# Tipografia

## Escolha

| Papel | Família | Licença | Por quê, em uma frase |
|---|---|---|---|
| Voz — títulos e o número-manchete | **Fraunces** (variável: peso, tamanho óptico, SOFT) | SIL OFL 1.1 | Serifa de curvas macias que conversa com a forma do fruto e dá ar editorial a uma tela de finanças, onde quase tudo é grotesca fria. |
| Dado — interface, tabelas, valores | **Geist** | SIL OFL 1.1 | Grotesca precisa, com algarismos tabulares que alinham em coluna, e menos vista que as escolhas óbvias do gênero. |

As duas estão no Google Fonts, são gratuitas para uso comercial e entram no app **empacotadas como asset** — nada de buscar fonte na rede em tempo de execução (privacidade, funcionamento offline e primeiro quadro sem salto de layout).

O par funciona por contraste: a Fraunces fala, a Geist conta. Uma terceira família não entra.

## Papéis

| Onde | Família | Observação |
|---|---|---|
| Número-manchete da tela ("Sobram R$ 412 até domingo.") | Fraunces | A frase inteira, não só o número: é a voz do app |
| Título de tela e de seção | Fraunces | Peso médio; nunca negrito pesado |
| Título de cartão, rótulo, botão, corpo, legenda | Geist | — |
| **Todo valor em lista, tabela ou campo** | Geist com `tabular-nums` | Colunas de dinheiro precisam alinhar casa com casa |
| Chat | Geist | Conversa longa pede neutralidade |

Regra prática: a Fraunces aparece **uma ou duas vezes por tela**. Se tudo é display, nada é.

## Escala inicial

Ponto de partida para a Fase 3, que fecha a escala testando em aparelho real. Razão aproximada de 1,2 entre degraus de texto; os displays saltam mais para criar hierarquia de capa de revista.

| Token | Família | Tamanho / altura de linha | Peso | Entreletra |
|---|---|---|---|---|
| `display.large` | Fraunces | 40 / 44 | 520 | −2,5% |
| `display.medium` | Fraunces | 32 / 36 | 520 | −2% |
| `headline` | Fraunces | 24 / 30 | 540 | −1,5% |
| `title` | Geist | 18 / 24 | 600 | −0,5% |
| `body` | Geist | 16 / 24 | 400 | 0 |
| `body.strong` | Geist | 16 / 24 | 600 | 0 |
| `label` | Geist | 14 / 20 | 500 | 0 |
| `caption` | Geist | 12,5 / 16 | 400 | +1% |
| `overline` | Geist | 12 / 16 | 600, caixa alta | +12% |
| `amount.large` | Geist tabular | 28 / 32 | 600 | −2% |
| `amount` | Geist tabular | 16 / 24 | 600 | 0 |

## Ajustes da Fraunces

A fonte é variável; a marca usa sempre:

- **SOFT = 100** — cantos arredondados, coerentes com o símbolo.
- **WONK = 0** — sem as formas excêntricas do *h*, *n*, *m* itálicos; elegante, não caricata.
- **Tamanho óptico automático** — traço fino e contraste alto em tamanho grande, robusto em tamanho pequeno.
- **Itálico** apenas para ênfase pontual dentro de um título ("Todo mês *rebrota.*").

## Dinheiro

- `R$` menor e mais claro que o valor, alinhado ao topo, quando o número é grande; do mesmo tamanho em listas.
- Centavos sempre presentes em listas e tabelas; omitidos no número-manchete quando são zero.
- Negativo com sinal de menos verdadeiro (`−`, U+2212), nunca hífen, e nunca só pela cor.
- Algarismos sempre alinhados (*lining*) e tabulares; nunca estilo antigo em valores.

## Acessibilidade

- Corpo mínimo de 16 px; nada abaixo de 12 px.
- A escala responde ao tamanho de fonte do sistema: todo layout precisa sobreviver a 200% sem cortar texto (WCAG 1.4.4), o que na prática proíbe altura fixa em contêiner de texto.
- Altura de linha de 1,5 no corpo, e layout que não perde conteúdo quando o usuário aumenta o espaçamento do texto (WCAG 1.4.12).
- Serifa só em tamanho de título: texto corrido longo fica na Geist.
