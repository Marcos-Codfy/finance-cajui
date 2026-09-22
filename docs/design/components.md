# Componentes

Todos moram em `packages/design_system/lib/src/components/` e são exportados por `lib/design_system.dart`. Cada um aparece na gallery em **todos os estados**, com o nome do estado escrito ao lado.

## A base: `CajuiPressable`

Tudo o que se toca — botão, chip, chave, cartão e linha tocáveis, campo de escolha — é construído sobre `CajuiPressable` (`lib/src/interaction/`). O que ele garante, uma vez, para todos:

| Garantia | Como |
|---|---|
| Resposta em menos de 100 ms (RNF-PERF-04) | O estado pressionado aparece no quadro seguinte; nada espera rede, disco ou IA |
| Alvo de 48 (WCAG 2.5.8) | Área mínima de toque, mesmo quando o desenho é menor |
| Teclado | Foco por Tab, ativa com Enter e Espaço |
| Foco visível (WCAG 2.4.7 e 2.4.11) | `FocusRing`: anel afastado, com uma folga que o separa do fundo; só aparece na navegação por teclado |
| Leitor de tela | Um nome obrigatório (`semanticLabel`), papel de botão e o estado que existir; o rótulo visual não é lido duas vezes. **Ligado** (`toggled`) e **escolhido** (`selected`) são papéis diferentes e não se misturam: chave e chip ligam e desligam sozinhos; destino de navegação e item de lista só deixam de ser o escolhido quando outro passa a ser |
| Os cinco estados | Repouso, mouse em cima, pressionado, em foco, inativo — mais "ocupado", que bloqueia o segundo toque |
| Som e toque | Avisa o `CajuiFeedback` em vigor; o componente nunca toca som por conta própria |
| Movimento | Mola ao pressionar; no nível `reduced`, só troca de cor |

Um componente novo que se toca **não reimplementa** nada disso.

## Ação

| Componente | Variações | Estados | Regras |
|---|---|---|---|
| `CajuiButton` | `primary` · `secondary` · `ghost` · `destructive`; tamanhos `regular` (52) e `compact` (40); com ícone; `expand` | Repouso · mouse · pressionado · foco · carregando · inativo | Uma ação principal por tela. Carregando mantém a largura e o nome. `destructive` só depois de uma pergunta |
| `CajuiIconButton` | As mesmas quatro variantes | Os mesmos | Desenho de 24, alvo de 48. `semanticLabel` obrigatório |
| `CajuiChip` | — | Não selecionado · selecionado · inativo | Selecionado muda de cor **e** ganha o ícone de visto. Rótulo longo encolhe com reticências, não estoura |
| `CajuiSwitch` | — | Ligada · desligada · inativa (ligada e desligada) | Efeito imediato, sem botão de salvar |
| `CajuiNavBar` + `CajuiNavDestination` | De 3 a 5 destinos | Em vigor · repouso · mouse · pressionado · foco | No pé da tela, onde o polegar alcança. O destino em vigor é marcado pela pílula **e** pelo peso do nome. Todo destino tem nome à vista. Cabe em 320 px com fonte a 200% |

## Moldura do app

| Componente | Para quê | Regra |
|---|---|---|
| `CajuiAppSurface` | O chão do app: entrega tema e retorno sensorial, pinta o fundo e define o texto padrão | `themeOf` segue o claro/escuro do aparelho e baixa o movimento quando o sistema pede ou quando o aparelho perde quadros. O app não escolhe cor de fundo nem estilo de texto |
| `CajuiScreen` | O esqueleto de toda tela: título, conteúdo rolável, ação presa ao pé | O título rola com o conteúdo e é cabeçalho para o leitor de tela. Voltar só aparece quando há para onde voltar. Conteúdo limitado a 640 de largura |
| `CajuiSectionTitle` | O título de uma seção dentro da tela: "Contas fixas", "Por onde foi pago" | Traz o próprio respiro — espaço de seção acima, pequeno abaixo —, para duas telas nunca separarem seções de jeitos diferentes. É cabeçalho para o leitor de tela |
| `CajuiPageRoute` | A troca de tela | A tela nova sobe 4% enquanto aparece; em `reduced`, só esmaece |
| `CajuiLocalizations` | Os textos de sistema que os componentes pedem ao Flutter | Existe para o app não importar o Material — o verificador reprova esse import (ADR-014) |

## Conteúdo

| Componente | Para quê | Regras |
|---|---|---|
| `CajuiAmountText` | Todo valor em dinheiro | Tons `neutral` · `muted` · `positive` · `shortfall` · `accent`. Algarismos tabulares; sinal de menos tipográfico; espaço não separável entre `R$` e o número. O tom diz o **papel** do número, não se ele é bom ou ruim |
| `CajuiCard` | Agrupar | Padrão · rebaixado (`sunken`) · tocável. Tocável exige nome para o leitor de tela |
| `CajuiListRow` | Lançamento, parcela, item de ajuste | **Título é o que foi comprado; subtítulo, por onde foi pago** — a regra central do produto, na estrutura do componente |
| `CajuiMeter` | Parte de um todo | Um dos dois únicos gráficos do app (RN-862). Exige o número equivalente em texto. Passar do limite enche a barra e troca para a cor da falta, sem alarme |
| `CajuiStatCard` | Um número do painel: o que mede, o valor e quanto do todo já tomou | Nasceu na gallery e foi promovido quando o painel do app precisou dele. Sem valor, mostra um travessão — nunca zero (RN-604). Não existe cartão "vermelho": o tom é o papel do número, e a frase de apoio diz o que fazer com ele. A barra exige a frase, que é o mesmo dado em texto |
| `CajuiChatBubble` | Uma fala da conversa com o assistente | Quem fala se distingue pelo lado, pela cor **e** pelo nome lido ("Você:", "Cajui:"). Na espera, três pontos que respiram, e o leitor de tela ouve "Cajui está respondendo" — não um balão vazio. Promovido da gallery quando o assistente do app precisou dele |
| `CajuiConfidenceIndicator` | Quanto a leitura do comprovante confia na categoria | Três níveis, sempre com a frase: alta · "Fiquei entre estas" · "Não consegui identificar". Confiança baixa vira pergunta, não palpite |

`BrlFormatter` (`lib/src/format/`) é o único lugar que formata real: `R$ 1.234,56`, a partir de centavos inteiros. Nunca `double`.

## Campos

Todos sobre `CajuiFieldFrame`, que dá o rótulo sempre visível (fora do campo, nunca como dica que some), a ajuda e o erro.

`CajuiFieldLabel` é esse rótulo, sozinho: serve ao que não é campo de texto — um grupo de chips, por exemplo —, porque grupo de escolhas sem rótulo deixa quem usa leitor de tela sem saber o que está escolhendo. Traz o próprio espaço (`CajuiFieldLabel.gap`) para o rótulo ficar sempre à mesma distância do que nomeia.

| Componente | Estados | Regras |
|---|---|---|
| `CajuiTextField` | Vazio com dica · preenchido · com ajuda · com erro · em foco · inativo | O erro fica sob o campo até ser resolvido e diz o que fazer ([catálogo](../spec/error-catalog.md), classe `validação`) |
| `CajuiAmountField` | Os mesmos | Os centavos entram da direita para a esquerda, como em maquininha: não existe vírgula para errar. Entrega `int` em centavos |
| `CajuiSelectField` | Vazio · escolhido · com erro · inativo | Abre uma lista; não é um menu suspenso do sistema |
| `CajuiOptionList<T>` | Com e sem item selecionado | Selecionado tem ícone de visto, não só cor |

## Estado

| Componente | Para quê | Regras |
|---|---|---|
| `CajuiNotice` | Avisar na tela | Intenções `info` · `positive` · `attention` · `danger`. **Persistente**: não some sozinho (RNF-A11Y-13). Estrutura fixa: o que aconteceu · o que significa · até duas saídas. Dispensável só por quem lê |
| `CajuiEmptyState` | Primeiro uso e lista vazia | Não é erro: explica o que vai aparecer ali e oferece o primeiro passo. Ilustração e ação opcionais |
| `CajuiSkeleton` | Carregando conteúdo | Tem a forma do que vem. Pulsa nos níveis `full` e `lite`; parado em `reduced` |
| `CajuiLoadingDots` | Esperando (botão, IA) | Três pontos que respiram, não giram. Parados no nível `reduced`, com o mesmo nome para o leitor de tela |
| `CajuiHeroFruit` | Ilustração-herói: primeiro uso e conquista | Vetor desenhado em código, sem imagem. Aparece pouco, para significar algo |

## Movimento e ícones

| Componente | Para quê |
|---|---|
| `CajuiEntrance` | Entrada em cascata de itens de lista; o atraso de cada item vem do índice |
| `CajuiCountUp` | O número conta do valor antigo ao novo |
| `CajuiIcon` + `CajuiIconData` | 19 ícones de traço, desenhados como caminhos vetoriais: recibo, câmera, cartão, carteira, vale, dívida, calendário, gráfico, conversa, compartilhar, som, visto, fechar, mais, avançar, voltar, ajustes, informação, sem rede |

Os dois efeitos consultam o nível de movimento do tema e aparecem prontos em `reduced`. A revisão deles contra a WCAG 2.2.2 (conteúdo que se move sozinho) é o item BL-024.

## Regras de composição

1. **Uma tela, uma pergunta.** O número-manchete responde a ela; o resto apoia.
2. **Dinheiro e vale nunca se somam** (RN-111). O vale tem cartão próprio, em tom `accent`, e nunca entra num total com dinheiro.
3. **Ação principal embaixo**, ao alcance do polegar; ações de um aviso ficam dentro do aviso.
4. **Toda tela tem os quatro estados mínimos**: carregando, com dados, erro e sem rede — mais os próprios, conforme a [matriz de telas](../spec/use-cases.md#telas-e-seus-estados).
5. **Má notícia entra devagar e em silêncio.** Tela de falta não toca som, não usa vermelho de erro e sempre traz ao menos uma saída concreta.
