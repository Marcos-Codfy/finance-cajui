"""Gera o ícone do app Android e o da abertura a partir do símbolo da marca.

Nada de desenho novo: a geometria vem de `build_logo.py`, que é a fonte única
do símbolo. Aqui ele só é posto nos formatos que o Android pede:

- o ícone adaptativo (Android 8+): primeiro plano e monocromático em vetor
  (`android_vectors.py`), sobre o fundo de anoitecer, também em XML;
- o ícone da abertura (Android 12+), em vetor, com a castanha na cor do tema;
- o ícone antigo (Android 7), em PNG, com o fundo já embutido.

Só o antigo é rasterizado. A rasterização usa o Chrome em modo headless: é o
mesmo motor que desenha o SVG na web, então o PNG sai igual ao vetor
aprovado, com transparência. O Chrome também mede onde a tinta do símbolo
está, para centrá-lo.

Uso: python tool/brand/build_app_icons.py
Requer: Google Chrome instalado e Pillow.
"""

from __future__ import annotations

import math
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from android_vectors import GRID, WHITE, symbol_vector  # noqa: E402
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

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
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

# Quanto da grade a tinta ocupa. O adaptativo corta tudo fora de 66% e ainda
# aproxima o ícone ao tocar, então 60% deixa folga sem encolher o desenho.
FOREGROUND_EXTENT = 0.60
# No ícone antigo o corte é o próprio quadrado: cabe um pouco mais de tinta.
LEGACY_EXTENT = 0.66
# A abertura do Android 12+ desenha o ícone em 288 dp e o recorta num
# círculo de 192 dp. A diagonal da tinta cabe nele, com um respiro de 8%.
SPLASH_CIRCLE = 192 / 288 * 0.92


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


def centered(box: tuple[float, float, float, float], scale: float) -> tuple[float, float, float]:
    """Esquerda, topo e escala que põem a tinta medida no meio da grade."""
    x0, y0, x1, y1 = box
    left = GRID / 2 - scale * (x0 + x1) / 2
    top = GRID / 2 - scale * (y0 + y1) / 2
    return (left, top, scale)


def by_extent(box: tuple[float, float, float, float], extent: float) -> tuple[float, float, float]:
    """O lado maior da tinta ocupando [extent] da grade."""
    x0, y0, x1, y1 = box
    return centered(box, extent * GRID / max(x1 - x0, y1 - y0))


def by_circle(box: tuple[float, float, float, float], diameter: float) -> tuple[float, float, float]:
    """A diagonal da tinta cabendo num círculo de [diameter] da grade: é o
    que garante que o recorte redondo da abertura não come a castanha."""
    x0, y0, x1, y1 = box
    return centered(box, diameter * GRID / math.hypot(x1 - x0, y1 - y0))


def as_transform(place: tuple[float, float, float]) -> str:
    left, top, scale = place
    return f"translate({left:.1f} {top:.1f}) scale({scale:.4f})"


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


def write_text(relative: str, text: str) -> None:
    target = RES_DIR / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8", newline="\n")
    print(f"ok  {relative}")


def write_vector_drawables(ink: tuple[float, float, float, float]) -> None:
    """O adaptativo, o monocromático e a abertura, todos em vetor."""
    inside = by_extent(ink, FOREGROUND_EXTENT)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        write_text(f"mipmap-anydpi-v26/{name}", ADAPTIVE_XML)
    write_text("drawable/ic_launcher_background.xml", BACKGROUND_XML)
    write_text(
        "drawable/ic_launcher_foreground.xml",
        symbol_vector(
            "O primeiro plano do ícone adaptativo: o cajuí no círculo seguro.",
            108,
            inside,
        ),
    )
    write_text(
        "drawable/ic_launcher_monochrome.xml",
        symbol_vector(
            "O ícone de uma cor só do Android 13+: o sistema pinta a\n"
            "     silhueta com a cor do papel de parede.",
            108,
            inside,
            solid=WHITE,
        ),
    )
    write_text(
        "drawable/splash_cajui.xml",
        symbol_vector(
            "O cajuí da abertura do Android 12+. A castanha segue o tema\n"
            "     (`cajui_splash_nut`): tinta no claro, lua no escuro.",
            288,
            by_circle(ink, SPLASH_CIRCLE),
            nut="@color/cajui_splash_nut",
        ),
    )


def main() -> None:
    browser = chrome()
    ink = measure_ink(browser, svg_document(GRID, GRID, symbol_group(MOON), "Cajui"))
    print(f"ok  tinta do símbolo medida em {ink}")
    square = as_transform(by_extent(ink, LEGACY_EXTENT))
    write_png_set(browser, legacy_svg(square), "ic_launcher", LEGACY_SIZES)
    write_png_set(browser, legacy_svg(square), "ic_launcher_round", LEGACY_SIZES)
    write_vector_drawables(ink)
    print("ok  ícone do app gerado a partir do símbolo da marca")


if __name__ == "__main__":
    main()
