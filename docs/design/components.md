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

Pedidos do dono em 11/10/2026, para o app ficar simples e gostoso de usar. Na gallery, página **Movimento e som › Microinterações**. Todos seguem as mesmas três regras: **respeitam o movimento reduzido** (viram uma versão parada e completa), **assentam sozinhos** — nada em laço (RNF-A11Y-08) — e **nunca disputam o dedo** com o que a pessoa quer fazer.

A inclinação do aparelho entra de fora, como `CajuiTilt` (um `ValueListenable<Offset>` de -1 a 1): o design system não lê sensor nem tem plugin. Quem alimenta é o app, a partir do acelerômetro; sem fonte, os componentes ficam parados e continuam completos.

| Componente | Para quê | Regras |
|---|---|---|
| `CajuiCreditCard3D` | O cartão de crédito que inclina e vira | Perspectiva com o sensor e com o **arrasto de lado** (o de cima para baixo continua rolando a tela). O brilho (`brand.sheen`, no máximo 12%, por baixo do texto) anda ao contrário da inclinação. Um toque vira e mostra em uso, livre, a barra e o percentual; a barra muda de tom na metade (cajuí) e nos 80% (cor da falta), e a frase descreve o fato — "Metade do limite já está em uso" — sem alarme. Nunca fala em "gasto": cartão é forma de pagamento. Um botão só para o leitor de tela, com o lado à mostra por extenso. Com fonte grande, o cartão cresce em vez de cortar. Em `reduced`: reto, brilho parado, virar é fusão curta |
| `CajuiGlow` | O brilho do mês que fecha no verde | Quando `active` passa a verdadeiro, o halo cresce, faíscas de capim dourado sobem **uma vez** (600 ms) e tudo assenta num halo calmo. Quando falta, nada acontece. `celebrateOnAppear` só quando a boa notícia é nova. Fora de `full`, o halo só aparece. O halo é feito de anéis, não de desfoque, para valer também em `lite`. É enfeite: a boa notícia tem de estar dita em texto no bloco |
| `CajuiBarChart` + `CajuiChartBar` | Mês a mês: o que sobrou ou faltou | Barras crescem com mola (`CajuiSprings.grow`) a partir da linha do zero, em cascata. Sobra no tom da sobra, falta no tom **neutro** (`data.fixed`), nunca vermelho. Um toque escolhe o mês; o destaque mostra o valor rolando. Cada barra é botão com "Março: sobrou R$ 312,00", e o escolhido é anunciado como selecionado; ele também se marca pelo peso do nome e por um traço, não só por cor. Coluna mínima de 48: com mês demais, rola de lado começando pelo mais novo |
| `CajuiStreamingText` | A resposta do assistente aparecendo palavra por palavra | Palavras que faltam já ocupam o lugar, transparentes: nada pula de linha. Passo de `CajuiDurations.wordStep` (45 ms), com teto de `streamCap` (4 s) para qualquer tamanho; um toque mostra tudo. Em `reduced`, nasce pronta. O leitor de tela recebe o texto inteiro desde o começo. Se o texto crescer pelo fim, o que já apareceu fica. No balão: `CajuiChatBubble(streamed: true)` |

Som e toque novos: `feedback.entrySaved()` (semente caindo na cuia) e `feedback.undone()` (folha que vai e volta), os dois com o pulso leve de tecla. Quem lança ou desfaz põe o botão sob um `CajuiFeedbackScope` silencioso, para o som de toque não abafar a semente — a gallery mostra o jeito.

**Ponto em aberto.** O `CajuiBarChart` não é parte-todo nem progresso, e a letra da RN-862 só admite esses dois. Ele entrou por decisão do dono (11/10/2026) e cumpre a outra metade da regra — todo valor tem o equivalente em texto —, mas a regra precisa ser revista na especificação.

## Profundidade

Pedido do dono em 11/10/2026: "3D scrolling, com animações cinematográficas". Na gallery, grupo **Movimento e som**, uma página por componente, cada uma num palco do tamanho de um celular. As escolhas e o custo estão na [ADR-028](../architecture/adr/ADR-028-rolagem-3d-e-entrada-cinematografica.md).

Todos usam a mesma lente (`CajuiDepth.perspective`) e a mesma geometria: **a superfície é a face de um tambor** — de frente no meio, curvando para longe nas bordas. Tudo é matriz aplicada na pintura: o texto continua texto, e o toque e o leitor de tela acompanham a matriz.

| Componente | Para quê | Regras |
|---|---|---|
| `CajuiDepthScroll` | Corpo de tela feita de seções, como o Início | Só curva o que está **cortado pela borda** (faixa de 32% da altura, no máximo a altura do bloco): entra deitado e menor por baixo, assenta, recua por cima e é coberto pelo seguinte. Inteiro à vista, plano — matriz identidade, sem camada. Fundo opcional (`backdrop`) sobe a 1/3 da velocidade. Física que quica, sempre rolável. `lite`: sem esmaecer. `reduced`: lista comum, fundo parado |
| `CajuiParallax` | Camada em outra velocidade dentro de qualquer rolagem | `factor` positivo fica para trás, negativo adianta. No centro da tela, está onde o layout a pôs. Enfeite: para o fundo, nunca para o número. `reduced`: parada |
| `CajuiCoverFlow` | Poucos blocos irmãos que se folheiam: os números do mês | A do centro de frente; as vizinhas giram com a borda de fora para longe, encolhem, esmaecem e enfiam a borda de dentro atrás da do centro. Encaixe com `CajuiSprings.page`; um gesto passa uma página só; a ponta cede e volta. **Sem arrastar**: tocar na vizinha, os pontos (toque e setas) ou o ajuste do leitor de tela. Cada página é anunciada "Página 2 de 4"; página fora do palco continua na leitura e, ao receber o foco, vem para o centro. Altura da página mais alta. Pop do card e pulso de tecla no soltar (`pageTurned`). `reduced`: plano, lado a lado, troca é corte com esmaecer de 120 ms |
| `CajuiCinematicEntrance` + `CajuiCinematicShot` | O travelling ao abrir uma tela | Cada tomada vem de longe (escala 0,86), de baixo (28 px), deitada (~10°) e fora de foco (sigma 8), e assenta com `CajuiCurves.settle`. Opacidade antes do foco, foco antes do fim. Cascata de 35 ms; do 6º bloco em diante, juntos; tudo em 600 ms. Uma faixa de luz rasante cruza uma vez, no máximo a 12%. Roda uma vez, e de novo só se `replayKey` mudar; espera a tela estar à vista. O leitor de tela acha os blocos desde o primeiro quadro. `lite`: sem desfoque nem luz. `reduced`: esmaecem juntos, em 120 ms |
| `CajuiWalletStack` | Os cartões da tela de Cartões | Ao aparecer, saem de um maço, o da frente primeiro (dentro de uma entrada cinematográfica, no ritmo dela). Rolando, cada cartão para no alto da tela e é coberto pelo seguinte; puxando além do topo, abrem em leque. O layout é sempre o da coluna aberta: a rolagem não pula, e o toque acha o cartão onde ele aparece. `lite`: sem escurecer os de trás. `reduced`: coluna parada |

O `CajuiScreen` liga os dois efeitos de tela sem montagem à mão: `depth: true` troca a lista pela `CajuiDepthScroll` (com `backdrop`), e `cinematic: true` faz do alto e de cada filho uma tomada, com `replayKey` para rodar de novo. Para tela de painel; em formulário o efeito só atrapalha.

## Vidro

Pedido do dono em 12/10/2026: o widget da tela inicial "mais surrealista, com glassmorfismo", e um efeito ao abrir o app por ele. Na gallery, página **O app › Widget da tela inicial**, com o gesto inteiro: o widget na tela inicial, o app crescendo de dentro dele e a chegada no Início.

O widget Android é desenhado por outro processo (`RemoteViews`): não desfoca o papel de parede, não tem sombreador nem animação própria. Por isso o vidro **não desfoca nada**, nem na réplica: a aurora já é difusa, e o véu sobre ela parece fosco sem desfoque. Os desenháveis do Android (`home_widget_aurora.xml`, `home_widget_glass.xml`, `home_widget_orb.xml`) usam os mesmos valores dos componentes.

| Componente | Para quê | Regras |
|---|---|---|
| `CajuiAurora` | O fundo do widget: a aurora do Cerrado à noite | O céu de `brand.auroraSky` com as três luzes de `brand.aurora` — cajuí no alto à esquerda, capim dourado à direita, vereda embaixo —, todas sem contorno. Sempre noite, nos dois temas |
| `CajuiGlassPanel` | O vidro sobre a aurora | Véu branco translúcido, borda de luz e o reflexo no alto. `round: true` é o botão de vidro. Texto sobre ele em `brand.sheen` |
| `CajuiOrb` + `CajuiOrbTone` | A esfera de luz que flutua fora do painel | `fruit` (do dourado ao terracota) ou `vereda`. Enfeite puro: sem nome para o leitor de tela |
| `CajuiGlassArrival` | A chegada no app pelo widget | Roda quando `arrival` muda para um valor diferente de zero, uma vez. O bloco chega coberto pelo véu, a 0,9 do tamanho, com a aurora acesa atrás; o véu se desfaz, o bloco assenta com `CajuiCurves.settle`, a aurora se apaga e a faixa de luz cruza uma vez, com o pop do card. Cabe em `slowest` (600 ms). A forma da árvore não muda, para o carrossel não perder a página. `lite`: sem aurora nem luz. `reduced`: só o véu se desfaz, em 120 ms |

No app, o toque no saldo ou no fundo do widget abre a rota `widget` (`MainActivity.ACTION_WIDGET`): o app volta ao Início, fecha o que estiver aberto por cima e soma um ao `widgetArrivalProvider`, que a `CajuiGlassArrival` em volta dos números escuta. A raiz do widget é `@android:id/background`, e é isso que deixa o Android 12+ abrir o app crescendo de dentro dele. Os dois atalhos (câmera e galeria) continuam abrindo a captura, sem a chegada.

## Regras de composição

1. **Uma tela, uma pergunta.** O número-manchete responde a ela; o resto apoia.
2. **Dinheiro e vale nunca se somam** (RN-111). O vale tem cartão próprio, em tom `accent`, e nunca entra num total com dinheiro.
3. **Ação principal embaixo**, ao alcance do polegar; ações de um aviso ficam dentro do aviso.
4. **Toda tela tem os quatro estados mínimos**: carregando, com dados, erro e sem rede — mais os próprios, conforme a [matriz de telas](../spec/use-cases.md#telas-e-seus-estados).
5. **Má notícia entra devagar e em silêncio.** Tela de falta não toca som, não usa vermelho de erro e sempre traz ao menos uma saída concreta.
