# Marca Cajui

Tudo o que define como o Cajui se parece, soa e fala. Este é o ponto de partida do design system da Fase 3: os tokens de lá nascem das decisões daqui.

Para ver a marca montada, abra a prancha visual:

```bash
python -m http.server 5178 --directory docs/brand
# depois: http://localhost:5178/brand-board.html
```

## Documentos

| Arquivo | O que decide |
|---|---|
| [naming.md](naming.md) | Por que "Cajui": critérios, candidatos, verificação de domínio e de marca |
| [brand-platform.md](brand-platform.md) | Propósito, posicionamento, personalidade, valores e assinatura |
| [voice-and-tone.md](voice-and-tone.md) | Como o app fala: princípios, vocabulário, padrões de microcopy |
| [logo.md](logo.md) | Símbolo, logotipo, variantes, área de respiro, usos proibidos |
| [color.md](color.md) | Paleta do Cerrado com contraste medido contra a WCAG 2.2 |
| [typography.md](typography.md) | Fraunces e Geist: papéis, escala inicial, algarismos |
| [iconography.md](iconography.md) | Ícones de traço para a interface e ícones-herói em 3D |
| [motion-and-sound.md](motion-and-sound.md) | Princípios de movimento, toque e som |
| [brand-board.html](brand-board.html) | Prancha visual: tudo acima aplicado, inclusive em duas telas |

## Arquivos do logo

Gerados por [`tool/brand/build_logo.py`](../../tool/brand/build_logo.py) a partir de uma única geometria. Não edite os SVGs à mão: mude o script e rode de novo, para as variantes não divergirem.

| Arquivo | Uso |
|---|---|
| `assets/symbol.svg` | Símbolo em fundo claro |
| `assets/symbol-on-dark.svg` | Símbolo em fundo escuro |
| `assets/symbol-mono.svg` | Uma cor (herda `currentColor`) |
| `assets/app-icon.svg` | Ícone do app, base para o ícone adaptativo do Android |
| `assets/wordmark.svg` · `wordmark-on-dark.svg` | Logotipo em curvas |
| `assets/lockup-horizontal.svg` · `…-on-dark.svg` | Assinatura horizontal |
| `assets/hero-3d-concept.svg` | Estudo de direção para os ícones-herói em 3D |

## O que é provisório

Esta pasta fixa a direção. Três coisas só se fecham adiante, com medição:

- **Cor de déficit** — vermelho de mercado ou "barro" neutro e acionável: as duas versões são apresentadas na Fase 3, depois da pesquisa de UX financeira da Fase 1.
- **Escala tipográfica final** — testada em aparelho real na Fase 3.
- **Ícones 3D em produção** — o SVG atual é um estudo; a técnica (imagem pré-renderizada, Rive ou Lottie) depende de medição de custo de frame.
