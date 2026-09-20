# Tokens

Um token é uma decisão de desenho com nome. O Cajui organiza os seus em três níveis, e cada nível só conhece o de baixo.

```
primitivo              semântico                 componente
CajuiPalette.cajui  →  colors.action.primary  →  CajuiButtonTokens.resolve(...)
"que tom é este"       "para que serve"          "como este componente usa"
```

| Nível | Onde mora | Quem pode usar | Exemplo |
|---|---|---|---|
| Primitivo | `lib/src/tokens/primitives/` | Só o nível semântico. `CajuiPalette` **não é exportada** | `CajuiPalette.inkFaint` |
| Semântico | `lib/src/tokens/semantic/` | Componentes e app | `colors.text.muted` |
| Componente | Junto de cada componente | Só o próprio componente | `CajuiButtonTokens.resolve(colors, variant, states)` |

O app pede um **papel**, nunca um tom. É isso que permite trocar o tema claro pelo escuro, ou a versão da falta do mês, sem tocar em nenhuma tela.

## Onde mexer para mudar o quê

| Quero mudar | Edito | Efeito |
|---|---|---|
| A cor de todos os botões principais | `action.primary` (e `primaryHover`, `primaryPressed`) em `action_colors.dart` | Todos os botões, chips selecionados e chaves ligadas |
| Um tom da marca | `cajui_palette.dart` | Todo papel que aponta para ele, nos dois temas |
| Como a falta do mês é pintada | `ShortfallStyle` no tema | Todo valor negativo de mês, no app inteiro |
| O arredondamento dos cartões | `CajuiRadius.xl` | Cartões e folhas |
| A velocidade da resposta a toque | `CajuiDurations.fast` | Todo controle tocável |
| O som de "salvo" | O arquivo `saved.wav`, via `tool/sound/build_sounds.py` | Todo lugar que chama `feedback.saved()` |

Depois de qualquer mudança de cor: `flutter test test/accessibility`. O teste mede todos os pares em uso e reprova o que cair abaixo do mínimo.

## Cor

Os papéis, agrupados como em `CajuiColors`. Valores e contraste de cada um: páginas **Cores** e **Contraste** da gallery.

| Grupo | Papéis | Para quê |
|---|---|---|
| `surface` | `base` · `sunken` · `elevated` · `high` · `scrim` | Os planos da tela, do fundo ao que flutua |
| `text` | `primary` · `muted` · `faint` · `onAction` · `link` · `disabled` | Três pesos de leitura, mais os casos especiais |
| `action` | `primary` · `secondary` (cada um com `Hover` e `Pressed`) · `disabled` | Tudo o que se toca |
| `intent` | `positive` · `notice` · `danger` · `info` · `achievement` (cada um com `Subtle`) | O sentido de um aviso ou de um número |
| `border` | `subtle` · `field` · `strong` · `focusRing` · `focusGap` | Limites e foco |
| `brand` | `accent` · `gold` | O cajuí e o capim dourado, em detalhe |
| `data` | `fixed` · `variable` · `debt` · `voucher` · `track` | Os três blocos de despesa e o vale, nos medidores |
| — | `shortfall` · `shortfallSubtle` | A falta do mês; resolve pelo `ShortfallStyle` em vigor |

Regras:

1. **Cor nunca é o único sinal** (WCAG 1.4.1). Selecionado tem ícone; aviso tem ícone e texto; o veredito de contraste vem escrito.
2. **Contraste medido, não estimado.** Texto comum ≥ 4,5:1; texto grande, ícone e borda de componente ≥ 3:1. O que o teste já corrigiu está em [../brand/color.md](../brand/color.md).
3. **O tema escuro é um tema**, não o claro invertido: azul-petróleo, sem sombra, profundidade pela cor da superfície.
4. **Vermelho é reservado.** `intent.danger` marca erro que impede algo. Dinheiro faltando não é erro — é `shortfall`, e a sua cor é uma [decisão em aberto](#decisão-em-aberto).

## Tipografia

`CajuiTypography`, em `lib/src/typography/`. Duas famílias, empacotadas no próprio pacote (OFL):

| Família | Papel | Estilos |
|---|---|---|
| Fraunces (variável: `opsz`, `wght`, `SOFT`, `WONK`) | A voz: títulos | `displayLarge` · `displayMedium` · `headline` · `title` |
| Geist (variável: `wght`) | O trabalho: leitura, rótulos, números | `body` · `bodyStrong` · `label` · `caption` · `overline` · `amountLarge` · `amount` |

- Os estilos de valor (`amount*`) usam **algarismos tabulares**: o número não treme quando conta e as colunas alinham sozinhas.
- O eixo `opsz` da Fraunces acompanha o corpo: o mesmo arquivo serve ao título de 40 e à legenda de 12.
- Corpo mínimo de 12; tudo em unidades lógicas, para respeitar a fonte ampliada do sistema até 200%.

## Espaço, raio e sombra

| Escala | Valores | Observação |
|---|---|---|
| `CajuiSpacing` | 2 · 4 · 8 · 12 · 16 · 20 · 24 · 32 · 48 · 64 | `touchTarget` = 48, fora da escala |
| `CajuiRadius` | 8 · 12 · 16 · 20 · 28 · `pill` | Cartão usa 28; campo e chip, os menores |
| `CajuiShadows` | `none` · `contact` · `raised` · `floating` · `overlay` | Só no tema claro |

Escalas curtas de propósito: com poucos degraus, duas telas feitas em dias diferentes saem com o mesmo ritmo.

## Movimento

| Token | Valor | Uso |
|---|---|---|
| `CajuiDurations.instant` | 90 ms | Mudança de estado sem percurso |
| `fast` | 180 ms | Resposta a toque |
| `base` | 260 ms | Algo entrando |
| `slow` | 420 ms | Troca de tela |
| `slowest` | 600 ms | O teto: nada passa disso |
| `stagger` | 35 ms | Diferença entre itens de uma cascata |
| `reducedFade` | 120 ms | A fusão que substitui tudo no nível reduzido |
| `CajuiCurves.spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Toque: ultrapassa e volta |
| `enter` · `exit` · `standard` | curvas de desaceleração, aceleração e padrão | Entrar, sair, mover |

O **nível de movimento** (`MotionLevel`) é parte do tema: `full` libera tudo; `lite` mantém mola e corta o decorativo; `reduced` troca todo percurso por uma fusão curta. Quem decide é o `MotionLevelResolver`: primeiro o sistema (movimento reduzido), depois a medição de quadros no aparelho, por último a preferência. Um componente nunca pergunta "posso animar?" por conta própria — pergunta ao tema.

## Som e toque

`CajuiSound` nomeia cada som pelo que ele **significa** (`saved`, `notice`), como os tokens de cor. Os componentes não tocam som: avisam o `CajuiFeedback` do que aconteceu (`tap`, `toggle`, `open`, `saved`, `notice`, `achievement`), e a implementação em vigor decide som e vibração juntos.

- O som **nasce desligado** (`SoundSettings`), com três famílias que ligam separadas: toques, confirmações, ambiente.
- A velocidade varia até ±3% a cada disparo: o mesmo som nunca toca igual duas vezes seguidas.
- **Não existe `sound.error`.** O aviso é uma nota grave e macia.

## Decisão em aberto

A falta do mês tem duas versões, e o app inteiro troca de uma para a outra por um único valor (`ShortfallStyle`):

| Versão | Cor | Argumento |
|---|---|---|
| `calm` — "barro" | Tom de terra, mesmo peso visual da sobra | Falta é fato e distância a percorrer, não bronca (D-UX-22) |
| `alarm` — vermelho | O padrão do mercado | Leitura imediata para quem vem de banco e planilha |

As duas aparecem lado a lado na página **Decisões › Falta** da gallery, com o contraste medido. A escolha é do dono do produto, no checkpoint da Fase 3.
