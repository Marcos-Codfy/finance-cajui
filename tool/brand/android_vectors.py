"""Escreve o símbolo do Cajui como VectorDrawable do Android.

O VectorDrawable entende o mesmo `d` do SVG, inclusive o arco da castanha, e
os grupos fazem a mesma rotação de 14° e o mesmo enquadramento. Por isso o
ícone adaptativo, o monocromático e o da abertura saem da geometria de
`build_logo.py` sem redesenho: vetor, nítido em qualquer densidade, e sem
PNG para regerar quando o símbolo mudar.
"""

from __future__ import annotations

from build_logo import FRUIT_PATH, MOON, NUT_PATH, NUT_WIDTH

GRID = 512

# O gradiente do fruto do símbolo (`GRADIENT` em build_logo.py), com os
# mesmos pontos: o SVG mede em fração da caixa do fruto (160..352 × 52..270),
# e o VectorDrawable, nas coordenadas do próprio desenho.
FRUIT_STOPS = (("0", "#FFF4B740"), ("0.5", "#FFEE7B33"), ("1", "#FFD5411E"))
FRUIT_START = (208, 52)
FRUIT_END = (304, 270)

# O reflexo do alto do fruto: a elipse de `HIGHLIGHT`, em caminho, porque o
# VectorDrawable não tem elipse.
HIGHLIGHT_PATH = "M219,112 a13,30 0 1,0 26,0 a13,30 0 1,0 -26,0 Z"

WHITE = "#FFFFFFFF"


def _fruit(solid: str | None) -> str:
    if solid is not None:
        return f'            <path android:fillColor="{solid}" android:pathData="{FRUIT_PATH}"/>\n'
    stops = "".join(
        f'                        <item android:offset="{offset}" android:color="{color}"/>\n'
        for offset, color in FRUIT_STOPS
    )
    return (
        f'            <path android:pathData="{FRUIT_PATH}">\n'
        '                <aapt:attr name="android:fillColor">\n'
        '                    <gradient android:type="linear"\n'
        f'                        android:startX="{FRUIT_START[0]}" android:startY="{FRUIT_START[1]}"\n'
        f'                        android:endX="{FRUIT_END[0]}" android:endY="{FRUIT_END[1]}">\n'
        f"{stops}"
        "                    </gradient>\n"
        "                </aapt:attr>\n"
        "            </path>\n"
    )


def _nut(color: str) -> str:
    return (
        f'            <path android:pathData="{NUT_PATH}"\n'
        f'                android:strokeColor="{color}"\n'
        f'                android:strokeWidth="{NUT_WIDTH}"\n'
        '                android:strokeLineCap="round"/>\n'
    )


def _highlight() -> str:
    return (
        '            <group android:pivotX="232" android:pivotY="112" android:rotation="12">\n'
        f'                <path android:fillColor="{WHITE}" android:fillAlpha="0.2"\n'
        f'                    android:pathData="{HIGHLIGHT_PATH}"/>\n'
        "            </group>\n"
    )


def symbol_vector(
    comment: str,
    size_dp: int,
    place: tuple[float, float, float],
    nut: str = MOON,
    solid: str | None = None,
) -> str:
    """O símbolo num VectorDrawable de [size_dp], enquadrado por [place]
    (esquerda, topo, escala na grade de 512).

    Com [solid], tudo numa cor só e sem reflexo: é o monocromático, que o
    Android 13 pinta com a cor do papel de parede.
    """
    left, top, scale = place
    body = _nut(solid or nut) + _fruit(solid) + ("" if solid else _highlight())
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f"<!-- {comment}\n"
        "     Gerado por tool/brand/build_app_icons.py a partir de build_logo.py:\n"
        "     para mudar o desenho, mude lá e rode o script. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    xmlns:aapt="http://schemas.android.com/aapt"\n'
        f'    android:width="{size_dp}dp"\n'
        f'    android:height="{size_dp}dp"\n'
        f'    android:viewportWidth="{GRID}"\n'
        f'    android:viewportHeight="{GRID}">\n'
        f'    <group android:translateX="{left:.1f}" android:translateY="{top:.1f}"\n'
        f'        android:scaleX="{scale:.4f}" android:scaleY="{scale:.4f}">\n'
        '        <group android:pivotX="256" android:pivotY="256" android:rotation="-14">\n'
        f"{body}"
        "        </group>\n"
        "    </group>\n"
        "</vector>\n"
    )
