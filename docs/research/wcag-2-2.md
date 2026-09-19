# WCAG 2.2 — Web Content Accessibility Guidelines

| Fonte | Versão ou edição lida | Acesso |
|---|---|---|
| [WCAG 2.2](https://www.w3.org/TR/WCAG22/) | W3C Recommendation de 12 dez 2024 (publicação original: 5 out 2023) | 2026-09-19 |
| [What's New in WCAG 2.2](https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/) e páginas *Understanding* de cada critério citado | Conteúdo vigente na data de acesso | 2026-09-19 |
| [WCAG2ICT](https://www.w3.org/TR/wcag2ict-22/) — aplicação da WCAG a software não-web | W3C Group Note de 11 dez 2025 (informativa) | 2026-09-19 |
| [WCAG2Mobile](https://www.w3.org/TR/wcag2mobile-22/) — aplicação a apps móveis | W3C Group Draft Note de 6 mai 2025 (rascunho, informativa) | 2026-09-19 |

## Por que esta fonte importa para o Cajui

- "WCAG 2.2 AA" é meta declarada do projeto; sem traduzir critério por critério, a meta não é testável e vira frase de README.
- O Cajui tem duas superfícies com tecnologia de acessibilidade diferente: app Android (TalkBack, escala de fonte do sistema) e Flutter Web desenhado em canvas (leitor de tela só enxerga a árvore de semântica). A WCAG foi escrita para HTML; aqui está o que sobra dela em cada superfície.
- O domínio é dinheiro: "sobra" e "falta" são o centro da tela, e a marca escolheu duas cores (Vereda e Barro) que em escala de cinza são praticamente a mesma (1,12:1 entre si). O critério 1.4.1 deixa de ser detalhe.
- A marca pede movimento "cinematográfico", som e vibração. Os critérios 2.2.2, 2.3.3 e 1.4.2 definem até onde isso vai sem excluir ninguém.
- Os critérios novos da 2.2 (2.4.11, 2.5.7, 2.5.8, 3.2.6, 3.3.7, 3.3.8) batem direto em biometria, formulário de confirmação do OCR e barras fixas.

## O que se aplica

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| 1.3.3 Características sensoriais (A) | Microcopy, instruções, som e vibração como tokens | D-WCAG-02 |
| 1.4.1 Uso de cor (A) | Sobra x falta, gráficos, campo com erro, medidor de limite | D-WCAG-03 |
| 1.4.2 Controle de áudio (A) — só vale para áudio automático > 3 s | Sons de interface da marca | D-WCAG-25 |
| 1.4.3 Contraste mínimo (AA): 4,5:1; 3:1 em texto grande; sem arredondar; placeholder conta | Paleta de `docs/brand/color.md`, texto sobre gradiente nos heróis | D-WCAG-04 |
| 1.4.11 Contraste não textual (AA): 3:1 contra a cor adjacente | Borda de campo, estados, ícones, barras e fatias de gráfico, anel de foco | D-WCAG-05, D-WCAG-14 |
| 1.4.4 Redimensionar texto (AA): 200% sem perda | Escala de fonte do Android; zoom do navegador na web | D-WCAG-06, D-WCAG-07 |
| 1.4.5 Imagens de texto (AA) — exceção "personalizável" | Texto em canvas no Flutter Web (ver Pontos de atenção) | D-WCAG-07 |
| 1.4.10 Reflow (AA): 320 px CSS de largura = 1280 px a 400% | Layout responsivo da web; tabelas e gráficos são exceção | D-WCAG-08 |
| 1.4.12 Espaçamento de texto (AA) | Formalmente não alcança canvas nem Android; vira regra de token | D-WCAG-09 |
| 2.1.1 Teclado (A) e 2.1.2 Sem armadilha (A) | Web desktop inteira; Android com teclado externo e Switch Access | D-WCAG-10, D-WCAG-11 |
| 2.2.2 Pausar, parar, ocultar (A): > 5 s, automático, em paralelo | Loops de ambiente, shimmer, contagem de número, painel que se atualiza | D-WCAG-12 |
| 2.3.3 Animação por interação (AAA, adotado por escolha) | Modo `reduced` de `docs/brand/motion-and-sound.md` | D-WCAG-13 |
| 2.4.7 Foco visível (AA) | Anel de foco na web e no Android com teclado | D-WCAG-14 |
| 2.4.11 Foco não encoberto (AA): o item focado não pode ficar *inteiramente* escondido | App bar, barra de navegação, campo do chat, snackbar | D-WCAG-15 |
| 2.5.7 Movimentos de arrastar (AA) | Slider, reordenar lista, deslizar para excluir, puxar para atualizar, folha inferior | D-WCAG-16 |
| 2.5.8 Tamanho do alvo (AA): 24×24 px CSS ou espaçamento equivalente | Todo alvo de toque e de ponteiro | D-WCAG-17 |
| 3.2.6 Ajuda consistente (A) — não obriga a ter ajuda | Entrada "Ajuda" na navegação | D-WCAG-18 |
| 3.3.1 Identificação do erro (A) e 3.3.3 Sugestão (AA) | Catálogo de erros; formulário de confirmação do OCR | D-WCAG-19, D-WCAG-20 |
| 3.3.7 Entrada redundante (A): dentro do mesmo processo, não entre sessões | Compartilhar → OCR → confirmar; onboarding; reautenticação no meio do fluxo | D-WCAG-21 |
| 3.3.8 Autenticação acessível (AA) | Biometria (`local_auth`) e login do modo consulta na web | D-WCAG-22 |
| 4.1.2 Nome, função, valor (A) | Todo componente, sobretudo os desenhados à mão (gráficos, medidor, heróis) | D-WCAG-23 |
| 4.1.3 Mensagens de status (AA) | "Despesa registrada", "Lendo o comprovante…", resposta do chat, erros | D-WCAG-24 |

### Como a WCAG chega ao Android e o que muda para o Flutter Web

O W3C não mantém diretriz separada para mobile: afirma que a WCAG cobre mobile e publica duas notas **informativas** de interpretação. A WCAG2ICT troca "página web" por "programa/tela", "conjunto de páginas" por "conjunto de programas" e manda usar a unidade independente de densidade da plataforma no lugar do pixel CSS — **dp no Android**. Diz que 4.1.2 se cumpre pelos serviços de acessibilidade da plataforma, que 1.4.4 aceita "até onde a escala da plataforma chegar" e que a senha que destrava o sistema operacional está fora do escopo de 3.3.8. A WCAG2Mobile (rascunho) usa "tela/visão" como unidade e declara 1.4.12 não aplicável quando a plataforma não permite sobrescrever estilo de texto.

| Tema | App Android | Flutter Web |
|---|---|---|
| Quem fala com a tecnologia assistiva | Semântica do Flutter → API de acessibilidade do Android → TalkBack. Sempre ligada | Semântica do Flutter → DOM paralelo com ARIA. **Desligada por padrão**; liga com `SemanticsBinding.instance.ensureSemantics()` |
| Texto a 200% | Escala de fonte do sistema, respeitada pelos widgets de texto | Zoom do navegador + ajuste de tamanho dentro do app |
| Reflow | Tela já é estreita; risco é fonte grande em 360 dp | Zoom de 400% em 1280 px cai em 320 px lógicos: o layout compacto precisa existir na web |
| Alvo | 48×48 dp (orientação Android, acima dos 24 da WCAG) | 24×24 px lógicos no mínimo; 48 como padrão |
| Teclado | Teclado externo e Switch Access | Requisito central (2.1.1, 2.4.7, 2.4.11) |
| Movimento reduzido | Ajuste "Remover animações" → `MediaQuery.disableAnimations` | `prefers-reduced-motion`; repasse ao Flutter não documentado |
| Técnicas HTML/CSS da WCAG | Não se aplicam | Só alcançam o `index.html` de shell |

## Decisões

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-WCAG-01 | Alvo: todos os critérios A e AA da WCAG 2.2 nas duas superfícies, lidos no Android pela WCAG2ICT (tela = página, dp = px CSS). 2.3.3 (AAA) adotado por escolha. Na web a declaração é "AA com ressalvas documentadas" (1.4.5 e 1.4.12, ver Pontos de atenção) | Fase 2, `docs/spec/` (RNF de acessibilidade, matriz critério × superfície) | Revisão da matriz em PR; nenhum critério sem linha "como se testa" |
| D-WCAG-02 | Nenhuma instrução identifica controle só por cor, forma, posição ou som ("toque no botão verde", "à direita", "quando ouvir o som"). Sempre pelo rótulo visível. Som e vibração nunca são o único canal | Fase 3, guia de voz do design system e `error-catalog.md` | Busca no CI por termos proibidos nos arquivos de strings; revisão de PR |
| D-WCAG-03 | Sobra e falta diferem por **palavra** ("Sobra"/"Falta") no rótulo, **ícone de forma diferente** e valor falado por extenso ("falta de 120 reais"), além da cor. Vale para gráficos (rótulo direto ou padrão), campo com erro e medidor estourado | Fase 2 (RN dos indicadores define o texto) e Fase 3 (tokens `intent.*`) | Golden test em escala de cinza dos componentes de indicador; teste de semântica do rótulo |
| D-WCAG-04 | Texto: 4,5:1; texto grande (≥ 24 px, ou ≥ 18,66 px em negrito): 3:1; comparação sem arredondar (4,499 reprova); placeholder conta como texto; texto sobre gradiente ou imagem é medido no pior ponto | Fase 3, tokens de cor | Teste unitário que calcula a razão de todos os pares frente/fundo usados, nos dois temas, e quebra o build; `textContrastGuideline` nos testes de widget |
| D-WCAG-05 | 3:1 contra o adjacente para borda de campo, indicador de estado, ícone com significado e partes de gráfico. Campo não pode ser delimitado só pelo preenchimento; Capim dourado nunca é o único preenchimento com significado | Fase 3, tokens `border.*`, `icon.*`, `chart.*` | Mesmo teste de pares, meta 3:1 |
| D-WCAG-06 | Android: a escala de fonte do sistema é honrada até 200%, sem limite artificial no `textScaler`; nenhum contêiner de texto com altura fixa; números-herói quebram linha em vez de cortar | Fase 2 (RNF) e Fase 3 (componentes) | Testes de widget em 360×640 dp com escala 1,0, 1,3 e 2,0 sem exceção de overflow; teste manual no aparelho com fonte no máximo |
| D-WCAG-07 | Web: zoom do navegador a 200% sem perda; `index.html` sem `user-scalable=no` nem `maximum-scale`; preferência "Tamanho do texto" dentro do app (100% a 200%), que também sustenta a exceção "personalizável" de 1.4.5 | Fase 2 (RNF), Fase 3 (tela de preferências), Fase 6 | Teste manual em Chrome e Firefox a 200%; teste de widget em 1280×720 com escala 2,0 |
| D-WCAG-08 | O layout funciona em 320 px lógicos de largura só com rolagem vertical. Exceção do próprio critério: tabelas de relatório e gráficos rolam na horizontal dentro do componente. Em tela estreita, relatório tabular vira lista de cartões | Fase 3 (breakpoints) e Fase 2 (RNF) | Testes de widget em 320×800; teste manual com zoom de 400% em janela de 1280 px |
| D-WCAG-09 | 1.4.12 não é exigível (canvas e Android), mas o efeito é entregue por token: texto corrido com altura de linha ≥ 1,5 e espaço entre parágrafos ≥ 2× o corpo; nenhum contêiner corta texto se a altura de linha crescer | Fase 3, tokens de tipografia | Teste unitário dos tokens |
| D-WCAG-10 | Web: 100% das funções pelo teclado. Elemento interativo é widget Material ou `FocusableActionDetector`; é proibido `GestureDetector`/`Listener` como única forma de ativar algo. Arrastar, hover e toque longo têm equivalente por tecla | Fase 2 (RNF), Fase 3 (contrato de componente), Fase 6 | Teste de integração por tela que completa os fluxos principais só com Tab, Shift+Tab, Enter, Espaço, Esc e setas; verificação no CI de `GestureDetector` fora do pacote do design system |
| D-WCAG-11 | Sem armadilha de foco: modal contém o foco, mas fecha com Esc e com botão visível; nada de iframe ou `HtmlElementView` que capture foco; saída fora do padrão é explicada na tela | Fase 3 | Teste: abrir cada modal, Esc, foco volta ao disparador |
| D-WCAG-12 | Nada se move sozinho por mais de 5 s ao lado de outro conteúdo: loop de ambiente termina em ≤ 5 s; shimmer vira estado estático com texto "Carregando…"; nenhum carrossel avança sozinho; painel que se atualiza sozinho tem pausa ou "Atualizar agora" | Fase 3, tokens de movimento (duração máxima de loop) | `pumpAndSettle` conclui em toda tela fora de estado de carregamento explícito; revisão dos tokens |
| D-WCAG-13 | Modo `reduced` ligado pelo sistema (Android: "Remover animações"; web: `prefers-reduced-motion`) ou por chave manual. Nele: sem paralaxe, cascata, contagem de número, deslocamento ou escala; fusão curta é permitida (fade e mudança de cor não são "animação de movimento" pelo *Understanding*). O splash do `index.html` segue a mesma regra por CSS | Fase 2 (RNF) e Fase 3 (tokens; caráter já fixado em `docs/brand/motion-and-sound.md`) | Testes de widget com `disableAnimations: true` conferem duração zero ou fusão; teste manual com emulação de `prefers-reduced-motion` no Chrome; na Fase 6, confirmar se o motor web repassa a media query — se não, ler por `matchMedia` |
| D-WCAG-14 | Anel de foco sempre visível em modo teclado, sem tempo limite, com ≥ 2 px de espessura e **afastado 2 px do componente**, para contrastar com a superfície e não com o preenchimento. Meta 3:1 contra toda superfície | Fase 3, token `focus.ring` | Golden de cada componente em estado focado; teste de pares do token de foco contra todas as superfícies |
| D-WCAG-15 | Barras fixas (app bar, navegação, campo do chat, banners) ficam **fora** da área de rolagem, nunca sobrepostas a ela; sobreposição não modal (snackbar, tooltip) não cobre o item focado ou fecha com Esc; mudança de foco rola o item para a área visível | Fase 3, scaffolds de layout | Teste de integração: após cada Tab, o retângulo do widget focado não cruza o das barras fixas, em 1280×720 e 320×800 |
| D-WCAG-16 | Nenhuma função depende de arrastar: slider aceita toque no trilho e tem campo numérico ao lado; reordenar tem "Mover para cima/baixo"; deslizar para excluir tem botão ou menu equivalente; puxar para atualizar tem botão "Atualizar"; folha inferior fecha por botão. Rolagem da plataforma é isenta | Fase 2 (RNF) e Fase 3 (contrato de componente) | Teste de widget que executa cada função só com `tap`; checklist por componente |
| D-WCAG-17 | Android: alvo ≥ 48×48 dp. Web: padrão 48; densidade compacta no desktop só com ≥ 24×24 px lógicos e círculos de 24 px que não se cruzam. Link dentro de frase é isento | Fase 3, token `size.target.min` | `meetsGuideline(androidTapTargetGuideline)` e `labeledTapTargetGuideline` em todas as telas; diretriz customizada de 24×24 para o modo compacto |
| D-WCAG-18 | Se houver ajuda (entrada "Ajuda", perguntas frequentes), ela ocupa a mesma posição relativa em todas as telas de cada superfície — último item da navegação | Fase 3, navegação | Teste de widget do scaffold; revisão |
| D-WCAG-19 | Todo erro de entrada detectado aponta **o campo** e traz **mensagem em texto** presa a ele (nunca só cor ou ícone), exposta na semântica do campo e anunciada (D-WCAG-24). Campo que o OCR não leu entra marcado: "Não consegui ler o valor. Digite o valor do comprovante" | Fase 3, `docs/spec/error-catalog.md` (colunas: código, campo, mensagem, sugestão, canal de anúncio); Fase 2 (RNs de validação) | Teste de widget por validador confere o texto do erro no nó semântico do campo; teste de esquema do catálogo |
| D-WCAG-20 | Toda mensagem de erro traz a correção quando ela é conhecida (formato com exemplo: "Use vírgula para os centavos, por exemplo 45,90"; conjunto fechado: listar as opções). Exceção do próprio critério: erro de autenticação, sessão ou pinning **não detalha a causa**; entra no catálogo na classe `seguranca`, com mensagem neutra e o próximo passo | `error-catalog.md`; referência cruzada no `threat-model.md` (Fase 5) | Teste de esquema: toda entrada tem `sugestao`, ou `classe: seguranca` com justificativa |
| D-WCAG-21 | No mesmo fluxo nada é pedido duas vezes: o que o OCR extraiu chega preenchido; erro de validação ou de rede preserva tudo que foi digitado; o onboarding reaproveita valores já informados; reautenticação no meio do fluxo (exceção de segurança) preserva o formulário | Fase 2, RNs dos fluxos | Testes: forçar erro no envio e conferir campos intactos; reautenticar no meio do fluxo e conferir estado |
| D-WCAG-22 | Android: biometria com retorno para a credencial do aparelho (fora do escopo pela WCAG2ICT). O Cajui **nunca** cria senha ou PIN próprio, CAPTCHA, cálculo ou quebra-cabeça. Web: login sem memorizar nem transcrever — passkey/WebAuthn ou aprovação pelo app Android; se existir campo de credencial, aceita colar e gerenciador de senhas; código redigitado entre aparelhos nunca é o único caminho | Fase 2 (RNF de autenticação), Fase 4 (ADR do login web), Fase 5 (`asvs-checklist.md`) | Revisão do ADR contra esta regra; teste e2e colando em todo campo de credencial; teste manual com gerenciador de senhas |
| D-WCAG-23 | Todo componente expõe nome, função e valor pela semântica do Flutter: widget Material por padrão; o que é desenhado à mão vai embrulhado em `Semantics` com rótulo, valor e estado corretos; decorativo vai em `ExcludeSemantics`. Na web, `ensureSemantics()` na inicialização | Fase 3 (contrato de componente), Fase 4 (ADR: semântica sempre ligada na web), Fase 6 | Testes com `tester.ensureSemantics()` e `matchesSemantics`; inspeção do DOM com `FLUTTER_WEB_DEBUG_SHOW_SEMANTICS=true`; rodada manual com TalkBack e com NVDA + Chrome a cada release |
| D-WCAG-24 | Mensagem de status não move o foco: sucesso e progresso como região viva educada (`liveRegion`, papel `status`), erro como `alert`, carga como `progressBar`/`loadingSpinner`. Resposta do chat é anunciada **uma vez, completa**, não token a token | Fase 3 (componentes de feedback); coluna "canal" do `error-catalog.md` | Teste de widget confere a marca de região viva ou o papel; teste manual com TalkBack e NVDA |
| D-WCAG-25 | Todo som de interface dura menos de 3 s e não há som de ambiente em loop; chave "Sons" própria, independente do volume do sistema, para nunca cobrir a fala do leitor de tela | Fase 3, tokens de som (duração máxima) | Teste de assets confere a duração de cada arquivo |
| D-WCAG-26 | `index.html` (único HTML real sob nosso controle): `<html lang="pt-BR">`, `<title>` descritivo, viewport sem bloqueio de zoom, `<noscript>` com mensagem, indicador de carga com `role="status"` e texto, splash com contraste e movimento reduzido por CSS | Fase 2 (RNF) e Fase 6 (`web/index.html`) | Lighthouse e axe sobre o shell no CI; revisão do HTML |
| D-WCAG-27 | Roteiro manual por release, porque ferramenta automática não enxerga canvas: TalkBack, NVDA + Chrome, só teclado, fonte a 200%, zoom de 400%, escala de cinza, movimento reduzido. Lighthouse ≥ 90 em acessibilidade é condição necessária, não prova | Fase 2 (definição de pronto) e Fase 7 (`docs/ops/runbook.md`, checklist de release) | Checklist preenchido anexado ao PR de release |

## O que não se aplica, e por quê

- **4.1.1 Análise (Parsing):** removido na WCAG 2.2 como obsoleto.
- **1.4.12 como obrigação formal:** o *Understanding* diz que o critério vale para conteúdo em linguagem de marcação e que texto em canvas é tratado como imagem de texto; a WCAG2Mobile o declara não aplicável quando a plataforma não permite sobrescrever estilo. Fica como regra de token (D-WCAG-09).
- **Técnicas HTML/CSS/ARIA (C39, C43 `scroll-padding`, C45 `:focus-visible`, H100, `<label>`):** só alcançam o `index.html`. O equivalente no Flutter é `MediaQuery.disableAnimations`, layout sem sobreposição, modo de realce de foco e `Semantics`.
- **Diretriz 1.2 (mídia baseada em tempo):** o produto não tem vídeo nem áudio de conteúdo.
- **Exceções de CAPTCHA e reconhecimento de objeto de 3.3.8:** o Cajui não usa nenhum teste cognitivo, então não precisa da exceção.
- **Critérios que a WCAG2ICT marca como problemáticos fora da web (2.4.1, 2.4.2, 2.4.5, 3.1.2, 3.2.3, 3.2.4, 3.2.6):** no Android são aplicados por analogia (tela no lugar de página), sem pretensão de conformidade formal.
- **AAA além de 2.3.3 (2.4.12, 2.4.13, 2.5.5, 3.3.9):** fora da meta. 2.4.13 serve só de referência para a espessura do anel de foco.

## Pontos de atenção

1. **A semântica do Flutter Web nasce desligada.** Sem `ensureSemantics()`, o leitor de tela encontra um único botão invisível "Enable accessibility". A documentação diz que é assim "por desempenho": ligar sempre tem custo, e isso disputa com a meta de Lighthouse ≥ 90 em desempenho. Medir na Fase 6 antes de prometer os dois números.
2. **Texto em canvas é "imagem de texto" para o W3C.** Um auditor rigoroso pode reprovar o Flutter Web em 1.4.5 e 1.4.12, porque o usuário não consegue aplicar folha de estilo própria. A mitigação (ajuste de tamanho dentro do app + zoom) é defensável, não blindada. Para um app pessoal de usuário único o risco é aceitável, mas a meta precisa ser escrita como "AA com ressalvas".
3. **Lighthouse e axe não enxergam dentro do canvas.** Contraste, tamanho de alvo e ordem de foco do que é desenhado não são medidos; a nota cobre o shell e o DOM de semântica. Sem os testes próprios (pares de token, diretrizes do `flutter_test`, roteiro manual), a nota engana.
4. **A paleta aprovada tem quatro furos medidos** (fórmula da WCAG, mesmos hex de `color.md`): Castanha tênue sobre Areia funda = **4,44:1** — reprova, e é exatamente o par "placeholder dentro de campo"; Areia funda sobre Areia = 1,11:1 — o campo precisa de contorno; Céu (foco) contra Cajuí forte (botão primário) = 1,01:1 — o anel só funciona afastado do botão; Vereda contra Barro = 1,12:1 (1,13:1 no tema escuro) — sobra e falta são indistinguíveis sem o segundo sinal. Luar tênue sobre Noite alta = 3,89:1, já vetado em `color.md`. Corrigir na Fase 3.
5. **"Cinematográfico" x 2.2.2:** contagem animada de número, cascata e herói em loop são conteúdo que se move sozinho. Passam se forem de disparo único e curtos; ambiente em loop contínuo não passa sem controle de pausa.
6. **"Proibido mensagem genérica" x segurança:** 3.3.3 abre exceção quando a sugestão compromete a segurança. Erro de login, sessão e pinning tem de ser vago de propósito. O catálogo precisa da classe `seguranca`, senão a regra do projeto e a ASVS colidem.
7. **O plano não define o login do modo consulta na web.** 3.3.8 elimina senha própria sem suporte a colar/gerenciador e elimina código transcrito como único caminho. Decidir em ADR na Fase 4 junto com a pesquisa de segurança.
8. **Fonte a 200% em 360 dp** é o pior caso do design: número-herói grande + rótulo + moeda. Desenhar essa tela primeiro na Fase 3, não por último.
9. **Snackbar que some sozinho:** a APG e a WCAG tratam aviso que desaparece rápido como barreira. Erro não pode ser snackbar temporizado.
10. **WCAG2ICT e WCAG2Mobile são informativas**, e a segunda é rascunho com seções ainda em aberto. Servem de interpretação, não de norma.
11. A documentação do Flutter cita "44×44 px CSS" como mínimo do W3C; esse é o número do critério AAA. O mínimo AA é 24×24. O projeto usa 48 dp no Android por orientação da plataforma, não da WCAG.
12. `liveRegion` está documentado para Android e iOS, com a ressalva de que o anúncio "pode não ser falado" se o sistema já estiver falando outra coisa. Para a web a documentação não diz o que é emitido.

## Páginas lidas

- https://www.w3.org/TR/WCAG22/ — status (Recommendation, 12 dez 2024), editores, texto normativo de 1.3.3 a 2.4.11; remoção de 4.1.1. A página só foi obtida até a diretriz 2.5 (limite de tamanho na leitura).
- https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/ — os nove critérios novos, níveis, data de 5 out 2023.
- *Understanding* (https://www.w3.org/WAI/WCAG22/Understanding/ + nome): `sensory-characteristics`, `use-of-color`, `audio-control`, `contrast-minimum` (texto grande, placeholder, sem arredondamento), `images-of-text`, `resize-text`, `reflow` (1280 px a 400%, exceções), `non-text-contrast` (estados, gráficos, hover), `text-spacing` (canvas = imagem de texto), `content-on-hover-or-focus`, `keyboard`, `no-keyboard-trap` (modal), `pause-stop-hide`, `animation-from-interactions` (o que é animação de movimento), `focus-visible` (sem tempo limite), `focus-not-obscured-minimum` (barras fixas, F110), `dragging-movements` (alternativas por componente), `target-size-minimum` (círculo de 24 px, exceções), `consistent-help`, `error-identification`, `error-suggestion` (exceção de segurança), `redundant-entry` (mesmo processo, não entre sessões), `accessible-authentication-minimum` (biometria, colar, gerenciador de senhas), `name-role-value`, `status-messages` (papéis status/alert/log/progressbar).
- https://www.w3.org/TR/wcag2ict-22/ e https://www.w3.org/WAI/standards-guidelines/wcag/non-web-ict/ — natureza informativa, substituições de termos, critérios problemáticos, funcionalidade fechada.
- https://raw.githubusercontent.com/w3c/wcag2ict/main/comments-by-guideline-and-success-criterion.md — notas de 2.5.8, 3.3.8 (senha da plataforma fora do escopo), 2.4.11, 3.3.7, 1.4.4.
- https://raw.githubusercontent.com/w3c/wcag2ict/main/comments-on-definitions-in-wcag-2.2-glossary-in-appendix-a.md — pixel CSS fora da web: dp no Android, pt no iOS.
- https://www.w3.org/WAI/standards-guidelines/mobile/ e https://www.w3.org/TR/wcag2mobile-22/ — posição do W3C sobre mobile; tela/visão como unidade; 1.4.4, 1.4.12, 2.1.1, 4.1.2.
- Flutter: https://docs.flutter.dev/ui/accessibility (checklist de release), `/ui/accessibility/web-accessibility` (semântica opcional na web), `/ui/accessibility/ui-design-and-styling` (escala de fonte, 48 dp), `/ui/accessibility/accessibility-testing` (diretrizes de teste, flag de depuração), `/platform-integration/web/initialization` (shell), https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html, https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html, https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html.
- `docs/brand/color.md` e `docs/brand/motion-and-sound.md` — hex da paleta (razões de contraste recalculadas) e modo `reduced`.

## Não verificado

- Texto normativo de 2.5.7 em diante **na própria página TR** (obtida só até a diretriz 2.5): foi lido nas páginas *Understanding*, que reproduzem o critério, e em "What's New".
- Seções por critério da WCAG2ICT na página TR (obtida só em parte): lidas no arquivo-fonte do repositório oficial. A seção de 4.1.3 não foi localizada.
- WCAG2Mobile: as seções de 2.4.7, 2.4.11, 2.5.7, 2.5.8, 3.2.6, 3.3.7, 3.3.8 e 4.1.3 não vieram no conteúdo recebido ou estão em aberto no rascunho.
- *Understanding* de 2.4.13 e 2.5.5 (AAA): não abertos; citados só pelo resumo de "What's New" e pela menção em 2.5.8.
- Flutter Web: se o motor repassa `prefers-reduced-motion` para `disableAnimations`; se o zoom e o tamanho de fonte padrão do navegador chegam ao `textScaler`; o que `liveRegion` emite no DOM. Nada disso está na documentação lida — verificar em protótipo na Fase 4.
