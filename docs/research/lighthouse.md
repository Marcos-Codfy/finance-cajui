# Lighthouse

| Campo | Valor |
|---|---|
| Fonte | https://developer.chrome.com/docs/lighthouse/ · código e changelog em github.com/GoogleChrome/lighthouse · github.com/GoogleChrome/lighthouse-ci · complemento sobre Flutter Web em docs.flutter.dev e flutter.dev/blog |
| Versão lida | Lighthouse **13.5.0** (changelog, 2026-09-17), pesos conferidos no `core/config/default-config.js` da `main`. Lighthouse CI `@lhci/cli` 0.15.x. Docs do Flutter marcadas como Flutter 3.47.2 (páginas atualizadas entre 2026-05 e 2026-09) |
| Acesso | 2026-09-19 |

## Por que esta fonte importa para o Cajui

"Lighthouse >= 90 nas quatro categorias" é requisito não-funcional do modo consulta web. O Flutter Web é o pior caso para essa régua: desenha em canvas, baixa um runtime de megabytes antes do primeiro quadro e só expõe DOM pela árvore de semântica. Esta pesquisa fixa o que exatamente se mede, com qual configuração, o que o Flutter oferece para chegar lá e o que fazer se não chegar. Sem isso a meta vira número de vaidade ou trava a Fase 6.

## O que se aplica

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| Nota de performance = média ponderada de 5 métricas: **TBT 30 %, LCP 25 %, CLS 25 %, FCP 10 %, SI 10 %** (INP entra com peso 0). As demais auditorias de performance (insights, payload, cache) têm peso 0 | Só essas cinco decidem a nota; o resto é diagnóstico | D-LH-09 |
| Curvas do desktop são mais rígidas: verde até FCP 0,9 s, SI 1,3 s, LCP 1,2 s, TBT 150 ms (mobile: 1,8 s / 3,4 s / 2,5 s / 200 ms). CLS bom até 0,1 | Preset desktop não é "modo fácil" | D-LH-01, D-LH-09 |
| Preset desktop = `desktopDense4G` (RTT 40 ms, 10 Mbps, CPU 1x), tela 1350x940. Mobile = slow 4G (150 ms, 1,6 Mbps, CPU 4x). Throttling simulado (Lantern) é o padrão | A web do Cajui é consulta em desktop | D-LH-01 |
| Candidatos a LCP: `<img>`, `<image>` em SVG, poster de vídeo, `background-image: url()`, blocos de texto. **Canvas não é candidato.** FCP conta texto, imagem, SVG e canvas não branco | O LCP do Cajui será medido no shell HTML, não no painel desenhado | D-LH-03, D-LH-06 |
| Acessibilidade = média ponderada de auditorias axe binárias (peso 10: button-name, aria-*, label, meta-viewport; peso 7: color-contrast, document-title, html-has-lang). Auditoria manual não pontua | O axe só enxerga DOM: `index.html` + nós `flt-semantics` | D-LH-10, D-LH-11 |
| Boas práticas, pesos: is-on-https 5, deprecations 5, third-party-cookies 5, paste-preventing-inputs 3; errors-in-console, inspector-issues, doctype, charset, redirects-http e image-* 1. csp-xss, has-hsts, origin-isolation, clickjacking-mitigation e trusted-types-xss têm **peso 0** | Cabeçalho de segurança não dá ponto, mas aparece no relatório | D-LH-12, D-LH-19 |
| SEO, pesos: **is-crawlable 4,04**; document-title, meta-description, http-status-code, link-text, crawlable-anchors, robots-txt, image-alt, hreflang e canonical 1 cada | `noindex` sozinho derruba a categoria | D-LH-13 |
| Categoria PWA removida na 12.0.0 (2024-04-22) | Nenhuma meta de PWA | Não se aplica |
| Categoria "Agentic Browsing": entrou no config padrão na 13.3.0 (2026-05); a doc a chama de experimental, pede Chrome 150+ e mostra fração de checagens, não nota 0-100 | "Quatro categorias" precisa ser lista explícita | D-LH-01 |
| LHCI: `collect` (staticDistDir, isSinglePageApplication, numberOfRuns padrão 3, `settings.preset: desktop`), `assert` (minScore por categoria, maxNumericValue, aggregationMethod), `upload` (temporary-public-storage é **público**) | Gate de CI no GitHub Actions | D-LH-14, D-LH-15 |
| Variabilidade: mediana de 5 execuções é 2x mais estável que 1; mínimo de 2 núcleos dedicados e 4 GB; nunca rodar em paralelo na mesma máquina; a doc **desaconselha CI gratuito ou compartilhado** | Runner padrão do GitHub Actions | D-LH-15 |
| Flutter `build web --wasm`: renderer skwasm com fallback para canvaskit; exige WasmGC (Chrome 119+). Firefox e Safari caem no JavaScript por bugs abertos. Multi-thread exige COOP `same-origin` + COEP `credentialless` ou `require-corp` | Build e cabeçalhos da Vercel | D-LH-04, D-LH-05 |
| Flutter init: `flutter_bootstrap.js`, tokens `{{flutter_js}}` e `{{flutter_build_config}}`, `_flutter.loader.load({config, onEntrypointLoaded})`, `initializeEngine()`, `runApp()`. Config: `nonce`, `canvasKitBaseUrl`, `fontFallbackBaseUrl` (padrão fonts.gstatic.com), `forceSingleThreadedSkwasm`. **Service worker não é mais gerado** | Shell, CSP e cache | D-LH-03, D-LH-06 |
| Flutter deferred: `import ... deferred as x` + `x.loadLibrary()` gera `*.js` separados na web. No wasm é experimental (`--enable-wasm-deferred-loading`, Flutter 3.50+) | Divisão por feature | D-LH-07 |
| Flutter a11y: semântica **desligada por padrão na web, por desempenho**; liga por botão invisível "Enable accessibility" ou `SemanticsBinding.instance.ensureSemantics()`; `SemanticsRole` vira role ARIA | WCAG 2.2 AA e nota de acessibilidade | D-LH-10 |
| Blog oficial do Flutter (2024-05): CanvasKit soma ~1,5 MB; não dar `await` caro antes de `runApp`; WebP/AVIF; preload no `<head>`; splash em HTML/CSS no `index.html` | Tempo de carga | D-LH-03, D-LH-08 |
| FAQ do Flutter: a saída "doesn't align with what search engines need"; recomenda Jaspr ou HTML para conteúdo indexável | SEO é só do shell; base do plano B | D-LH-13, D-LH-16 |

### Onde o Flutter Web tende a reprovar

| Auditoria | Por que reprova | Mitigação |
|---|---|---|
| TBT (30 %) | Parse, compilação e execução do código do app mais a subida do engine ocupam a thread principal; verde só até 150 ms | Build wasm (o blog oficial diz que inicia mais rápido que JS), deferred, nada pesado antes do primeiro quadro |
| Speed Index (10 %) | O progresso visual só fecha quando o engine pinta o primeiro quadro | Esqueleto no shell parecido com a primeira tela |
| FCP (10 %) e LCP (25 %) | O `index.html` padrão fica em branco até o engine pintar; canvas não é candidato a LCP | Shell com texto e SVG reais no HTML |
| CLS (25 %) | Troca splash -> canvas e carga de fonte | Splash como overlay `position: fixed`, removido sem reflow |
| Acessibilidade | Semântica desligada = DOM quase vazio = nota alta e sem sentido (tudo "não aplicável"). Ligada, passam a valer button-name, aria-* e label sobre os nós gerados | `ensureSemantics()`, label e role em todo componente do design system, medir sempre com semântica ligada |
| color-contrast | O axe não lê pixel de canvas | Contraste garantido por token (`docs/brand/color.md`) e teste manual |
| SEO | `noindex` reprova is-crawlable; o `index.html` padrão traz título e descrição genéricos | D-LH-12 e D-LH-13 |
| errors-in-console | Requisição 4xx/5xx durante a carga vira erro no console | Checagem de sessão anônima responde 200 (D-LH-19) |
| deprecations (5) e inspector-issues | API usada pelo engine e violação de CSP viram apontamento | Parte fora do nosso controle; CSP validada em Report-Only antes de valer |
| Insights (payload enorme, JS não usado, cache curto) | Runtime grande e arquivos sem hash no nome | Peso 0: registrar, não perseguir |

## Decisões

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-LH-01 | Configuração de referência: Lighthouse 13.x via `@lhci/cli` 0.15.x, `preset: desktop`, throttling simulado, `onlyCategories: [performance, accessibility, best-practices, seo]`. Versões fixadas | Fase 2 (RNF de qualidade web) · Fase 6 (`lighthouserc.json`) | Arquivo no repositório; o relatório mostra `lighthouseVersion` e `formFactor: desktop` |
| D-LH-02 | ">= 90" significa mediana de 5 execuções na URL de produção, com semântica ligada e cache frio | Fase 2 (RNF) | Relatório arquivado a cada deploy de produção |
| D-LH-03 | Shell com primeiro paint real: CSS crítico inline, marca em SVG inline, texto "Cajui" e esqueleto do painel com as cores e blocos da primeira tela; zero requisição bloqueante; overlay fixo removido após o primeiro quadro | Fase 3 (spec de splash e esqueleto no design system) · Fase 6 | FCP <= 0,8 s, LCP <= 1,2 s e CLS <= 0,05 no LHCI |
| D-LH-04 | Build de release com `flutter build web --wasm`, fallback JS mantido. Dependência que use `dart:html`, `package:js` ou `dart:js` é vetada | Fase 4 (ADR de build web) | Job de CI compila com `--wasm`; log de inicialização registra `dart.tool.dart2wasm` |
| D-LH-05 | Servir COOP `same-origin` e COEP `credentialless` para liberar skwasm multi-thread; todo recurso hospedado na própria origem (ver D-VERCEL-10) | Fase 4 (ADR) · Fase 7 (`vercel.json`) | `crossOriginIsolated === true` no console em produção |
| D-LH-06 | `flutter_bootstrap.js` próprio e externo (CSP sem inline), com `<link rel="preload">` para ele e para o binário principal; `performance.mark` em `cajui:entrypoint`, `cajui:engine` e `cajui:first-frame` | Fase 6 | Marcas aparecem em "User Timing" do relatório |
| D-LH-07 | Carregamento adiado por feature: chat com IA, relatórios e gráficos atrás de `deferred as`; a rota inicial carrega só o painel. No wasm, só quando a flag deixar de ser experimental | Fase 4 (ADR; casa com feature-first) | Saída do build tem partes separadas; orçamento de transferência inicial cumprido |
| D-LH-08 | Nada de rede nem `await` caro antes do `runApp`; restauração de sessão acontece depois do primeiro quadro | Fase 4 (ADR) · Fase 6 (checklist de revisão) | Trace: nenhuma requisição antes de `cajui:first-frame` |
| D-LH-09 | Orçamento de performance (tabela abaixo) vira asserção do LHCI | Fase 2 (RNF com números) · Fase 6 | `lhci assert` falha o PR quando estoura |
| D-LH-10 | Semântica sempre ligada na web: `ensureSemantics()` na inicialização sob `kIsWeb`. Performance é medida com ela ligada | Fase 2 (RNF de acessibilidade) · Fase 6 | DOM tem árvore `flt-semantics` sem clicar em nada; acessibilidade >= 0,95 no LHCI |
| D-LH-11 | Nota de acessibilidade é condição necessária, não suficiente: contraste por token, teclado e leitor de tela em roteiro manual | Fase 3 (design system) · Fase 5 (checklist) | Roteiro manual executado por release; evidência anexada |
| D-LH-12 | Shell com `<!doctype html>`, `<html lang="pt-BR">`, charset primeiro, viewport, `<title>`, meta description, theme-color, favicon e `robots.txt` válido | Fase 6 | Auditorias de SEO e boas práticas do shell passam |
| D-LH-13 | Sem `noindex` em produção. A não indexação vem do controle de acesso (D-VERCEL-17). SEO só se mede em produção ou no build local, nunca em preview (a Vercel injeta `X-Robots-Tag: noindex` em preview) | Fase 2 (RNF) · Fase 4 (ADR) | is-crawlable passa em produção; requisição anônima não devolve o app |
| D-LH-14 | Duas camadas: gate de PR contra `build/web` local (`staticDistDir`, `isSinglePageApplication: true`) e medição oficial pós-deploy contra a URL real. Relatório vai para artefato do Actions (`target: filesystem`); **temporary-public-storage é proibido** | Fase 6 (workflow de CI) · Fase 7 (runbook) | Artefato presente em cada execução; nenhuma URL pública de relatório |
| D-LH-15 | Controle de variância: `numberOfRuns: 5`, um job por vez (concurrency group), registrar `benchmarkIndex` e versão do Chrome. Gate de performance no PR: erro abaixo de 0,85, aviso abaixo de 0,90. As outras três categorias e os orçamentos de bytes são erro direto | Fase 6 | Histórico mostra dispersão <= 5 pontos entre execuções |
| D-LH-16 | Plano B registrado de antemão (seção abaixo); qualquer exceção à meta vira ADR aprovado em checkpoint com o usuário | Fase 4 (ADR) | ADR existe antes de a exceção entrar em `docs/spec/` |
| D-LH-17 | Não publicar `.map` no build web | Fase 7 (`scripts/deploy.sh`) | CI falha se existir `*.map` em `build/web` |
| D-LH-18 | Preset mobile roda só como informação (manual, por release), sem gate | Fase 7 (runbook) | Relatório mobile anexado à release |
| D-LH-19 | Carga inicial sem erro no console: a checagem de sessão responde 200 com `authenticated: false` em vez de 401 | Fase 2 (contrato da API) · Fase 3 (`error-catalog.md`) | errors-in-console passa; teste de contrato do endpoint |

### Orçamento de performance proposto (preset desktop, mediana de 5)

| Item | Orçamento |
|---|---|
| Performance | >= 0,90 (meta) · 0,85 (piso do gate de PR) |
| Acessibilidade e Boas práticas | >= 0,95 |
| SEO | >= 0,90, só em produção ou build local |
| FCP / LCP | <= 0,8 s / <= 1,2 s (ambos vêm do shell) |
| TBT | <= 150 ms (aviso) · <= 250 ms (erro) |
| CLS | <= 0,05 |
| Speed Index | <= 1,8 s |
| Primeiro quadro do Flutter (`cajui:first-frame`) | <= 2,5 s a frio · <= 1,0 s com cache |
| Transferência inicial comprimida | <= 2,5 MB no total · código do app <= 1,0 MB · `index.html` <= 15 KB · fontes <= 200 KB · <= 20 requisições até o primeiro quadro |

Conta que sustenta a meta: com FCP, LCP e CLS no verde pleno já são ~60 pontos; TBT em 150 ms rende ~27 e SI em 1,8 s rende ~7, total ~93. Se o TBT for a 250 ms a nota cai para ~87, então TBT é a métrica que decide. Os números de bytes são proposta: a fonte oficial só informa ~1,5 MB para o CanvasKit. Calibrar na primeira medição real da Fase 6 e só então congelar em `docs/spec/`.

### Como medir de forma reprodutível

1. **Gate de PR**: o job compila `flutter build web --wasm --release` e roda `npx @lhci/cli@0.15.x autorun` com `staticDistDir: build/web`, `isSinglePageApplication: true`, `numberOfRuns: 5`, `settings.preset: desktop` e as quatro categorias. Limite honesto: o servidor estático do LHCI não envia os cabeçalhos de produção (sem COOP/COEP o skwasm roda em uma thread; compressão pode diferir). Serve para pegar regressão, não para declarar a nota.
2. **Medição oficial**: depois do deploy de produção, mesma configuração contra `https://cajui-app.vercel.app`, com o cabeçalho `x-vercel-protection-bypass` em `settings.extraHeaders` (segredo no GitHub Secrets) se a proteção de deployment estiver ligada.
3. **Reprodutibilidade**: versões fixadas, um job por vez, throttling simulado, `benchmarkIndex` registrado; execução com índice muito abaixo da linha de base é descartada e repetida.
4. **Calibração única**: rodar a mesma configuração na máquina de desenvolvimento e anotar a diferença para o runner. Chrome headless sem GPU pode encarecer o WebGL do renderer e inflar TBT e SI.

### Plano B se performance não chegar a 90

1. Antes de desistir: trace do TBT no painel Performance do DevTools (flags `debugProfile*`), esqueleto mais fiel à primeira tela, mais código adiado, cortar pacote pesado, subset de fontes.
2. Mediana entre 80 e 89: ADR de exceção. A meta passa a ser ">= 90 em acessibilidade, boas práticas e SEO; >= 80 em performance; e orçamentos absolutos (primeiro quadro <= 2,5 s a frio e <= 1,0 s com cache)". Justificativa: usuário único, desktop, visitas recorrentes com cache quente, e o Lighthouse só mede carga fria.
3. Abaixo de 80, ou se o usuário tratar 90 como inegociável: refazer o modo consulta em tecnologia de DOM (a própria FAQ do Flutter aponta Jaspr), reaproveitando os pacotes Dart de domínio e dados do monorepo. Custo alto: segunda camada de UI e fim da "base única". Só com aprovação em checkpoint.
4. Não é aceitável maquiar: esconder o app atrás de um clique para medir só o shell, desligar a semântica na medição ou medir página diferente da usada.

## O que não se aplica, e por que

- **Categoria PWA**: removida do Lighthouse desde a 12.0.0. Qualquer checklist que cite "nota de PWA" está desatualizado.
- **Agentic Browsing**: experimental, sem nota 0-100, mira sites lidos por agentes (llms.txt, WebMCP). Painel financeiro privado não quer ser lido por agente nenhum.
- **Preset mobile como gate**: o uso móvel é o app Android nativo; a web é consulta em desktop.
- **Auditorias de SEO de conteúdo** (hreflang, canonical, structured-data, link-text, crawlable-anchors): ficam "não aplicáveis" ou triviais, porque não há links nem conteúdo em HTML; tudo está no canvas.
- **Auditorias de imagem** (image-aspect-ratio, image-size-responsive, image-alt): só alcançam o que estiver no shell; o que o Flutter desenha é invisível para elas.
- **color-contrast automático**: não funciona sobre canvas (ver D-LH-11).
- **PageSpeed Insights e dados de campo (CrUX)**: usuário único não gera dado de campo e o PSI não alcança URL protegida.
- **Stack packs e plugins**: não há stack pack para Flutter.
- **Lighthouse no app Android**: é app nativo, fora do escopo da ferramenta.

## Pontos de atenção

1. **SEO >= 90 contra privacidade.** O natural para um painel financeiro pessoal é `noindex`, mas is-crawlable pesa 4,04 de ~13 pontos: com `noindex` a categoria cai para a faixa de 60 a 70 (conta própria sobre os pesos). A saída adotada (D-LH-13) é não indexar por controle de acesso. Franqueza: SEO aqui é métrica de vaidade; fica porque custa pouco, não porque importa.
2. **A medição oficial contradiz a doc.** O Lighthouse desaconselha CI gratuito e compartilhado para performance. Custo zero não deixa alternativa; por isso mediana de 5, piso de 0,85 no PR e calibração local.
3. **Acessibilidade custa performance.** O Flutter desliga a semântica na web "por desempenho". WCAG 2.2 AA obriga a ligar. Medir com ela desligada seria mentir.
4. **wasm + deferred ainda não é estável** (flag experimental, Flutter 3.50+). No lançamento talvez seja preciso escolher: wasm sem divisão de código ou JS com divisão. Decidir medindo.
5. **Firefox e Safari não executam o build wasm** e caem em JS + CanvasKit, mais pesado. O orçamento vale para Chrome e Edge desktop; os outros são "funciona", sem promessa de nota.
6. **O LCP mede o shell, não o painel.** É legítimo (é o que o usuário vê primeiro), mas a nota não prova que o app abre rápido. Por isso `cajui:first-frame` entra no orçamento.
7. **Parte de boas práticas está fora do nosso controle**: deprecations (peso 5) e inspector-issues dependem do que o engine do Flutter usa. Upgrade de Flutter pode derrubar ou recuperar nota sem mudança nossa.
8. **Página de pontuação desatualizada**: o texto oficial ainda fala em "Lighthouse 10" (a versão vigente é 13.5). Os pesos batem com o config da `main`, mas a fonte de verdade é o código.
9. **"Quatro categorias" deixou de ser o padrão**: o config da 13.x traz uma quinta. Sem `onlyCategories` o relatório muda de forma a cada versão.
10. **Relatório é dado sensível**: inclui captura de tela do app. Por isso artefato privado, nunca armazenamento público temporário.

## Páginas lidas

- https://developer.chrome.com/docs/lighthouse/overview — categorias atuais (sem PWA, com Agentic browsing), formas de rodar; atualizada em 2025-06-02.
- https://developer.chrome.com/docs/lighthouse/performance/performance-scoring — pesos, curva log-normal (p25 = 50, p8 = 90), faixas de cor, curvas separadas por dispositivo.
- https://developer.chrome.com/docs/lighthouse/performance/first-contentful-paint — limiares mobile e desktop; o que conta como conteúdo (canvas não branco conta).
- https://developer.chrome.com/docs/lighthouse/performance/lighthouse-largest-contentful-paint — limiares; desktop mais rígido.
- https://developer.chrome.com/docs/lighthouse/performance/lighthouse-total-blocking-time — limiares; janela FCP-TTI; tarefas acima de 50 ms.
- https://developer.chrome.com/docs/lighthouse/performance/speed-index — limiares mobile e desktop.
- https://web.dev/articles/lcp — candidatos a LCP (canvas fora), heurísticas de exclusão, fim da medição na primeira interação.
- https://web.dev/articles/cls — limiares de CLS.
- https://developer.chrome.com/docs/lighthouse/accessibility/scoring e .../accessibility/ — auditorias binárias ponderadas pelo impacto do axe; manuais não pontuam; atualizadas em 2025-10-22.
- https://developer.chrome.com/docs/lighthouse/best-practices/ — lista de auditorias (HTTPS, HSTS, CSP, clickjacking, Trusted Types, console, deprecations).
- https://developer.chrome.com/docs/lighthouse/seo/ e .../seo/is-crawlable — lista de auditorias; is-crawlable olha meta robots e `X-Robots-Tag`.
- https://developer.chrome.com/docs/lighthouse/agentic-browsing — categoria experimental, Chrome 150+, sem nota 0-100; atualizada em 2026-05-05.
- https://raw.githubusercontent.com/GoogleChrome/lighthouse/main/changelog.md — 13.5.0 em 2026-09-17; 13.0.0 em 2025-10-10 (Node >= 22.19, auditorias trocadas por insights, pesos de a11y ajustados); 12.0.0 removeu PWA.
- https://github.com/GoogleChrome/lighthouse/releases — notas das versões 13.4 e 13.5.
- https://raw.githubusercontent.com/GoogleChrome/lighthouse/main/core/config/default-config.js — categorias e pesos vigentes.
- .../core/config/desktop-config.js, .../core/config/constants.js (`main`) e .../v12.0.0/core/config/constants.js — preset desktop, emulação de tela e valores de `desktopDense4G` e `mobileSlow4G`.
- https://github.com/GoogleChrome/lighthouse/blob/main/docs/throttling.md e .../docs/variability.md — tipos de throttling, `benchmarkIndex`, fontes de variância, hardware mínimo, recomendação contra CI compartilhado.
- https://github.com/GoogleChrome/lighthouse-ci/blob/main/docs/getting-started.md, .../configuration.md e .../troubleshooting.md — `autorun`, workflow de Actions, opções de collect/assert/upload, aviso sobre armazenamento público, `--no-sandbox`.
- https://docs.flutter.dev/platform-integration/web/wasm — build, WasmGC por navegador, fallback, COOP/COEP, pacotes incompatíveis, deferred experimental.
- https://docs.flutter.dev/platform-integration/web/initialization — bootstrap, tokens, API do loader, opções de config, fim do service worker padrão.
- https://docs.flutter.dev/platform-integration/web/faq — navegadores, service worker removido, exemplo de cache (`max-age=0` para js/wasm/json), posição sobre SEO e Jaspr.
- https://docs.flutter.dev/platform-integration/web/building e https://docs.flutter.dev/deployment/web — comandos, conteúdo de `build/web`, minificação e tree shaking por modo, aviso sobre `.map`.
- https://docs.flutter.dev/perf/deferred-components — deferred vale para Android e web; na web gera `*.js` separados.
- https://docs.flutter.dev/perf/web-performance — página de depuração (DevTools, flags de trace); aponta o post do blog para otimização de carga.
- https://docs.flutter.dev/ui/accessibility/web-accessibility — semântica opt-in, `ensureSemantics()`, `SemanticsRole`.
- https://flutter.dev/blog/best-practices-for-optimizing-flutter-web-loading-speed — post oficial de 2024-05-06 com as práticas de carga.

## Não verificado

- **Página "Web renderers" do Flutter**: `docs.flutter.dev/platform-integration/web/renderers` devolveu o conteúdo da visão geral ("Web support for Flutter"); o caminho antigo e o arquivo no repositório do site deram 404. O que está aqui sobre renderers veio das páginas de wasm e de inicialização, do post do blog e do resumo do buscador. Confirmar na Fase 4: tamanho real do CanvasKit e do skwasm, e de onde o CanvasKit é baixado por padrão (CDN do Google ou build local).
- **Página de CLS em developer.chrome.com**: 404; o limiar veio de web.dev.
- **Sem candidato a LCP**: não li o que o Lighthouse faz quando não existe nenhum candidato (suspeita de erro na métrica). O shell da D-LH-03 evita o caso.
- **is-crawlable e `robots.txt`**: a página só cita meta robots e cabeçalho. Não confirmei se `Disallow` no robots.txt também reprova.
- **Viewport injetado pelo engine do Flutter**: suspeita de que leve `user-scalable=no`, o que reprovaria meta-viewport (peso 10). Conferir na primeira medição.
- **Efeito do Chrome headless sem GPU no runner** sobre TBT e SI: hipótese, não medido. Especificação e cota de minutos do runner ficam para a pesquisa de GitHub Actions.
- **Tamanhos reais** de `main.dart.wasm`, `main.dart.js` e do skwasm para este app: só existirão na Fase 6.
