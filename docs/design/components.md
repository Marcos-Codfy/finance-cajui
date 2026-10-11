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
| `CajuiNavBar` + `CajuiNavDestination` | De 2 a 5 destinos (o app usa 2: Conversar e Início) | Em vigor · repouso · mouse · pressionado · foco | No pé da tela, onde o polegar alcança. O destino em vigor é marcado pela pílula **e** pelo peso do nome. Todo destino tem nome à vista. Cabe em 320 px com fonte a 200% |

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
| `CajuiMeter` | Parte de um todo | Gráfico de progresso (RN-862). Exige o número equivalente em texto. Passar do limite enche a barra e troca para a cor da falta, sem alarme |
| `CajuiRollingAmount` | Valor em reais que rola até o número certo | É `CajuiAmountText` dentro de `CajuiCountUp`. Com `from: 0`, rola desde o zero ao aparecer — um número por tela, no máximo. O leitor de tela ouve só o valor final, uma vez |
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
| `CajuiCountUp` | O número conta do valor antigo ao novo. Com `from`, conta também ao aparecer |
| `CajuiHeroNumber` | O número que voa entre telas: mesma `tag` no Início e no detalhe. A cópia que voa é parada (nada conta no ar); em `reduced` não há voo |
| `CajuiHeroScope` | Liga o voo num app sem Material. Já vem dentro do `CajuiAppSurface`; a gallery o põe no próprio `builder` |
| `CajuiIcon` + `CajuiIconData` | 19 ícones de traço, desenhados como caminhos vetoriais: recibo, câmera, cartão, carteira, vale, dívida, calendário, gráfico, conversa, compartilhar, som, visto, fechar, mais, avançar, voltar, ajustes, informação, sem rede |

Os efeitos consultam o nível de movimento do tema e aparecem prontos em `reduced`. A revisão deles contra a WCAG 2.2.2 (conteúdo que se move sozinho) é o item BL-024.

## Efeitos vivos

Pedidos do dono em 11/10/2026, para o app ficar simples e gostoso de usar. Na gallery, página **Componentes › Efeitos vivos**. Todos seguem as mesmas três regras: **respeitam o movimento reduzido** (viram uma versão parada e completa), **assentam sozinhos** — nada em laço (RNF-A11Y-08) — e **nunca disputam o dedo** com o que a pessoa quer fazer.

A inclinação do aparelho entra de fora, como `CajuiTilt` (um `ValueListenable<Offset>` de -1 a 1): o design system não lê sensor nem tem plugin. Quem alimenta é o app, a partir do acelerômetro; sem fonte, os componentes ficam parados e continuam completos.

| Componente | Para quê | Regras |
|---|---|---|
| `CajuiWaterGauge` | "Pode gastar esta semana" como um pote de água | Esvazia conforme a fração; balança com mola (`CajuiSprings.slosh`) quando o celular inclina e assenta em uns 2 s — o relógio de quadros dorme em seguida. Ao lado, rótulo, valor (rolando desde o zero) e frase: é gráfico de progresso, e o leitor de tela ouve os três. Água é sempre cor de água (`data.water`); valor negativo só troca o tom do número para o da falta. Em `reduced`: nível certo, superfície reta, sem inclinação |
| `CajuiCreditCard3D` | O cartão de crédito que inclina e vira | Perspectiva com o sensor e com o **arrasto de lado** (o de cima para baixo continua rolando a tela). O brilho (`brand.sheen`, no máximo 12%, por baixo do texto) anda ao contrário da inclinação. Um toque vira e mostra em uso, livre, a barra e o percentual; a barra muda de tom na metade (cajuí) e nos 80% (cor da falta), e a frase descreve o fato — "Metade do limite já está em uso" — sem alarme. Nunca fala em "gasto": cartão é forma de pagamento. Um botão só para o leitor de tela, com o lado à mostra por extenso. Com fonte grande, o cartão cresce em vez de cortar. Em `reduced`: reto, brilho parado, virar é fusão curta |
| `CajuiGlow` | O brilho do mês que fecha no verde | Quando `active` passa a verdadeiro, o halo cresce, faíscas de capim dourado sobem **uma vez** (600 ms) e tudo assenta num halo calmo. Quando falta, nada acontece. `celebrateOnAppear` só quando a boa notícia é nova. Fora de `full`, o halo só aparece. O halo é feito de anéis, não de desfoque, para valer também em `lite`. É enfeite: a boa notícia tem de estar dita em texto no bloco |
| `CajuiBarChart` + `CajuiChartBar` | Mês a mês: o que sobrou ou faltou | Barras crescem com mola (`CajuiSprings.grow`) a partir da linha do zero, em cascata. Sobra no tom da sobra, falta no tom **neutro** (`data.fixed`), nunca vermelho. Um toque escolhe o mês; o destaque mostra o valor rolando. Cada barra é botão com "Março: sobrou R$ 312,00", e o escolhido é anunciado como selecionado; ele também se marca pelo peso do nome e por um traço, não só por cor. Coluna mínima de 48: com mês demais, rola de lado começando pelo mais novo |
| `CajuiStreamingText` | A resposta do assistente aparecendo palavra por palavra | Palavras que faltam já ocupam o lugar, transparentes: nada pula de linha. Passo de `CajuiDurations.wordStep` (45 ms), com teto de `streamCap` (4 s) para qualquer tamanho; um toque mostra tudo. Em `reduced`, nasce pronta. O leitor de tela recebe o texto inteiro desde o começo. Se o texto crescer pelo fim, o que já apareceu fica. No balão: `CajuiChatBubble(streamed: true)` |

Som e toque novos: `feedback.entrySaved()` (semente caindo na cuia) e `feedback.undone()` (folha que vai e volta), os dois com o pulso leve de tecla. Quem lança ou desfaz põe o botão sob um `CajuiFeedbackScope` silencioso, para o som de toque não abafar a semente — a gallery mostra o jeito.

**Ponto em aberto.** O `CajuiBarChart` não é parte-todo nem progresso, e a letra da RN-862 só admite esses dois. Ele entrou por decisão do dono (11/10/2026) e cumpre a outra metade da regra — todo valor tem o equivalente em texto —, mas a regra precisa ser revista na especificação.

## Regras de composição

1. **Uma tela, uma pergunta.** O número-manchete responde a ela; o resto apoia.
2. **Dinheiro e vale nunca se somam** (RN-111). O vale tem cartão próprio, em tom `accent`, e nunca entra num total com dinheiro.
3. **Ação principal embaixo**, ao alcance do polegar; ações de um aviso ficam dentro do aviso.
4. **Toda tela tem os quatro estados mínimos**: carregando, com dados, erro e sem rede — mais os próprios, conforme a [matriz de telas](../spec/use-cases.md#telas-e-seus-estados).
5. **Má notícia entra devagar e em silêncio.** Tela de falta não toca som, não usa vermelho de erro e sempre traz ao menos uma saída concreta.
