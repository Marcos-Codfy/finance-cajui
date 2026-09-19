# Logo

## Conceito

Duas formas, uma leitura dupla:

- **O fruto** — uma pera de pescoço estreito e base cheia, em gradiente do amarelo-capim ao vermelho-cajuí. Carrega a cor e o calor da marca.
- **A castanha** — um arco grosso, de pontas redondas, aberto para a direita. É a castanha do cajuí presa por baixo do fruto, como na planta, e é também o **C** de Cajui.

O conjunto é inclinado 14° para a esquerda: fruta pendurada no galho, não pictograma engessado.

No logotipo, o pingo do último *i* é laranja. A marca abre mão do acento de "cajuí" para viajar bem; o pingo colorido é o aceno a ele.

## Construção

Grade de 512 × 512. A geometria vive em um único lugar — [`tool/brand/build_logo.py`](../../tool/brand/build_logo.py) — e todas as variantes são geradas dali.

| Elemento | Definição |
|---|---|
| Fruto | Curva Bézier simétrica, de `y=52` a `y=270`, largura máxima 192 |
| Castanha | Arco de raio 64, traço 60, pontas redondas, abertura de 110° voltada à direita; entra 12 px por baixo do fruto |
| Brilho | Elipse branca a 20% no ombro esquerdo do fruto — luz de cima à esquerda, a mesma dos ícones 3D |
| Inclinação | −14° em torno do centro da grade |
| Gradiente do fruto | `#F4B740` → `#EE7B33` → `#D5411E`, diagonal |
| Logotipo | Fraunces, peso 540, tamanho óptico 144, eixo SOFT em 100, entreletra −18/2000 em; convertido em curvas |

## Variantes

| Variante | Arquivo | Quando usar |
|---|---|---|
| Símbolo, fundo claro | `assets/symbol.svg` | Castanha em `#2A1D17` |
| Símbolo, fundo escuro | `assets/symbol-on-dark.svg` | Castanha em `#F4ECE0` |
| Símbolo, uma cor | `assets/symbol-mono.svg` | Carimbo, marca d'água, ícone de notificação do Android (que exige silhueta) |
| Ícone do app | `assets/app-icon.svg` | Base do ícone adaptativo; fundo em gradiente "noite" |
| Logotipo | `assets/wordmark.svg` · `wordmark-on-dark.svg` | Quando o símbolo já apareceu perto, ou em espaço muito horizontal |
| Assinatura horizontal | `assets/lockup-horizontal.svg` · `…-on-dark.svg` | Uso padrão: tela de abertura, README, cabeçalho da web |

## Área de respiro e tamanho mínimo

- **Respiro:** em volta do logo, deixe livre no mínimo a largura do traço da castanha — 60 unidades na grade de 512, cerca de 15% da altura do símbolo. Nada entra nessa área.
- **Tamanho mínimo do símbolo:** 20 px de altura na tela. Abaixo disso o brilho some e a abertura do C fecha — use a versão de uma cor.
- **Tamanho mínimo da assinatura:** 96 px de largura.

## Ícone do app no Android

O Android recorta o ícone adaptativo em formas diferentes por fabricante; só o círculo central de 66% é garantido. O símbolo entra a 76% da grade, o que mantém todo o desenho visível dentro desse círculo. Na implementação (Fase 6) o `app-icon.svg` é separado em duas camadas — fundo e primeiro plano — e ganha a camada monocromática exigida pelos ícones temáticos do Android 13+, que é o `symbol-mono.svg`.

## Fundos

| Fundo | Variante |
|---|---|
| Areia `#FBF6EE`, branco, areia funda `#F3EADC` | fundo claro |
| Noite `#0F1A1E` e superfícies elevadas do tema escuro | fundo escuro |
| Fotografia ou cor fora da paleta | uma cor, em castanha ou luar, o que contrastar mais |
| Cajuí `#E4572E` ou cajuí forte `#B93D17` | uma cor, em luar — o fruto em gradiente some sobre laranja |

## Não faça

- Não endireite o símbolo: a inclinação faz parte do desenho.
- Não separe fruto e castanha, nem troque a ordem.
- Não recolora o fruto fora do gradiente; para uma cor só, existe a variante própria.
- Não aplique sombra, contorno ou brilho extra.
- Não redigite o logotipo em outra fonte, nem em Fraunces "ao vivo" — use as curvas.
- Não coloque o logotipo com acento: a marca é **Cajui**.
- Não estique, nem comprima; escale sempre proporcionalmente.

## Como regenerar

```bash
pip install fonttools
python tool/brand/build_logo.py
```

O script baixa a Fraunces (licença SIL Open Font License 1.1) do repositório oficial do Google Fonts para o diretório temporário do sistema, fixa os eixos da fonte variável e escreve os SVGs em `docs/brand/assets/`.
