# MDN Web Docs

| Campo | Valor |
|---|---|
| Fonte | https://developer.mozilla.org/pt-BR/ — lida em **en-US** (motivo abaixo) |
| Versão lida | Documentação viva, sem edição numerada. Cada página traz "last modified"; as lidas vão de 2024-09-02 a 2026-09-17 (data por página em "Páginas lidas") |
| Acesso | 2026-09-19 |

**Idioma:** conferi quatro páginas em pt-BR. CSP não cita `'wasm-unsafe-eval'` nem `'strict-dynamic'`; CORS (2025-07-07) traz lista antiga de cabeçalhos seguros; `Intl.NumberFormat` não cobre `roundingMode`, `currencySign` nem `signDisplay`; `share_target` dá 404. A referência do projeto é a versão en-US.

## Por que esta fonte importa para o Cajui

- O modo consulta roda em navegador. CSP, HSTS, CORS, cookies e autoplay são comportamento de navegador, não do Flutter; a MDN descreve esse comportamento e a compatibilidade.
- O build `--wasm` exige exceções de CSP. A MDN define o que `'wasm-unsafe-eval'` libera e o que continua bloqueado.
- A topologia (front em `cajui-app.vercel.app`, API em outro site) decide a sessão web: cookie de terceiros ou token em memória.
- A página de `share_target` confirma, com dados, por que receber comprovante é tarefa do app Android.
- A política de autoplay é a regra que limita os sons de interface na web.

## O que se aplica

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| CSP: diretivas e fallback (`worker-src` → `child-src` → `script-src` → `default-src`) | Cabeçalhos do site estático na Vercel | D-MDN-01, 02 |
| `script-src 'wasm-unsafe-eval'`: sem ele, wasm não carrega sob CSP; `'unsafe-eval'` o sobrepõe e libera `eval()` | Build `--wasm` (skwasm/CanvasKit) | D-MDN-02 |
| "CSP in workers": worker de URL de rede **não** herda a CSP do documento; worker `blob:`/`data:` herda | Workers do motor Flutter | D-MDN-01, 02 |
| CSP por `<meta>` não suporta `frame-ancestors`, `report-uri`, `sandbox` nem Report-Only | `index.html` | D-MDN-01 |
| CSP estrita: nonce exige resposta dinâmica; hash serve para site estático | Hospedagem estática | D-MDN-03 |
| `crossOriginIsolated`, COOP, COEP, CORP (CORP só vale para `no-cors`; `fetch` em modo `cors` não é afetado) | skwasm multi-thread; isolamento | D-MDN-04 |
| HSTS: ignorado via HTTP; `preload` exige `includeSubDomains` e 1 ano, e não faz parte da RFC | Caddy (API) e Vercel | D-MDN-05 |
| `nosniff`: bloqueia `script` sem MIME JS e `style` sem `text/css`; `.wasm` precisa de `application/wasm` | Vercel e API | D-MDN-06 |
| `Referrer-Policy`: padrão `strict-origin-when-cross-origin` | Web e API | D-MDN-07 |
| `Permissions-Policy`: `()` desliga, `self` restringe; status "limited availability/experimental" | Web | D-MDN-08 |
| CORS: `Authorization` e `application/json` sempre geram preflight; curinga proibido com credenciais; `Vary: Origin` | Backend Shelf | D-MDN-09 |
| `Access-Control-Max-Age`: padrão 5 s; teto 2 h (Chromium) e 24 h (Firefox) | Latência do painel | D-MDN-09 |
| Cookies: `Secure`, `HttpOnly`, `SameSite`, prefixo `__Host-`; "site" = domínio registrável (Public Suffix List) + esquema | Sessão web | D-MDN-10, 11 |
| Cookies de terceiros: Safari (ITP) bloqueia, Firefox particiona, Chrome ainda permite | Front e API em sites diferentes | D-MDN-10 |
| CSRF: defesas = token, Fetch Metadata, evitar "simple requests", `SameSite` | API | D-MDN-12 |
| `share_target`: experimental, só PWA instalada, arquivos por POST multipart interceptado em service worker | Receber comprovantes | D-MDN-13 |
| Service Worker (ciclo install/waiting/activate) e Cache (ignora cabeçalhos HTTP, nunca expira sozinho) | Build web | D-MDN-14 |
| `Cache-Control`: `no-store`, `no-cache`, `immutable` | API, `index.html`, assets com hash | D-MDN-14 |
| Autoplay: áudio só com gesto prévio; `AudioContext` nasce `suspended` fora de gesto; `play()` rejeita com `NotAllowedError` | Sons de interface | D-MDN-15 |
| `prefers-reduced-motion` (Windows 11: Acessibilidade > Efeitos visuais) | Shell e modo `reduced` da marca | D-MDN-16 |
| `prefers-color-scheme`, `<meta name="color-scheme">` | Shell e tema | D-MDN-17 |
| WebAuthn: contexto seguro, `rpId` sufixo registrável da origem, desafio do servidor ≥ 16 bytes, `userVerification` | Login na web | D-MDN-18 |
| Web Crypto: aviso explícito de que as primitivas são fáceis de usar errado | Cliente web | D-MDN-19 |
| `Intl.NumberFormat`: saída varia por implementação, usa NBSP, não comparar com constante; arredondamento padrão `halfExpand` | Valores em BRL | D-MDN-20 |
| Manifest: `rel=manifest`, `application/manifest+json`; Chromium exige `name`/`short_name`, ícones 192 e 512, `start_url`, `display`; service worker **não** é requisito de instalação | PWA do modo consulta | D-MDN-21 |

## Decisões

`<API>` = origem HTTPS do backend. "curl" = `curl -sI` no endereço de produção, automatizado no CI/runbook.

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-MDN-01 | CSP entregue por **cabeçalho HTTP** em todos os caminhos (`/(.*)`), nunca por `<meta>`: `frame-ancestors` e Report-Only não funcionam em meta, e workers de rede precisam da própria CSP | Fase 4 ADR de cabeçalhos web; Fase 5 `asvs-checklist.md`; Fase 7 `deploy.sh` | curl em `/`, `/main.dart.js` e no worker; grep: `index.html` sem `http-equiv="Content-Security-Policy"` |
| D-MDN-02 | Núcleo fixo: `default-src 'none'; script-src 'self' 'wasm-unsafe-eval'; connect-src 'self' <API>; img-src 'self'; font-src 'self'; style-src 'self'; worker-src 'self'; manifest-src 'self'; base-uri 'self'; form-action 'none'; frame-ancestors 'none'; object-src 'none'; upgrade-insecure-requests`. Exceções candidatas (`blob:` em `worker-src`/`img-src`, `data:` em `img-src`, `'unsafe-inline'` em `style-src`) só entram com violação registrada em Report-Only. Vetados sempre: `'unsafe-eval'`, `'unsafe-inline'` em `script-src`, curingas, CDN | Fase 5 `threat-model.md` e `asvs-checklist.md` | Build `--wasm` com a mesma política em `Content-Security-Policy-Report-Only`; E2E percorre todas as rotas com zero violação no console; só então vira enforce |
| D-MDN-03 | Nenhum `<script>` inline no shell. Se um for inevitável, hash `sha256-` (site estático não gera nonce). `'strict-dynamic'` fora | Fase 6; ADR de cabeçalhos | CI: grep por `<script` sem `src` falha o build |
| D-MDN-04 | Tudo auto-hospedado (runtime CanvasKit/skwasm, fontes, sons). Enviar `Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp` e `Cross-Origin-Resource-Policy: same-origin` | Fase 4 ADR; Fase 7 | E2E: `window.crossOriginIsolated === true`; aba Network sem host de terceiros além de `<API>` |
| D-MDN-05 | API (Caddy): `Strict-Transport-Security: max-age=63072000; includeSubDomains`, **sem** `preload`. Porta 80 só redireciona/ACME, nunca serve API. Na Vercel, conferir o HSTS que a plataforma já envia | Fase 2 RNF; Fase 7 `runbook.md` | curl nas duas origens; `curl http://<API>/...` nunca devolve corpo de API |
| D-MDN-06 | `X-Content-Type-Options: nosniff` em toda resposta. API sempre `application/json; charset=utf-8`; `.wasm` como `application/wasm`; `.js` como `text/javascript` | Fase 2 RNF; Fase 5 checklist | curl em `main.dart.wasm`, `main.dart.js` e numa rota da API |
| D-MDN-07 | `Referrer-Policy: no-referrer` na web e na API (o app não tem link de saída que precise de referência) | Fase 2 RNF | curl |
| D-MDN-08 | `Permissions-Policy` negando por padrão: `camera=(), microphone=(), geolocation=(), payment=(), usb=(), serial=(), bluetooth=(), display-capture=(), publickey-credentials-get=(self), publickey-credentials-create=(self), autoplay=(self)`. Conta como defesa em profundidade, não como controle único | Fase 5 checklist | curl; item do checklist anota a limitação de suporte |
| D-MDN-09 | CORS no Shelf: lista fechada com a origem exata `https://cajui-app.vercel.app`; `Vary: Origin`; métodos e cabeçalhos explícitos (`Authorization, Content-Type`); `Access-Control-Max-Age: 7200`; **sem** `Access-Control-Allow-Credentials`; `OPTIONS` respondido antes do middleware de autenticação; nunca `*`. Previews da Vercel não falam com a API de produção | Fase 2 RNF; Fase 4 ADR; Fase 6 | Testes de integração: preflight da origem permitida → 204 com cabeçalhos; origem estranha → sem `Access-Control-Allow-Origin`; `OPTIONS` sem token não devolve 401 |
| D-MDN-10 | Sessão web = **token curto só em memória** (variável Dart), enviado em `Authorization: Bearer`, com `withCredentials=false`. Nada em cookie, `localStorage`, `sessionStorage` ou IndexedDB. Recarregar a página = novo login por passkey | Fase 2 (RN/RNF de sessão); Fase 4 ADR (com a alternativa "rewrite na Vercel + cookie `__Host-`" e o motivo da recusa: TLS termina em terceiro e consome cota do Hobby); Fase 5 threat model | E2E pós-login: `document.cookie` vazio e storages vazios; teste de API: nenhuma resposta traz `Set-Cookie` |
| D-MDN-11 | Se um dia existir cookie: `__Host-` + `Secure; HttpOnly; SameSite=Strict; Path=/`, sem `Domain`, `Max-Age` curto, regenerado a cada autenticação | Fase 5 checklist (regra dormente) | Teste que falha se aparecer `Set-Cookie` fora desse formato |
| D-MDN-12 | Sem credencial ambiente não há CSRF clássico; ainda assim a API recusa escrita que não seja `Content-Type: application/json` (nunca "simple request") e rejeita `Origin`/`Sec-Fetch-Site` de outro site quando presentes | Fase 5 threat model | Testes: POST `text/plain` → 415; POST com `Origin` estranho → 403 |
| D-MDN-13 | Web **não** declara `share_target`, `file_handlers` nem `protocol_handlers`. Receber comprovante é exclusivo do Android | Fase 2 (escopo por plataforma); Fase 4 ADR | CI: lint do manifest falha se esses membros existirem |
| D-MDN-14 | Sem service worker próprio na v1. Se o build gerar um, ele guarda só assets estáticos versionados e apaga caches antigos no `activate`. Resposta da API nunca entra no Cache Storage e sai com `Cache-Control: no-store`; `index.html` com `no-cache`; assets com hash com `max-age=31536000, immutable` | Fase 2 RNF; Fase 7 | E2E: `caches.keys()` sem URL da API; curl nos três tipos de recurso |
| D-MDN-15 | Motor de som criado/retomado **dentro** do primeiro evento de gesto. Antes disso o som é descartado (sem fila). `NotAllowedError` tratado em silêncio. Controle liga/desliga e volume no app, independente de movimento reduzido | Fase 3 design system (token de som) e `error-catalog.md`; Fase 6 | E2E: sem interação, `AudioContext.state !== "running"` e console sem aviso de autoplay; após clique, `running` |
| D-MDN-16 | Shell: animação de carregamento só dentro de `@media (prefers-reduced-motion: no-preference)`. App: modo `reduced` da marca liga por preferência do sistema **ou** escolha manual | Fase 3 design system; Fase 2 RNF de acessibilidade | Emulação `prefers-reduced-motion: reduce` + captura de tela; teste de widget |
| D-MDN-17 | Shell com fundo claro/escuro via `prefers-color-scheme`, `<meta name="color-scheme" content="light dark">` e `theme-color` por `media`; app em `ThemeMode.system` | Fase 3 design system | Emulação nos dois esquemas; primeira pintura sem clarão branco |
| D-MDN-18 | Login web por **passkey** (credencial descobrível), `userVerification: "required"`, `rpId` fixo `cajui-app.vercel.app`, desafio de 32 bytes gerado no backend, uso único e expiração curta. Servidor valida desafio, origem, `rpId`, assinatura e contador. Cadastro de passkey só a partir de sessão autenticada no Android. Sem senha na web | Fase 2 RN de autenticação; Fase 4 ADR; Fase 5 threat model | Testes no backend (desafio/origem/`rpId` errados e reuso → recusa); E2E com autenticador virtual do Chrome |
| D-MDN-19 | Web Crypto só para aleatoriedade (`getRandomValues`/`randomUUID`, via `Random.secure()` do Dart). Nenhuma cifra caseira no navegador; criptografia em repouso é do backend | Fase 5 checklist | Revisão/lint: sem `Random()` comum para IDs; grep sem `crypto.subtle` |
| D-MDN-20 | Formatação de dinheiro no Dart (`intl`, `pt_BR`); `Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'})` é a referência de comportamento e só é chamado em página estática. Valor em centavos inteiros; arredondamento nunca delegado ao formatador. Vale-alimentação aparece como BRL + rótulo "VA", sem código de moeda inventado. Teste normaliza U+00A0 | Fase 2 RN de apresentação de valores; Fase 3 design system | Teste unitário: `R$ 1.234,56` e `-R$ 1.234,50` com NBSP normalizado |
| D-MDN-21 | `manifest.webmanifest` servido como `application/manifest+json`, com `id`, `name`, `short_name`, `start_url`, `scope`, `display: standalone`, ícones 192 e 512 (+ maskable), `theme_color`, `background_color`, `description` | Fase 3 (ícones/cores); Fase 6 | DevTools > Application > Manifest sem aviso; curl confere o `Content-Type` |

## O que não se aplica, e por quê

- **Nonce e `'strict-dynamic'`**: exigem resposta gerada por requisição; o front é arquivo estático.
- **`report-to`/`report-uri`**: sem endpoint de relatório na v1 (usuário único; um endpoint aberto vira alvo de spam). Report-Only é usado em desenvolvimento, lendo o console.
- **HSTS `preload`**: exige controle do domínio registrável; `vercel.app` e subdomínio de DNS gratuito não são nossos.
- **`SameSite=None`, `Partitioned` (CHIPS), Storage Access API**: remendos para cookie entre sites; o Cajui não usa cookie.
- **`SubtleCrypto`** (cifrar, assinar, derivar chave no navegador): nada no modo consulta precisa disso.
- **`Intl.NumberFormat` dentro do app Flutter**: o Dart não o chama; vale para página estática e como oráculo de comportamento.
- **`Sec-CH-Prefers-Reduced-Motion`**: client hint para servidor; host estático não negocia conteúdo.
- **Referência de elementos HTML e ARIA da MDN**: o app desenha em canvas; o alcance real está em `html-living-standard.md`.
- **App Android**: nenhum desses cabeçalhos o protege e CORS não se aplica a ele. CORS **não** é controle de acesso; quem protege a API é autenticação + pinning.

## Pontos de atenção

1. **Front e API são sites diferentes.** "Site" é domínio registrável pela Public Suffix List; se `vercel.app` está na lista (conferir em publicsuffix.org, não lido aqui), cookie da API seria de terceiros: bloqueado no Safari, particionado no Firefox. Daí D-MDN-10. Custo de UX: recarregar a aba derruba a sessão — a Fase 3 precisa desenhar esse retorno.
2. **Contrariamos o conselho padrão da MDN** (sessão em cookie `HttpOnly`). Token em memória pode ser lido por XSS enquanto a aba está aberta; o controle compensatório é a CSP. Por isso `'unsafe-inline'`/`'unsafe-eval'` em `script-src` bloqueiam release.
3. **A MDN não diz o que o Flutter exige.** Estilos inline do motor, workers `blob:` e download de CanvasKit/fontes de `gstatic.com` são hipóteses a fechar na pesquisa de Flutter e no teste Report-Only. Sem auto-hospedar, CSP e COEP derrubam o app.
4. **COEP `require-corp`** bloqueia sub-recurso `no-cors` de outra origem sem CORP. A chamada à API (modo `cors`) passa. Multi-thread do skwasm depender de isolamento vem da documentação do Flutter (não lida aqui).
5. **`rpId` preso a `cajui-app.vercel.app`**: mudar de domínio invalida as passkeys; previews têm outra origem e não usam as de produção. Origem e `rpId` aceitos são configuração fixa do backend.
6. **Preflight em toda chamada** (`Authorization` + JSON). Sem `Access-Control-Max-Age` o cache dura 5 s; com 7200 cobre o teto do Chromium.
7. **`Permissions-Policy` é "limited availability"**; não serve sozinho de evidência de ASVS.
8. **Primeiro som da sessão pode se perder**: o gesto que destrava o áudio é o mesmo que dispara o som, e `resume()` é assíncrono. O design deve aceitar isso.
9. **Service worker atrasa correção**: versão nova fica em `waiting` até fechar todas as abas — ruim para deploy de segurança. Mais um motivo para D-MDN-14.
10. **NBSP confirmado localmente** (Node 24.14.1, ICU 78.2): `R$` + U+00A0 + `1.234,56`. Comparar com espaço comum quebra teste — a MDN proíbe comparar com constante.
11. **`share_target`** (dados de compatibilidade do repositório oficial da MDN): Chrome Android 76+, Chrome desktop 89+, Firefox e Safari sem suporte, WebView sem suporte. Somado a "só PWA instalada" e à ausência de ML Kit na web, confirma o app Android nativo.
12. O guia prático da MDN diz que endpoint de API deve **desligar HTTP** em vez de redirecionar. Com 80 aberta para ACME/redirect, a API nunca pode responder conteúdo em HTTP (D-MDN-05).

## Páginas lidas

Todas em `https://developer.mozilla.org/en-US/docs/` (data = "last modified"):

- `Web/HTTP/Reference/Headers/Content-Security-Policy` (2026-03-22): diretivas, fallback, palavras-chave, CSP em workers, múltiplas políticas.
- `…/Content-Security-Policy/script-src` (2026-08-12): `'wasm-unsafe-eval'`, `'unsafe-eval'`, nonce, hash, `'strict-dynamic'`.
- `…/Content-Security-Policy/worker-src` (2025-07-04): alcance e cadeia de fallback.
- `…/Content-Security-Policy/frame-ancestors` (2026-08-27): não suportado em `<meta>`; relação com `X-Frame-Options`.
- `Web/HTTP/Guides/CSP` (2026-03-22): CSP estrita, hash para site estático, Report-Only, limites do `<meta>`.
- `Web/HTTP/Reference/Headers/Strict-Transport-Security` (2026-09-11): sintaxe, primeira visita, `preload`.
- `Web/HTTP/Reference/Headers/X-Content-Type-Options` (2026-03-17): destinos bloqueados.
- `Web/HTTP/Reference/Headers/Referrer-Policy` (2026-09-04): valores e padrão.
- `Web/HTTP/Reference/Headers/Permissions-Policy` (2026-09-14): sintaxe, diretivas, status.
- `Web/HTTP/Guides/CORS` (2026-09-04): simple request, preflight, credenciais, `Vary`.
- `Web/HTTP/Reference/Headers/Access-Control-Max-Age` (2025-11-21): padrão e tetos por navegador.
- `Web/HTTP/Guides/Cookies` (2026-09-17) e `Web/HTTP/Reference/Headers/Set-Cookie` (2026-09-01): atributos, prefixos, definição de "site".
- `Web/Privacy/Guides/Third-party_cookies` (2026-06-15): postura por navegador.
- `Web/Security/Attacks/CSRF` (2026-06-08): defesas.
- `Web/Security/Practical_implementation_guides` (2026-09-17): tabela de prioridade dos controles.
- `Web/HTTP/Reference/Headers/Cache-Control` (2026-09-17): `no-store`, `no-cache`, `immutable`.
- `Web/API/Window/crossOriginIsolated` (2026-08-21), `Web/HTTP/Reference/Headers/Cross-Origin-Embedder-Policy` (2026-09-04), `Web/HTTP/Guides/Cross-Origin_Resource_Policy` (2025-07-10).
- `WebAssembly/Reference/JavaScript_interface/instantiateStreaming_static` (2025-05-21): MIME `application/wasm`, remissão à CSP.
- `Web/Progressive_web_apps/Manifest/Reference/share_target` (2026-08-27) e `…/How_to/Share_data_between_apps` (2025-06-30): requisitos e fluxo de arquivos.
- `raw.githubusercontent.com/mdn/browser-compat-data/main/manifests/webapp/share_target.json`: suporte por navegador.
- `Web/API/Service_Worker_API/Using_Service_Workers` (2026-05-29) e `Web/API/Cache` (2026-09-11).
- `Web/Media/Guides/Autoplay` (2026-09-10) e `Web/API/Web_Audio_API/Best_practices` (2026-08-27).
- `Web/CSS/Reference/At-rules/@media/prefers-reduced-motion` (2026-06-10) e `…/prefers-color-scheme` (2026-08-04).
- `Web/API/Web_Authentication_API` (2026-02-19), `Web/API/Web_Crypto_API` (2024-09-02), `Web/API/Web_Storage_API` (2025-02-22; sem orientação de segurança sobre tokens).
- `Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat/NumberFormat` (2026-08-21) e `…/NumberFormat/format` (2026-07-20).
- `Web/Progressive_web_apps/Manifest` (2025-08-08) e `…/Guides/Making_PWAs_installable` (2026-09-07).
- pt-BR, só para checar defasagem: `pt-BR/docs/Web/HTTP/Reference/Headers/Content-Security-Policy` (2026-04-10), `pt-BR/docs/Web/HTTP/Guides/CORS` (2025-07-07), `pt-BR/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat`.

## Não verificado

- `…/Content-Security-Policy/Sources` devolveu 404; a sintaxe de fontes foi lida na página principal da CSP, que **não** trata `blob:`/`data:` como fonte (só no trecho sobre workers).
- Tabelas de compatibilidade são montadas por JavaScript e não vieram no HTML obtido. Só `share_target` foi conferido pelos dados brutos. Ficaram sem conferir: suporte por navegador a `Permissions-Policy`, a COEP `credentialless` e a `navigator.getAutoplayPolicy()`.
- Presença de `vercel.app` na Public Suffix List (atenção 1) e o HSTS que a Vercel envia por padrão.
- Exigências reais do Flutter Web para CSP/COEP (atenção 3 e 4): fora do escopo da MDN.
- "Related origin requests" do WebAuthn: o trecho lido não foi claro; não usar como saída para troca de domínio sem reler.
- `pt-BR/…/Manifest/Reference/share_target`: 404 (não existe tradução).
