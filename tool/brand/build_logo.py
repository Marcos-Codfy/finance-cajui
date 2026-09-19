"""Gera os SVGs do logo do Cajui a partir de uma única fonte de geometria.

O logotipo sai em curvas (não em <text>) para não depender de a Fraunces estar
instalada em quem abre o arquivo. Rodar de novo sempre que o símbolo ou as
cores de marca mudarem, para as variantes não divergirem entre si.

Uso: python tool/brand/build_logo.py
Requer: pip install fonttools
"""

from __future__ import annotations

import tempfile
import urllib.request
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

FONT_URL = (
    "https://github.com/google/fonts/raw/main/ofl/fraunces/"
    "Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf"
)
# Peso médio com cantos macios: conversa com a forma arredondada do fruto.
FONT_AXES = {"wght": 540, "opsz": 144, "SOFT": 100, "WONK": 0}
OUT_DIR = Path(__file__).resolve().parents[2] / "docs" / "brand" / "assets"

INK = "#2A1D17"
MOON = "#F4ECE0"
CAJUI = "#E4572E"
CAJUI_LIGHT = "#FF8A5C"
NIGHT_TOP = "#17262C"
NIGHT_BOTTOM = "#0F1A1E"

WORD = "cajui"
TRACKING = -18  # em unidades da fonte; aproxima as letras como num logotipo
SYMBOL_BOX = 512

# Pera de pescoço estreito e base cheia: é o que separa um cajuí de uma gota.
FRUIT_PATH = (
    "M256 52 C284 52 304 72 308 104 C314 150 352 168 352 210 "
    "C352 248 310 270 256 270 C202 270 160 248 160 210 "
    "C160 168 198 150 204 104 C208 72 228 52 256 52 Z"
)
# A castanha é um arco grosso aberto para a direita: lê como castanha e como "C".
# Ela encosta por baixo do fruto, como na planta, em vez de flutuar solta.
NUT_PATH = "M292.7 299.6 A64 64 0 1 0 292.7 404.4"
NUT_WIDTH = 60
HIGHLIGHT = '<ellipse cx="232" cy="112" rx="13" ry="30" fill="#FFFFFF" opacity="0.2" transform="rotate(12 232 112)"/>'
GRADIENT = (
    '<linearGradient id="fruit" x1="0.25" y1="0" x2="0.75" y2="1">'
    '<stop offset="0" stop-color="#F4B740"/>'
    '<stop offset="0.5" stop-color="#EE7B33"/>'
    '<stop offset="1" stop-color="#D5411E"/></linearGradient>'
)
HERO_DEFS = (
    '<radialGradient id="fruitBody" cx="0.36" cy="0.26" r="0.85">'
    '<stop offset="0" stop-color="#FFE08A"/><stop offset="0.32" stop-color="#F8A63C"/>'
    '<stop offset="0.68" stop-color="#E8612B"/><stop offset="1" stop-color="#A92E12"/></radialGradient>'
    '<radialGradient id="fruitRim" cx="0.72" cy="0.86" r="0.5">'
    '<stop offset="0" stop-color="#FFB27A" stop-opacity="0.55"/>'
    '<stop offset="1" stop-color="#FFB27A" stop-opacity="0"/></radialGradient>'
    '<linearGradient id="nutBody" x1="0" y1="0" x2="1" y2="1">'
    '<stop offset="0" stop-color="#6B4A3A"/><stop offset="0.5" stop-color="#3A271E"/>'
    '<stop offset="1" stop-color="#1D130E"/></linearGradient>'
    '<linearGradient id="nutGloss" x1="0" y1="0" x2="1" y2="1">'
    '<stop offset="0" stop-color="#C9A58F" stop-opacity="0.7"/>'
    '<stop offset="1" stop-color="#C9A58F" stop-opacity="0"/></linearGradient>'
    '<filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="9"/></filter>'
    '<filter id="ground" x="-50%" y="-200%" width="200%" height="500%"><feGaussianBlur stdDeviation="16"/></filter>'
)


def load_font() -> TTFont:
    """Baixa a Fraunces uma vez para o cache temporário e fixa os eixos."""
    cache = Path(tempfile.gettempdir()) / "cajui-fraunces.ttf"
    if not cache.exists():
        urllib.request.urlretrieve(FONT_URL, cache)  # noqa: S310 - URL fixa
    return instantiateVariableFont(TTFont(cache), FONT_AXES)


def split_contours(glyph_set, glyph_name: str) -> list[list]:
    """Separa o glifo em contornos para poder colorir o pingo do i sozinho."""
    pen = DecomposingRecordingPen(glyph_set)
    glyph_set[glyph_name].draw(pen)
    contours, current = [], []
    for operation in pen.value:
        current.append(operation)
        if operation[0] in ("closePath", "endPath"):
            contours.append(current)
            current = []
    return contours


def contour_bounds(glyph_set, contour: list) -> tuple:
    pen = BoundsPen(glyph_set)
    for name, args in contour:
        getattr(pen, name)(*args)
    return pen.bounds


def contour_to_svg(glyph_set, contour: list, matrix: tuple) -> str:
    svg_pen = SVGPathPen(glyph_set, ntos=lambda value: f"{value:.1f}")
    pen = TransformPen(svg_pen, matrix)
    for name, args in contour:
        getattr(pen, name)(*args)
    return svg_pen.getCommands()


def layout_word(font: TTFont, scale: float, baseline: float, left: float) -> dict:
    """Devolve os paths do corpo e do pingo do último i, já em coordenadas SVG."""
    glyph_set, cmap = font.getGlyphSet(), font.getBestCmap()
    x_height = font["OS/2"].sxHeight
    body, accent, cursor = [], [], 0.0
    for index, char in enumerate(WORD):
        name = cmap[ord(char)]
        matrix = (scale, 0, 0, -scale, left + cursor * scale, baseline)
        for contour in split_contours(glyph_set, name):
            is_dot = contour_bounds(glyph_set, contour)[1] > x_height
            is_last = index == len(WORD) - 1
            target = accent if (is_dot and is_last) else body
            target.append(contour_to_svg(glyph_set, contour, matrix))
        cursor += font["hmtx"][name][0] + TRACKING
    return {"body": " ".join(body), "accent": " ".join(accent), "width": (cursor - TRACKING) * scale}


def symbol_group(nut_color: str, transform: str = "") -> str:
    attr = f' transform="{transform}"' if transform else ""
    return (
        f"<g{attr}><g transform=\"rotate(-14 256 256)\">"
        f'<path fill="none" stroke="{nut_color}" stroke-width="{NUT_WIDTH}" '
        f'stroke-linecap="round" d="{NUT_PATH}"/>'
        f'<path fill="url(#fruit)" d="{FRUIT_PATH}"/>{HIGHLIGHT}</g></g>'
    )


def svg_document(width: float, height: float, body: str, title: str, defs: str = GRADIENT) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width:.0f} {height:.0f}" '
        f'role="img" aria-label="{title}"><title>{title}</title>'
        f"<defs>{defs}</defs>{body}</svg>\n"
    )


def build_symbols() -> dict[str, str]:
    mono = (
        '<g transform="rotate(-14 256 256)" fill="currentColor">'
        f'<path d="{FRUIT_PATH}"/><path fill="none" stroke="currentColor" '
        f'stroke-width="{NUT_WIDTH}" stroke-linecap="round" d="{NUT_PATH}"/></g>'
    )
    return {
        "symbol.svg": svg_document(512, 512, symbol_group(INK), "Cajui"),
        "symbol-on-dark.svg": svg_document(512, 512, symbol_group(MOON), "Cajui"),
        "symbol-mono.svg": svg_document(512, 512, mono, "Cajui", defs=""),
    }


def build_app_icon() -> str:
    """Símbolo a 76%: o desenho visível fica dentro do círculo seguro (66%) do ícone adaptativo."""
    defs = GRADIENT + (
        '<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{NIGHT_TOP}"/>'
        f'<stop offset="1" stop-color="{NIGHT_BOTTOM}"/></linearGradient>'
    )
    background = '<rect width="512" height="512" rx="116" fill="url(#bg)"/>'
    symbol = symbol_group(MOON, "translate(61 66) scale(0.76)")
    return svg_document(512, 512, background + symbol, "Cajui", defs=defs)


def build_wordmark(font: TTFont, ink: str, accent: str) -> str:
    word = layout_word(font, scale=0.2, baseline=300, left=20)
    body = f'<path fill="{ink}" d="{word["body"]}"/><path fill="{accent}" d="{word["accent"]}"/>'
    return svg_document(word["width"] + 40, 420, body, "Cajui", defs="")


def build_lockup(font: TTFont, ink: str, accent: str, nut: str) -> str:
    # O símbolo é recortado à esquerda (a caixa de 512 tem muito ar dos lados)
    # para o espaço entre ele e o nome ser decidido aqui, não pelo acaso da caixa.
    word = layout_word(font, scale=0.23, baseline=352, left=286)
    symbol = symbol_group(nut, "translate(-128 6) scale(0.95)")
    body = (
        f'{symbol}<path fill="{ink}" d="{word["body"]}"/>'
        f'<path fill="{accent}" d="{word["accent"]}"/>'
    )
    return svg_document(286 + word["width"] + 24, 492, body, "Cajui")


def build_hero_3d() -> str:
    """Estudo do ícone-herói em 3D macio: mesma geometria, luz e volume por gradiente."""
    defs = HERO_DEFS
    shadow = '<ellipse cx="262" cy="474" rx="128" ry="15" fill="#2A1D17" opacity="0.28" filter="url(#ground)"/>'
    nut = (
        f'<path fill="none" stroke="url(#nutBody)" stroke-width="{NUT_WIDTH}" stroke-linecap="round" d="{NUT_PATH}"/>'
        '<path fill="none" stroke="url(#nutGloss)" stroke-width="12" stroke-linecap="round" '
        'filter="url(#soft)" d="M236 300 A66 66 0 0 0 196 348"/>'
    )
    fruit = (
        f'<path fill="url(#fruitBody)" d="{FRUIT_PATH}"/><path fill="url(#fruitRim)" d="{FRUIT_PATH}"/>'
        '<ellipse cx="230" cy="116" rx="15" ry="34" fill="#FFFFFF" opacity="0.5" filter="url(#soft)" transform="rotate(14 230 116)"/>'
        '<ellipse cx="222" cy="98" rx="5" ry="10" fill="#FFFFFF" opacity="0.85" transform="rotate(18 222 98)"/>'
    )
    body = f'{shadow}<g transform="rotate(-14 256 256)">{nut}{fruit}</g>'
    return svg_document(512, 512, body, "Conceito de ícone 3D do cajuí", defs=defs)


def main() -> None:
    font = load_font()
    files = build_symbols()
    files["app-icon.svg"] = build_app_icon()
    files["hero-3d-concept.svg"] = build_hero_3d()
    files["wordmark.svg"] = build_wordmark(font, INK, CAJUI)
    files["wordmark-on-dark.svg"] = build_wordmark(font, MOON, CAJUI_LIGHT)
    files["lockup-horizontal.svg"] = build_lockup(font, INK, CAJUI, INK)
    files["lockup-horizontal-on-dark.svg"] = build_lockup(font, MOON, CAJUI_LIGHT, MOON)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, content in files.items():
        (OUT_DIR / name).write_text(content, encoding="utf-8", newline="\n")
        print(f"ok  {name}")


if __name__ == "__main__":
    main()
