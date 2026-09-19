# WAI-ARIA Authoring Practices Guide (APG)

| Fonte | Versão ou edição lida | Acesso |
|---|---|---|
| [ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) — padrões e práticas | Documento vivo do W3C, sem número de versão; rodapé com copyright de 2026. Não é norma: é guia de autoria | 2026-09-19 |
| [Flutter — acessibilidade na web](https://docs.flutter.dev/ui/accessibility/web-accessibility) e páginas vizinhas | Página atualizada em 2026-05-05; índice de acessibilidade atualizado em 2026-07-31 | 2026-09-19 |
| [API `SemanticsRole`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html) e [`SemanticsProperties`](https://api.flutter.dev/flutter/semantics/SemanticsProperties-class.html) | Documentação do canal estável na data de acesso | 2026-09-19 |

## Por que esta fonte importa para o Cajui

- A APG é a referência do que um usuário de teclado e de leitor de tela **espera** de um diálogo, de uma aba, de um menu. Quem usa NVDA aprendeu esses padrões em outros sites; se o Cajui fugir deles, o painel web fica inutilizável mesmo com ARIA "correta".
- No Flutter Web não escrevemos HTML: quem emite os papéis ARIA é o motor de semântica. Então a APG entra de duas formas — **(a) contrato de teclado e foco** que cada componente do design system precisa cumprir e **(b) roteiro de teste** com leitor de tela (o que deve ser anunciado).
- O princípio de abertura da APG — "No ARIA is better than bad ARIA", porque "a role is a promise" — decide o que fazer quando o Flutter não tem o papel que o padrão pede (medidor, feed, listbox, grid): não aproximar com papel errado.
- A marca quer componentes sob medida e movimento próprio. Cada widget escrito do zero perde teclado e semântica que o Material já entrega; a APG dá a lista exata do que precisa ser reposto.

## O que se aplica

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| Read Me First: papel é promessa; ARIA errada é pior que nenhuma; testar com tecnologia assistiva; a APG não garante suporte em mobile e toque | Regra geral para todo uso de `Semantics(role: …)` | D-APG-01, D-APG-02, D-APG-20 |
| Dialog (modal) | Editar lançamento, confirmar dados do OCR na web, preferências | D-APG-04 |
| Alert e Alert Dialog | Erros, avisos, confirmação de exclusão, limpar dados | D-APG-05, D-APG-06 |
| Tabs | Painel (mês / semana), relatórios por bloco (fixos, variáveis, dívidas) | D-APG-07 |
| Disclosure | "Ver como calculamos", detalhe de um bloco de despesas | D-APG-08 |
| Switch | Preferências: sons, vibração, movimento reduzido | D-APG-09 |
| Slider | Simulações ("e se eu cortar X?") | D-APG-10 |
| Combobox e Listbox | Categoria, forma de pagamento, seletor de mês | D-APG-11 |
| Menu Button (+ Menu) | Ações da linha (editar, duplicar, excluir), menu de conta | D-APG-12 |
| Table e Grid | Relatórios e extrato no modo consulta | D-APG-13 |
| Tooltip | Botões só com ícone, explicação de indicador | D-APG-14 |
| Meter | Barra de limite semanal, % da renda comprometida | D-APG-15 |
| Feed | Conversa com a IA | D-APG-16 |
| Prática de landmarks | Estrutura das telas da web | D-APG-17 |
| Prática de nomes e descrições acessíveis | Todo `semanticLabel`, rótulo e dica | D-APG-18 |
| Prática de interface de teclado | Ordem de Tab, setas em compostos, atalhos | D-APG-19 |

### Contrato por padrão (o que a APG espera)

| Padrão | Papéis e estados ARIA | Teclado | O que a semântica do Flutter oferece |
|---|---|---|---|
| Dialog (modal) | `role=dialog`, `aria-modal=true`, nome por `aria-labelledby` (título visível) ou `aria-label`; `aria-describedby` opcional. `aria-modal` só se o fundo estiver de fato inerte e visualmente encoberto | Ao abrir, o foco entra no diálogo; Tab e Shift+Tab circulam **dentro**; Esc fecha; ao fechar, o foco volta a quem abriu. Em ação irreversível, foco inicial na opção menos destrutiva | `SemanticsRole.dialog`; `scopesRoute`/`namesRoute`; `FocusScope` mantém a travessia dentro do escopo e guarda o histórico de foco |
| Alert | `role=alert`. Não recebe nem move foco; alerta presente antes do fim da carga não é anunciado; evitar alerta que some sozinho e alerta frequente | Não se aplica | `SemanticsRole.alert`, `liveRegion`, `SemanticsService.announce`/`sendAnnouncement` com nível educado ou assertivo |
| Alert Dialog | `role=alertdialog`, `aria-modal=true`, nome, e `aria-describedby` apontando **a mensagem** | Igual ao diálogo modal | `SemanticsRole.alertDialog` |
| Tabs | `tablist` (com nome) > `tab` com `aria-selected` e `aria-controls`; `tabpanel` com `aria-labelledby`; `aria-orientation=vertical` se for o caso | Tab entra na aba ativa e depois sai para o painel; ← → movem entre abas com volta ao início; Home/End opcionais; Espaço/Enter ativam se a ativação for manual. Ativação automática recomendada quando o painel aparece sem latência | `tab`, `tabBar`, `tabPanel`; `selected`; `controlsNodes`. `TabBar` gera semântica sozinho (documentado) |
| Disclosure | `button` com `aria-expanded`; `aria-controls` opcional | Enter e Espaço alternam | `button` + `expanded` |
| Switch | `role=switch`, `aria-checked`; o **rótulo não muda** com o estado; grupo com `role=group` nomeado | Espaço alterna; Enter opcional | Não há papel `switch` no enum; há o estado `toggled` ("toggle switch or similar") |
| Slider | `role=slider`, `aria-valuenow/min/max`; `aria-valuetext` quando o número cru não basta; nome obrigatório | → ↑ sobem um passo, ← ↓ descem; Home/End vão ao mínimo/máximo; Page Up/Down dão passo maior (opcional). Aviso da APG: tecnologia assistiva de toque pode não operar | Estado `slider`, `value`, `increasedValue`, `decreasedValue`, `minValue`, `maxValue` |
| Combobox | `role=combobox` no campo, `aria-controls`, `aria-expanded`, `aria-autocomplete`, `aria-activedescendant`; opção com `aria-selected`. O foco do DOM fica no campo | ↓ abre e entra na lista; ↑ ↓ navegam; Enter aceita; Esc fecha; Alt+↓/↑ opcionais; digitar filtra | `SemanticsRole.comboBox`. Não há `listBox` nem `option` no enum |
| Listbox | `listbox` > `option`; `aria-selected` (seleção única) ou `aria-checked` (múltipla) — nunca os dois; `aria-multiselectable` | ↑ ↓; Home/End (recomendado acima de 5 opções); digitação para saltar (acima de 7); Espaço alterna na múltipla. Opção não contém elemento interativo; nome curto, sem prefixo repetido | Sem papel próprio; há `list`/`listItem`, `selected`, `checked`, `radioGroup` |
| Menu Button | `button` com `aria-haspopup=menu` e `aria-expanded`; contêiner `menu` com `menuitem`, `menuitemcheckbox`, `menuitemradio` | Enter, Espaço (e ↓, opcional) abrem e focam o 1º item; ↑ abre no último. No menu: ↑ ↓, Home/End, Enter ativa e fecha, Esc fecha e **devolve o foco ao botão**, Tab fecha, letra salta para o item | `menu`, `menuBar`, `menuItem`, `menuItemCheckbox`, `menuItemRadio`. `MenuAnchor` gera semântica sozinho (documentado) |
| Table | `table` > `row` > `columnheader`/`rowheader`/`cell`; nome; legenda por `aria-describedby`; `aria-sort` no cabeçalho. Estática: célula não recebe foco. A APG manda preferir `<table>` nativa | Não se aplica | `table`, `row`, `cell`, `columnHeader` (não achei `rowHeader`). `Table` gera semântica sozinho (documentado) |
| Grid | `grid` > `row` > `gridcell`; um único ponto de Tab | Setas de célula em célula; Home/End; Ctrl+Home/End; Page Up/Down; Enter ou F2 entram na célula, Esc volta | Não há `grid` nem `gridcell` no enum |
| Tooltip | `role=tooltip`; o gatilho aponta com `aria-describedby`. Padrão **sem consenso** do grupo ("work in progress") | Aparece no foco e no hover; Esc fecha; o foco fica no gatilho; não pode conter elemento focável (aí é diálogo não modal) | `SemanticsRole.tooltip`, propriedade `tooltip`, `SemanticsService.tooltip` |
| Meter | `role=meter`, `aria-valuenow` obrigatório, mín/máx com padrão 0–100, `aria-valuetext` quando a porcentagem não basta ("50% (6 hours) remaining"). **Não** serve para progresso nem para valor sem máximo | Não se aplica | **Não há `meter`.** Há `progressBar`, que a APG diz ser outra coisa |
| Feed | `feed` (nomeado) > `article` com `aria-posinset`/`aria-setsize`; `aria-busy` durante atualização. É estrutura para rolagem infinita de artigos; a página não fala de chat | Page Down/Up vão ao artigo seguinte/anterior; Ctrl+End/Home saem do feed | **Não há `feed` nem `article`** |
| Landmarks | `banner`, `complementary`, `contentinfo`, `form`, `main`, `navigation`, `region`, `search`. Todo conteúdo dentro de algum; rótulo único quando o papel se repete; sem o nome do papel no rótulo; diálogo não precisa | — | `main`, `navigation`, `complementary`, `contentInfo`, `region`, `form`. Não achei `banner` nem `search` |

### O que a semântica do Flutter suporta hoje (o que a documentação diz)

- O Flutter Web "traduz a árvore de semântica em uma estrutura DOM acessível". Isso é **opcional e desligado por padrão** "por desempenho": sem ação nossa, o usuário de leitor de tela precisa acionar um botão invisível `aria-label="Enable accessibility"`. Liga-se no código com `SemanticsBinding.instance.ensureSemantics()`.
- `SemanticsRole` tem 33 valores: `none`, `tab`, `tabBar`, `tabPanel`, `dialog`, `alertDialog`, `table`, `cell`, `row`, `columnHeader`, `dragHandle`, `spinButton`, `comboBox`, `menuBar`, `menu`, `menuItem`, `menuItemCheckbox`, `menuItemRadio`, `list`, `listItem`, `form`, `tooltip`, `loadingSpinner`, `progressBar`, `hotKey`, `radioGroup`, `status`, `alert`, `complementary`, `contentInfo`, `main`, `navigation`, `region`.
- Botão, link, cabeçalho (`header` + `headingLevel`), campo de texto, slider, alternância (`toggled`), marcação (`checked`/`mixed`), seleção, expansão, habilitado, obrigatório (`isRequired`), resultado de validação (`validationResult`), região viva e relação de controle (`controlsNodes`) são **estados e propriedades**, não papéis do enum.
- A documentação afirma semântica automática para `TabBar`, `MenuAnchor` e `Table`. Não diz o que `DropdownMenu`, `Autocomplete`, `DataTable`, `AlertDialog`, `Tooltip` e `SnackBar` emitem na web.
- Leitores de tela indicados para web: NVDA e JAWS no Windows, VoiceOver no macOS, TalkBack e VoiceOver nos navegadores móveis.
- Depuração: `flutter run -d chrome --profile --dart-define=FLUTTER_WEB_DEBUG_SHOW_SEMANTICS=true` mostra os nós e permite ver os atributos ARIA no DevTools.
- Foco: travessia padrão por ordem de leitura (`ReadingOrderTraversalPolicy`), agrupável com `FocusTraversalGroup`; `FocusableActionDetector` junta foco, atalhos, ações e hover; o realce de foco some em modo toque e volta com teclado ou mouse; pedido de foco só vale no quadro seguinte.

## Decisões

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-APG-01 | A APG não é implementada atributo por atributo. Entra como contrato: cada componente do design system tem uma seção "Teclado e semântica" que cita o padrão da APG, lista as teclas e o anúncio esperado (papel, nome, estado) | Fase 3, modelo de especificação de componente do design system | Revisão de PR: componente sem essa seção não entra |
| D-APG-02 | Papel é promessa: só se declara `SemanticsRole` se o widget cumpre o teclado daquele papel. Quando o Flutter não tem o papel (meter, feed, listbox, grid), **não se aproxima com papel errado** — cai-se para nome + valor em texto. É proibido injetar ARIA à mão, por JavaScript, no DOM de semântica | Fase 4, ADR "Acessibilidade no Flutter Web" | Revisão de código; verificação no CI dos usos de `SemanticsRole.` contra a lista permitida do design system |
| D-APG-03 | Semântica sempre ligada na web: `ensureSemantics()` no `main()` quando `kIsWeb`. O custo é medido, não presumido | Fase 4 (mesmo ADR) e Fase 6 | Teste de integração web: nós `flt-semantics` presentes sem acionar "Enable accessibility"; Lighthouse de desempenho antes e depois |
| D-APG-04 | Diálogo modal pelo mecanismo padrão do Material, com título como nome. Ao abrir, foco no primeiro campo; em ação irreversível (excluir lançamento, limpar dados), foco inicial em "Cancelar". Tab circula dentro, Esc fecha, foco volta ao disparador, fundo inerte | Fase 3, componente Diálogo | Teste de widget: abrir pelo teclado, foco dentro, N vezes Tab sem sair, Esc fecha, `FocusManager.primaryFocus` volta ao disparador |
| D-APG-05 | `alertDialog` só para confirmar ação destrutiva e para erro bloqueante que exige resposta; a mensagem é a descrição do diálogo. Informação simples nunca abre diálogo | Fase 3 e `docs/spec/error-catalog.md` (coluna "apresentação": inline, alerta ou diálogo de alerta) | Teste de esquema do catálogo; teste de widget confere o papel |
| D-APG-06 | Alerta de erro não move o foco, **não some sozinho** (fica até ser dispensado ou aparece inline) e é um por ação. Sucesso é `status` educado e pode sumir, porque o resultado continua visível na tela (o lançamento aparece na lista). Texto presente desde a carga não é tratado como alerta | Fase 3, componentes de feedback | Teste de widget: snackbar de erro sem temporizador e com botão de fechar; papel ou região viva presentes |
| D-APG-07 | Abas com `TabBar`/`TabBarView`. Contrato: um único ponto de Tab na lista (a aba ativa), ← → com volta ao início, Home/End, ativação automática (painéis locais, sem latência), Tab leva ao painel. Se o `TabBar` padrão não cumprir, envolve-se em `FocusTraversalGroup` + `Shortcuts` | Fase 3, componente Abas | Teste de widget de teclado; NVDA anuncia aba, selecionada, posição |
| D-APG-08 | Disclosure é botão com estado `expanded`; Enter e Espaço; o nome não muda ao abrir; conteúdo oculto sai da árvore de semântica | Fase 3 | `matchesSemantics` com botão + estado de expansão; teste de teclado |
| D-APG-09 | Switch do Material para preferência de efeito imediato; checkbox para seleção em formulário. Rótulo fixo ("Sons", "Movimento reduzido"), nunca "Ligar sons"/"Desligar sons"; Espaço e Enter alternam; switches agrupados sob cabeçalho | Fase 3 | `matchesSemantics` com estado `toggled`; teste de teclado |
| D-APG-10 | Slider nunca é o único caminho: sempre ao lado de um campo numérico (cobre também a WCAG 2.5.7). Valor falado em reais (equivalente ao `aria-valuetext`); setas ± um passo, Home/End, Page Up/Down com passo maior | Fase 3, componente Slider | Teste de widget das ações semânticas de aumentar e diminuir; teste manual com TalkBack, por causa do aviso da APG sobre toque |
| D-APG-11 | Até 7 opções fixas: grupo de rádio ou chips, não combobox. Lista longa (categoria): `DropdownMenu`/`Autocomplete` do Material com o contrato ↓ abre, ↑ ↓ navegam, Enter aceita, Esc fecha sem mudar o valor e mantém o foco no campo, digitar filtra. Nome de opção curto, palavra que distingue primeiro, sem botão dentro da opção | Fase 3 | Teste de teclado; NVDA anuncia caixa de combinação, recolhida/expandida e a opção ativa |
| D-APG-12 | Botão de menu com `MenuAnchor`. Enter, Espaço e ↓ abrem no 1º item; ↑ ↓ circulam; Home/End; Esc fecha e devolve o foco; Tab fecha. Papel `menu` é só para **ações** — navegação do app é landmark `navigation` com botões, não menu | Fase 3 | Teste de widget de teclado; revisão |
| D-APG-13 | Relatório é **tabela estática, não grid**: papéis `table`/`row`/`columnHeader`/`cell`, nome = título do relatório, descrição = período. Ação por linha é botão real na última célula. Ordenação por botão no cabeçalho, com o estado **no nome** ("Valor, do maior para o menor"), porque suporte a `aria-sort` não está documentado. Grid rejeitado: o Flutter não tem o papel e o contrato de teclado é caro para consulta somente leitura | Fase 3; nota no ADR da Fase 4 | Inspeção do DOM; navegação de tabela do NVDA (Ctrl+Alt+setas) lê os cabeçalhos |
| D-APG-14 | Tooltip nunca carrega informação essencial nem conteúdo interativo. Botão só com ícone tem nome acessível próprio. Aparece no hover **e no foco**, fecha com Esc, permanece com o ponteiro em cima (WCAG 1.4.13). Explicação de indicador usa disclosure ou diálogo | Fase 3 | Teste de teclado: foco mostra, Esc esconde; revisão |
| D-APG-15 | Medidor (limite semanal, % comprometida): nó somente leitura com rótulo "Limite semanal" e valor por extenso — "180 de 250 reais usados, 72%, restam 70 reais"; ao estourar, "passou 30 reais do limite". A barra desenhada vai em `ExcludeSemantics`. **Não usar `progressBar`.** Reavaliar se o Flutter ganhar `meter` | Fase 2 (a RN do indicador fixa a frase) e Fase 3 (componente Medidor) | `matchesSemantics(label, value)`; NVDA e TalkBack leem a frase inteira |
| D-APG-16 | O chat **não é feed**. É `list`/`listItem` em ordem cronológica; cada mensagem é um nó único com autor no início ("Você:", "Cajui:"); resposta nova anunciada uma vez, completa, como `status` educado; "Cajui está respondendo…" também é status. Enter envia, Shift+Enter quebra linha (dito na tela); após enviar, o foco fica no campo. Ação sugerida pela IA é botão real depois do texto. Histórico antigo vem por botão "Carregar mensagens anteriores", não por rolagem infinita | Fase 2 (RN do chat) e Fase 3 (componente Chat) | Testes de semântica; NVDA lê a resposta nova sem mover o foco; fluxo completo só por teclado |
| D-APG-17 | Web: um `main` por tela; `navigation` na barra ou trilho, com nome "Principal"; `complementary` para painel lateral; `region` nomeada só nos blocos grandes (no máximo 5 por tela); rótulo sem o nome do papel. Sem `banner`: o título da tela vira cabeçalho de nível 1 e os blocos, nível 2. No Android não há landmarks: os cabeçalhos fazem esse papel no TalkBack | Fase 3, scaffolds | Lista de landmarks e de cabeçalhos do NVDA confere com o esperado; teste de widget dos papéis do scaffold |
| D-APG-18 | Regra de nome acessível: função e não forma; 1 a 3 palavras; a palavra que distingue primeiro; sem "botão" ou "ícone" no nome; inicial maiúscula, sem ponto final; único entre elementos do mesmo papel na tela ("Editar aluguel", não cinco "Editar"); texto visível é o nome sempre que existir; instrução e formato vão na dica, não no nome | Fase 3, guia de microcopy e convenção dos arquivos de strings | `labeledTapTargetGuideline`; teste próprio que acusa rótulo repetido entre nós tocáveis da mesma tela; busca por "botão" em rótulos semânticos |
| D-APG-19 | Teclado: Tab entre componentes, setas dentro de compostos (abas, menu, rádio, lista), um ponto de Tab por composto; ordem de foco = ordem de leitura; o foco nunca se perde (item excluído → vizinho lógico); sem foco automático ao abrir tela, salvo tela de função única; foco e seleção têm aparência distinta; item de menu desabilitado continua focável. Atalhos próprios: poucos, nunca letra solta, sem colidir com navegador, sistema ou leitor de tela, listados numa tela "Atalhos" | Fase 2 (RNF) e Fase 3 (guia de interação) | Testes de integração de teclado; revisão |
| D-APG-20 | Roteiro com leitor de tela a cada release, por padrão usado: NVDA + Chrome na web e TalkBack no Android, comparando com o "anúncio esperado" de cada componente. O Android é testado por conta própria, não inferido da web (a APG avisa que não cobre mobile e toque) | Fase 3 (documentação do design system) e Fase 7 (`docs/ops/runbook.md`) | Checklist anexado ao PR de release |
| D-APG-21 | A cada atualização do SDK do Flutter, conferir papéis novos em `SemanticsRole` e rever D-APG-13, 15 e 16 | Fase 7, procedimento de atualização no runbook | Item no modelo de PR de atualização |

## O que não se aplica, e por quê

- **Padrões que o Cajui não usa:** accordion (disclosure cobre), breadcrumb, carousel (evitado também pela WCAG 2.2.2), menubar, toolbar, tree view, treegrid, window splitter, spinbutton, slider de múltiplos cursores, link (o app quase não tem hipertexto) e grid (D-APG-13).
- **Tudo o que é técnica de HTML:** `tabindex` itinerante, `aria-activedescendant`, `<table>` e `<label>` nativos, `aria-hidden` no fundo do diálogo, não depender de `title`/`placeholder`. O Flutter decide o DOM; o equivalente nosso é `FocusNode`, `FocusTraversalGroup` e `Semantics`. Os exemplos de código da APG (JS/CSS) não são reaproveitáveis.
- **Feed como estrutura:** feito para rolagem infinita de artigos, depende de `role=feed` para o leitor de tela ativar as teclas de salto. Sem o papel no Flutter, implementar só as teclas seria prometer sem cumprir.
- **Landmarks no Android:** conceito de página web; no app, cabeçalhos e ordem de leitura cumprem a função.
- **`banner` e `search`:** não encontrados no enum do Flutter; o Cajui não tem busca global no escopo atual.

## Pontos de atenção

1. **A semântica web desligada por padrão é a pegadinha nº 1.** Um build sem `ensureSemantics()` passa em todo teste visual e é opaco para leitor de tela. Ligar tem custo de desempenho que a documentação admite e não quantifica — risco direto para a meta de Lighthouse ≥ 90 em desempenho.
2. **Faltam papéis que o plano usa:** meter (limite semanal), feed/log (chat), listbox/option, grid, rowheader. As decisões 13, 15 e 16 contornam com texto, mas a experiência com leitor de tela será mais pobre que a de um app HTML equivalente. É o preço de uma base única em canvas.
3. **A documentação não diz o que cada widget Material emite na web**, salvo `TabBar`, `MenuAnchor` e `Table`. Antes de fechar o design system, fazer um protótipo na Fase 4 com diálogo, dropdown, autocomplete, snackbar, tooltip, switch e slider, inspecionar o DOM e ouvir no NVDA. Sem isso, as decisões 4 a 14 são hipótese.
4. **Esc fechando diálogo, setas no `TabBar`, tooltip no foco de teclado:** comportamentos exigidos pela APG que não estão confirmados na documentação lida. Tratar como itens de teste, não como fato.
5. **UX "requintada" sob medida x custo de acessibilidade:** cada componente reescrito do zero (`CustomPaint`, gesto próprio) perde foco, teclas e semântica, e a conta é o contrato inteiro da tabela acima. Recomendação franca: estilizar widgets Material a fundo em vez de substituí-los; componente 100% próprio só onde não há equivalente (medidor, gráficos).
6. **Snackbar padrão do Material some em segundos**; a APG pede para evitar alerta que desaparece sozinho. Erro precisa de outro veículo (D-APG-06).
7. **Resposta do chat em streaming + região viva = enxurrada de anúncios.** Anunciar só ao final (D-APG-16); o indicador "respondendo…" cobre a espera.
8. **O padrão Tooltip não tem consenso no próprio W3C**, e o padrão Slider traz aviso de que leitor de tela em toque pode não operá-lo. Depender pouco dos dois.
9. **Lighthouse (categoria acessibilidade) audita o DOM de semântica e o shell**, não o teclado nem o canvas. Nota ≥ 90 não demonstra nenhum dos contratos desta página.
10. A APG é documento vivo, sem versão. O alerta ainda cita critérios da WCAG 2.0, e a tabela ARIA é descrita como "novidade da ARIA 1.1". Registrar a data de acesso e reler antes da Fase 3.

## Páginas lidas

- https://www.w3.org/WAI/ARIA/apg/patterns/ — lista dos 30 padrões e descrições.
- https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/ — "No ARIA is better than bad ARIA", papel como promessa, ARIA que encobre semântica, aviso sobre suporte de navegador, tecnologia assistiva, mobile e toque.
- Padrões (https://www.w3.org/WAI/ARIA/apg/patterns/ + nome): `dialog-modal/` (foco inicial, retorno, `aria-modal`), `alert/` (não mover foco, não sumir sozinho), `alertdialog/`, `tabs/` (ativação automática), `disclosure/`, `switch/` (rótulo fixo), `slider/` (aviso de toque), `combobox/` (quatro modos de autocompletar, teclas do campo e da lista), `listbox/` (selected x checked, nomes curtos, sem conteúdo interativo), `menu-button/`, `menubar/` (teclas dentro do menu), `table/` (preferir tabela nativa), `grid/` (dados x layout, edição em célula), `tooltip/` (sem consenso), `meter/` (não é progresso), `feed/` (contrato página x tecnologia assistiva; nada sobre chat).
- Práticas: `practices/landmark-regions/`, `practices/names-and-descriptions/`, `practices/keyboard-interface/` (foco x seleção, tabindex itinerante, conflitos de atalho), `practices/range-related-properties/` (padrões 0–100, quando usar `aria-valuetext`).
- https://docs.flutter.dev/ui/accessibility/web-accessibility — semântica opcional, botão "Enable accessibility", `ensureSemantics()`, `SemanticsRole`, widgets com semântica automática.
- https://docs.flutter.dev/ui/accessibility, `/assistive-technologies`, `/accessibility-testing`, `/ui-design-and-styling` — leitores de tela por plataforma, diretrizes de teste do `flutter_test`, flag de depuração da semântica na web.
- https://docs.flutter.dev/ui/interactivity/focus — `Focus`, `FocusScope`, políticas de travessia, `FocusableActionDetector`, modo de realce.
- https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html — os 33 valores. https://api.flutter.dev/flutter/semantics/SemanticsProperties-class.html — estados e propriedades. https://api.flutter.dev/flutter/semantics/SemanticsService-class.html — `announce`, `sendAnnouncement`, `tooltip`. https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html.
- https://docs.flutter.dev/platform-integration/web/faq, `/web/wasm`, `/web/initialization` — Flutter Web é voltado a aplicação, não a documento; fallback para JavaScript sem WasmGC; o que dá para configurar no shell.
- https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html e `status-messages.html` — condições do tooltip e papéis de mensagem de status.

## Não verificado

- **Qual HTML/ARIA o motor do Flutter emite** para cada papel e estado (`toggled` vira `role="switch"`? `slider` vira `<input type="range">`? `liveRegion` vira `aria-live`? diálogo recebe `aria-modal`?). A documentação lida não detalha; só inspeção do DOM responde.
- Semântica web de `DropdownMenu`, `Autocomplete`, `DataTable`, `AlertDialog`, `Tooltip` e `SnackBar`; teclado padrão do `TabBar`; Esc em diálogo.
- https://docs.flutter.dev/platform-integration/web/renderers — o endereço devolveu a página geral "Web support for Flutter", sem a descrição dos renderizadores; o que se sabe de `--wasm` veio de `/web/wasm`.
- Notas de descontinuação ou ressalvas por plataforma de `SemanticsService.announce`: a página da classe não traz.
- Exemplos funcionais da APG (páginas de exemplo de cada padrão): não abertos; só as páginas de padrão e de prática.
- Padrões não usados pelo Cajui (accordion, carousel, tree view, treegrid, toolbar, spinbutton, window splitter): vistos só na lista.
