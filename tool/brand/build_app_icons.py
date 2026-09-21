"""Gera o ícone do app Android a partir do mesmo símbolo da marca.

Nada de desenho novo: a geometria vem de `build_logo.py`, que é a fonte única
do símbolo. Aqui ele só é posto nos dois formatos que o Android pede — o
primeiro plano do ícone adaptativo (transparente, dentro do círculo seguro) e
o ícone antigo, com o fundo já embutido — e rasterizado em cada densidade.

A rasterização usa o Chrome em modo headless: é o mesmo motor que desenha o
SVG na web, então o PNG sai igual ao vetor aprovado, com transparência.

Uso: python tool/brand/build_app_icons.py
Requer: Google Chrome instalado.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_logo import (  # noqa: E402
    GRADIENT,
    MOON,
    NIGHT_BOTTOM,
    NIGHT_TOP,
    svg_document,
    symbol_group,
)

ROOT = Path(__file__).resolve().parents[2]
RES_DIR = ROOT / "app" / "android" / "app" / "src" / "main" / "res"

CHROME_CANDIDATES = [
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    Path.home() / r"AppData\Local\Google\Chrome\Application\chrome.exe",
]

# O ícone antigo, quadrado com cantos: 48 dp em cada densidade.
LEGACY_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
# O primeiro plano do adaptativo: 108 dp, com o desenho no círculo de 66 dp.
FOREGROUND_SIZES = {name: round(size * 108 / 48) for name, size in LEGACY_SIZES.items()}

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
"""

BACKGROUND_XML = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- O mesmo anoitecer do ícone da marca: escuro em cima, mais escuro embaixo. -->
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:angle="270"
        android:startColor="{NIGHT_TOP}"
        android:endColor="{NIGHT_BOTTOM}"/>
</shape>
"""


GRID = 512
# Quanto da grade a tinta ocupa. O adaptativo corta tudo fora de 66% e ainda
# aproxima o ícone ao tocar, então 60% deixa folga sem encolher o desenho.
FOREGROUND_EXTENT = 0.60
# No ícone antigo o corte é o próprio quadrado: cabe um pouco mais de tinta.
LEGACY_EXTENT = 0.66


def measure_ink(browser: Path, svg_text: str) -> tuple[float, float, float, float]:
    """Onde a tinta do desenho começa e termina, na grade de 512.

    O símbolo não é centrado na própria grade — a castanha puxa para a direita
    e a inclinação de 14° desloca o conjunto. Medir é mais honesto que
    adivinhar a transformação, e se a geometria mudar isto se corrige sozinho.
    """
    from PIL import Image

    with tempfile.TemporaryDirectory() as work:
        svg = Path(work) / "measure.svg"
        svg.write_text(svg_text, encoding="utf-8")
        shot = Path(work) / "measure.png"
        render(browser, svg, shot, GRID)
        with Image.open(shot) as image:
            box = image.convert("RGBA").split()[3].getbbox()
    if box is None:
        raise SystemExit("O desenho saiu vazio: nada a medir.")
    return box


def centered_transform(box: tuple[float, float, float, float], extent: float) -> str:
    """A transformação que põe a tinta medida no meio da grade, ocupando
    [extent] dela."""
    x0, y0, x1, y1 = box
    scale = extent * GRID / max(x1 - x0, y1 - y0)
    left = GRID / 2 - scale * (x0 + x1) / 2
    top = GRID / 2 - scale * (y0 + y1) / 2
    return f"translate({left:.1f} {top:.1f}) scale({scale:.4f})"


def foreground_svg(transform: str) -> str:
    """O símbolo sozinho, centrado, para o primeiro plano do adaptativo."""
    return svg_document(GRID, GRID, symbol_group(MOON, transform), "Cajui")


def legacy_svg(transform: str) -> str:
    """O ícone antigo: o mesmo símbolo sobre o fundo de anoitecer, com o
    canto arredondado que o Android espera de quem não é adaptativo."""
    defs = GRADIENT + (
        '<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{NIGHT_TOP}"/>'
        f'<stop offset="1" stop-color="{NIGHT_BOTTOM}"/></linearGradient>'
    )
    background = f'<rect width="{GRID}" height="{GRID}" rx="116" fill="url(#bg)"/>'
    return svg_document(
        GRID,
        GRID,
        background + symbol_group(MOON, transform),
        "Cajui",
        defs=defs,
    )


def monochrome_svg(transform: str) -> str:
    """A versão de uma cor só, para o tema dinâmico do Android 13+: o sistema
    pinta a silhueta com a cor do papel de parede."""
    body = (
        f'<g transform="{transform}">'
        '<g transform="rotate(-14 256 256)" fill="#FFFFFF">'
        '<path d="M256 52 C284 52 304 72 308 104 C314 150 352 168 352 210 '
        "C352 248 310 270 256 270 C202 270 160 248 160 210 "
        'C160 168 198 150 204 104 C208 72 228 52 256 52 Z"/>'
        '<path fill="none" stroke="#FFFFFF" stroke-width="60" '
        'stroke-linecap="round" d="M292.7 299.6 A64 64 0 1 0 292.7 404.4"/>'
        "</g></g>"
    )
    return svg_document(512, 512, body, "Cajui", defs=GRADIENT)


def chrome() -> Path:
    for candidate in CHROME_CANDIDATES:
        if candidate.exists():
            return candidate
    raise SystemExit("Chrome não encontrado: ele é quem rasteriza o SVG.")


def render(browser: Path, svg: Path, out: Path, size: int) -> None:
    """Rasteriza [svg] em [size]×[size], com o fundo transparente."""
    with tempfile.TemporaryDirectory() as profile:
        subprocess.run(
            [
                str(browser),
                "--headless",
                "--disable-gpu",
                "--hide-scrollbars",
                "--force-device-scale-factor=1",
                "--default-background-color=00000000",
                f"--user-data-dir={profile}",
                f"--window-size={size},{size}",
                f"--screenshot={out}",
                svg.as_uri(),
            ],
            check=True,
            capture_output=True,
        )


def write_png_set(browser: Path, svg_text: str, name: str, sizes: dict) -> None:
    """Rasteriza uma vez na grade e reduz para cada densidade.

    O Chrome desloca o desenho na horizontal quando a janela não é a da grade
    — a medida e o corte deixam de bater. Rasterizar só em 512, onde o
    enquadramento é conferido, e reduzir com o Pillow tira o navegador dessa
    conta: cada densidade sai do mesmo PNG, com o mesmo enquadramento.
    """
    from PIL import Image

    with tempfile.TemporaryDirectory() as work:
        svg = Path(work) / f"{name}.svg"
        svg.write_text(svg_text, encoding="utf-8")
        master = Path(work) / f"{name}.png"
        render(browser, svg, master, GRID)
        with Image.open(master) as image:
            source = image.convert("RGBA")
            for folder, size in sizes.items():
                target = RES_DIR / folder / f"{name}.png"
                target.parent.mkdir(parents=True, exist_ok=True)
                source.resize((size, size), Image.LANCZOS).save(target)
                print(f"ok  {folder}/{name}.png  {size}px")


def write_vector_drawables() -> None:
    (RES_DIR / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (RES_DIR / "drawable").mkdir(parents=True, exist_ok=True)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        (RES_DIR / "mipmap-anydpi-v26" / name).write_text(
            ADAPTIVE_XML, encoding="utf-8", newline="\n"
        )
        print(f"ok  mipmap-anydpi-v26/{name}")
    (RES_DIR / "drawable" / "ic_launcher_background.xml").write_text(
        BACKGROUND_XML, encoding="utf-8", newline="\n"
    )
    print("ok  drawable/ic_launcher_background.xml")


def main() -> None:
    browser = chrome()
    ink = measure_ink(browser, svg_document(GRID, GRID, symbol_group(MOON), "Cajui"))
    print(f"ok  tinta do símbolo medida em {ink}")
    inside = centered_transform(ink, FOREGROUND_EXTENT)
    square = centered_transform(ink, LEGACY_EXTENT)
    write_png_set(browser, legacy_svg(square), "ic_launcher", LEGACY_SIZES)
    write_png_set(browser, legacy_svg(square), "ic_launcher_round", LEGACY_SIZES)
    write_png_set(
        browser, foreground_svg(inside), "ic_launcher_foreground", FOREGROUND_SIZES
    )
    write_png_set(
        browser, monochrome_svg(inside), "ic_launcher_monochrome", FOREGROUND_SIZES
    )
    write_vector_drawables()
    # O monocromático é drawable, não mipmap: o adaptativo o referencia assim.
    for folder in FOREGROUND_SIZES:
        source = RES_DIR / folder / "ic_launcher_monochrome.png"
        target = RES_DIR / folder.replace("mipmap", "drawable")
        target.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(target / "ic_launcher_monochrome.png"))
    print("ok  ícone do app gerado a partir do símbolo da marca")


if __name__ == "__main__":
    main()
