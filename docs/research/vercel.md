# Vercel

| Campo | Valor |
|---|---|
| Fonte | https://vercel.com/docs · guias em vercel.com/kb · changelog · Termos de Serviço em vercel.com/legal/terms |
| Versão lida | Documentação viva. Páginas lidas com `last_updated` entre 2026-03-05 e 2026-09-17 (Hobby 2026-09-14, Limits 2026-09-16, vercel.json 2026-08-14, Rewrites 2026-08-11). Termos de Serviço de 2026-06-01 |
| Acesso | 2026-09-19 |

## Por que esta fonte importa para o Cajui

A Vercel hospeda o modo consulta web a custo zero, mas o Flutter não existe na imagem de build dela, então o caminho de publicação precisa ser decidido. Num site estático, o `vercel.json` é o único controle de servidor que temos: cabeçalhos de segurança, cache, COOP/COEP do wasm e fallback de SPA. A decisão entre rewrite same-origin e CORS define o modelo de sessão da web, a CSP e o que entra no threat model. E os termos do plano Hobby dizem até onde dá para confiar nessa hospedagem.

## O que se aplica

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| Hobby é gratuito e restrito a "personal or non-commercial use". Comercial = ganho financeiro de qualquer envolvido: pagamento, anúncio, afiliado, ser pago para fazer o site. Doação não conta | Cajui é pessoal, sem anúncio nem cobrança: enquadra | D-VERCEL-01 |
| Termos: a Vercel pode desativar ou remover projeto Hobby "with or without notice at our sole discretion" | A hospedagem web não pode ser ponto único de falha | D-VERCEL-02 |
| Cotas Hobby por mês: 100 GB de Fast Data Transfer, 1 milhão de Edge Requests, 10 GB de Fast Origin Transfer. Limites: 100 deploys/dia, 1 build por vez, build <= 45 min (2 vCPU, 8 GB), upload pela CLI <= 100 MB e <= 15.000 arquivos, 2.048 rotas por deploy, log de runtime por 1 h. Estourou: recurso pausado por até 30 dias | Usuário único: a ~2,5 MB por carga fria, 100 GB são ~40 mil cargas | D-VERCEL-03 |
| Imagem de build: Amazon Linux 2023 com Node, Python, Ruby e Go. **Sem Flutter nem Dart.** Dá para instalar pacote via `installCommand` | Instalar o Flutter a cada build gasta minutos e foge do binário que o CI já validou | D-VERCEL-04 |
| Guia oficial de GitHub Actions: `vercel pull` -> `vercel build --prod` -> `vercel deploy --prebuilt --prod`; segredos `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`; **sem OIDC** para autenticar o deploy; `git.deploymentEnabled: false` evita deploy duplicado; `--archive=tgz`; o stdout é a URL do deployment | Pipeline de publicação | D-VERCEL-04, D-VERCEL-05 |
| Hobby não conecta repositório que pertença a uma organização do GitHub | Repositório pessoal privado funcionaria; mesmo assim não vamos conectar | D-VERCEL-05 |
| `vercel.json`: `$schema`, `framework: null` (= Other), `buildCommand`, `installCommand` (string vazia pula), `outputDirectory`, `cleanUrls`, `trailingSlash`, `headers`, `redirects`, `rewrites`, `routes` (hoje combinável com os demais). `public` foi removido e **quebra o deploy** | Arquivo central da publicação | D-VERCEL-06 |
| Rewrites: o sistema de arquivos tem precedência; exemplo oficial de SPA `/(.*)` -> `/index.html`; lookahead negativo é suportado; `/.well-known` é reservado | URL por caminho no Flutter Web | D-VERCEL-07 |
| TLS 1.2 e 1.3; HTTP -> HTTPS com 308 e sem opção de desligar; HSTS padrão em `*.vercel.app`: `max-age=63072000; includeSubDomains; preload` | Nada a configurar em `cajui-app.vercel.app` | D-VERCEL-08 |
| CSP: começar em Report-Only, evitar `unsafe-inline` e `unsafe-eval`, usar nonce ou hash. Nonce por requisição exige Routing Middleware | Site estático: não há nonce dinâmico | D-VERCEL-09 |
| Cache de estático: padrão `public, max-age=0, must-revalidate`; o CDN guarda o arquivo pela vida do deployment. `max-age=31536000, immutable` é recomendado **só para arquivo com hash no nome** | A saída do Flutter usa nomes fixos | D-VERCEL-11 |
| Compressão gzip e brotli automática; a lista inclui `application/wasm`, javascript, json, otf, ttf e svg | O wasm sai comprimido sem configuração | D-VERCEL-11 |
| Rewrite para origem externa é uso documentado ("Proxy API requests"). Timeout de 120 s até o primeiro byte; depois o stream continua se houver dado a cada <= 120 s (changelog de 2025-05-08); erro `ROUTER_EXTERNAL_TARGET_ERROR`. Projeto criado a partir de 2026-04-06 **faz cache por padrão** respeitando o `Cache-Control` do upstream; opt-out com `x-vercel-enable-rewrite-caching: 0` | `/api/*` -> backend na Oracle | D-VERCEL-12, 14, 15 |
| `routes[].transforms` com `env`: grava cabeçalho na requisição ao upstream com valor de variável de ambiente resolvida na borda; `dest` aceita `${VAR}` | Segredo de borda fora do bundle e fora do repositório | D-VERCEL-13 |
| O CDN só guarda resposta de GET/HEAD, sem `Authorization` na requisição, sem `set-cookie`, sem `private`/`no-store`/`no-cache`, até 10 MB | Defesa contra cache indevido da API | D-VERCEL-14 |
| Deployment Protection no Hobby: Vercel Authentication incluída, inclusive no escopo "All Deployments"; Standard protege tudo menos o domínio de produção; senha e IP confiável são pagos. Bypass para automação (`x-vercel-protection-bypass`) incluído; o cookie de acesso vale por URL; 1 usuário externo por conta | Barreira antes do login do app | D-VERCEL-17 |
| Preview recebe `X-Robots-Tag: noindex` automaticamente; produção não | SEO do Lighthouse só em produção | D-VERCEL-17 |
| Variáveis de ambiente: cifradas em repouso, por ambiente (Production, Preview, Development), 64 KB, só valem em deployment novo, visíveis a quem acessa o projeto. Com `--prebuilt` as variáveis de sistema não existem no build | No Flutter Web, tudo que entra por `--dart-define` vai para o bundle | D-VERCEL-18, D-VERCEL-19 |

### Esboço de `vercel.json`

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": null,
  "installCommand": "",
  "buildCommand": "test -f build/web/index.html",
  "outputDirectory": "build/web",
  "git": { "deploymentEnabled": false },
  "trailingSlash": false,
  "routes": [
    { "src": "/api/(.*)", "dest": "${CAJUI_API_ORIGIN}/$1", "env": ["CAJUI_API_ORIGIN"],
      "transforms": [{ "type": "request.headers", "op": "set", "target": { "key": "x-cajui-edge-key" },
                       "args": "$CAJUI_EDGE_KEY", "env": ["CAJUI_EDGE_KEY"] }] }
  ],
  "rewrites": [
    { "source": "/((?!api/|assets/|canvaskit/|.*\\.[a-z0-9]+$).*)", "destination": "/index.html" }
  ],
  "headers": [
    { "source": "/(.*)", "headers": [
      { "key": "Content-Security-Policy-Report-Only", "value": "default-src 'none'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self'; connect-src 'self'; worker-src 'self' blob:; manifest-src 'self'; base-uri 'self'; form-action 'none'; frame-ancestors 'none'; object-src 'none'" },
      { "key": "X-Content-Type-Options", "value": "nosniff" },
      { "key": "X-Frame-Options", "value": "DENY" },
      { "key": "Referrer-Policy", "value": "no-referrer" },
      { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=(), payment=(), usb=(), bluetooth=()" },
      { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
      { "key": "Cross-Origin-Embedder-Policy", "value": "credentialless" },
      { "key": "Cross-Origin-Resource-Policy", "value": "same-origin" } ] },
    { "source": "/api/(.*)", "headers": [
      { "key": "x-vercel-enable-rewrite-caching", "value": "0" },
      { "key": "Cache-Control", "value": "no-store" } ] },
    { "source": "/assets/(.*)\\.(otf|ttf|woff2|png|webp|avif|svg)", "headers": [
      { "key": "Cache-Control", "value": "public, max-age=3600" } ] }
  ]
}
```

Comentário, bloco a bloco:

1. **Build.** `framework: null` escolhe o preset "Other" e `installCommand` vazio pula a instalação. O Flutter é compilado uma única vez no GitHub Actions, antes do `vercel build`; o `buildCommand` só confere que `build/web` existe, para o mesmo binário passar por teste, Lighthouse CI e deploy. `git.deploymentEnabled: false` é cinto de segurança caso alguém conecte o repositório.
2. **`routes` de `/api`.** Faz o proxy para o backend na Oracle. A origem e a chave de borda vêm de variáveis de ambiente do projeto (só em Production), resolvidas na borda: não entram no bundle nem no repositório. O backend só aceita sessão web se `x-cajui-edge-key` conferir.
3. **Fallback de SPA.** Só caminhos sem extensão e fora de `api/`, `assets/` e `canvaskit/` caem em `/index.html`. Arquivo inexistente devolve 404 de verdade, em vez de HTML com status 200.
4. **Cabeçalhos globais.** A CSP entra em Report-Only e só passa a valer depois de validada em preview. `wasm-unsafe-eval` é o mínimo para compilar wasm; `unsafe-inline` fica só em `style-src` e só se o Report-Only provar que o engine precisa. HSTS não aparece porque o padrão de `*.vercel.app` já é o máximo. `X-XSS-Protection`, presente no exemplo da doc, fica de fora: é cabeçalho legado. COOP + COEP liberam o skwasm multi-thread e obrigam a hospedar tudo na própria origem.
5. **Cabeçalhos de `/api`.** Desligam o cache de rewrite externo (ligado por padrão em projeto novo) e repetem `no-store`. O backend também envia `no-store`: são três camadas de propósito.
6. **Cache.** Tudo fica no padrão `max-age=0, must-revalidate`, porque os nomes do Flutter não têm hash. Só fontes e imagens de `assets/` ganham 1 hora, como no exemplo da FAQ do Flutter. Nada de `immutable`.
7. **Ausências de propósito**: `cleanUrls` (só existe `index.html`), `redirects` (não há URL legada), `public` (removido), funções, middleware e otimização de imagem.

### Rewrite same-origin ou CORS restrito?

| Critério | Rewrite `/api/*` (same-origin) | CORS restrito |
|---|---|---|
| Sessão web | Cookie `__Host-`, `HttpOnly`, `Secure`, `SameSite=Strict`: o token fica fora do alcance de JavaScript | Origens em sites diferentes: cookie exigiria `SameSite=None` e esbarra no bloqueio de cookie de terceiro; o token acaba em memória de JS |
| CSP e COEP | `connect-src 'self'` | Precisa listar a origem da API |
| Preflight | Nenhum | Um `OPTIONS` extra por requisição com JSON ou `Authorization` |
| Backend | CORS fechado (nenhum `Access-Control-Allow-Origin`) | Allowlist com exatamente `https://cajui-app.vercel.app` |
| Latência | Um salto a mais (navegador -> borda -> Oracle) | Direto |
| Privacidade | O TLS termina na Vercel: o tráfego da API passa em claro pela borda de um terceiro | A Vercel não vê a API |
| Riscos próprios | Cache por padrão em projeto novo; timeout de 120 s; o backend vê o IP da Vercel; log de 1 h | Configuração de CORS errada é falha clássica; token exposto a XSS |

**Recomendação: rewrite same-origin para a web, com o CORS do backend fechado.** O ganho decisivo para o ASVS nível 2 é a sessão em cookie `HttpOnly` same-site e a CSP com `connect-src 'self'`. O custo de privacidade é marginal: a Vercel já serve o código que lê os dados, então já está na base de confiança do modo web, e o threat model deve dizer isso com todas as letras. O app Android continua falando direto com a Oracle, com certificate pinning. CORS restrito fica documentado como plano de contingência, acionado se o spike da Fase 6 reprovar latência ou streaming pelo proxy.

## Decisões

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-VERCEL-01 | Permanecer no enquadramento Hobby: sem anúncio, cobrança, afiliado ou pagamento pelo site. Monetizar exige trocar de plano ou de hospedagem | Fase 2 (RNF de custo zero) | Item no checklist de release do runbook |
| D-VERCEL-02 | Plano de saída: o mesmo `build/web` pode ser servido pelo Caddy na Oracle, com os mesmos cabeçalhos. O artefato do build fica guardado no Actions | Fase 7 (`runbook.md`: "Vercel pausada ou removida") | Simulado uma vez na Fase 7: build servido pelo Caddy em host temporário |
| D-VERCEL-03 | Conferir o painel de uso mensalmente; teto interno de 5 GB/mês; investigar acima de 10 % de qualquer cota | Fase 7 (runbook) | Checklist mensal assinado |
| D-VERCEL-04 | Build fora da Vercel: o Actions compila com Flutter fixado, testa, roda LHCI e publica com `vercel pull`, `vercel build --prod` e `vercel deploy --prebuilt --prod --archive=tgz` | Fase 4 (ADR de publicação) · Fase 7 (`scripts/deploy.sh` e workflow) | O deployment aparece como origem CLI e o log da Vercel não mostra passo de build |
| D-VERCEL-05 | Projeto **sem** integração Git (a Vercel não recebe acesso ao repositório privado). Token de deploy em GitHub Environment `production`, com escopo mínimo e rotação a cada 90 dias, já que não há OIDC | Fase 5 (threat model) · Fase 7 (runbook) | As configurações do projeto não mostram repositório; data da rotação registrada |
| D-VERCEL-06 | `vercel.json` na raiz do pacote web, versionado e validado contra o `$schema` no CI | Fase 6 | Job de CI falha com JSON inválido |
| D-VERCEL-07 | Estratégia de URL por caminho, com fallback de SPA restrito a caminhos sem extensão | Fase 4 (ADR de navegação web) | `curl` em link profundo devolve 200 com o shell; `curl /assets/nao-existe.png` devolve 404 |
| D-VERCEL-08 | HSTS: usar o padrão de `*.vercel.app`, sem sobrescrever. Se um dia houver domínio próprio, declarar `max-age=63072000; includeSubDomains; preload` | Fase 5 (`asvs-checklist.md`) | `curl -I` mostra o cabeçalho |
| D-VERCEL-09 | CSP estática sem script inline (bootstrap externo, ver D-LH-06). Report-Only em preview; passa a valer antes do lançamento. Toda exceção (`unsafe-inline` em estilo) é justificada por escrito | Fase 5 (checklist e threat model) | Console sem violação; o cabeçalho final não é `-Report-Only` |
| D-VERCEL-10 | Demais cabeçalhos: nosniff, `X-Frame-Options: DENY` junto de `frame-ancestors 'none'`, `Referrer-Policy: no-referrer`, Permissions-Policy negando tudo, COOP `same-origin`, COEP `credentialless`, CORP `same-origin`. CanvasKit/skwasm e fontes servidos da própria origem (`canvasKitBaseUrl` local; Fraunces e Geist embutidas) | Fase 5 (checklist) · Fase 7 (`vercel.json`) | Script pós-deploy confere cada cabeçalho; aba de rede sem requisição a terceiros |
| D-VERCEL-11 | Cache: nada de `immutable` em nome sem hash. HTML, JS, wasm e JSON em `max-age=0, must-revalidate`; fontes e imagens de `assets/` em 1 h; engine nunca com cache longo | Fase 4 (ADR) · Fase 7 | Depois de um deploy, recarregar sem forçar traz a versão nova (`version.json`) |
| D-VERCEL-12 | Web usa `/api/*` same-origin via rewrite; Android usa a origem da Oracle direto. CORS do backend fechado | Fase 4 (ADR) · Fase 5 (threat model: Vercel como processador confiável do modo web) | Bundle web sem a URL da Oracle; `OPTIONS` de origem estranha não recebe cabeçalho CORS |
| D-VERCEL-13 | `CAJUI_API_ORIGIN` e `CAJUI_EDGE_KEY` como variáveis de ambiente só de Production, injetadas por `routes.transforms`. Middleware do Shelf exige a chave para sessão web, com comparação em tempo constante e rotação | Fase 4 (ADR) · Fase 5 · Fase 6 | Requisição direta à Oracle com cookie web e sem a chave devolve 403 |
| D-VERCEL-14 | Toda resposta da API sai com `Cache-Control: no-store`; `/api` com `x-vercel-enable-rewrite-caching: 0` | Fase 2 (RNF de API) · Fase 6 | Teste de contrato: `x-vercel-cache` nunca é `HIT` em `/api` |
| D-VERCEL-15 | Tempo: chamada à DeepSeek com timeout próprio <= 90 s; chat por SSE com comentário de heartbeat a cada 25 s; sem WebSocket pelo proxy. Spike na Fase 6 confirma que o stream não é retido; se for, cai para respostas em blocos | Fase 3 (`error-catalog.md`: 504 e `ROUTER_EXTERNAL_TARGET_ERROR`) · Fase 6 | Teste ponta a ponta de streaming pela URL de produção |
| D-VERCEL-16 | Backend confia em `x-forwarded-for` só quando a chave de borda é válida; fora disso usa o IP do socket. Limite de taxa da web por sessão, não por IP | Fase 5 (threat model) · Fase 7 (Caddy) | Teste: `x-forwarded-for` forjado sem chave é ignorado |
| D-VERCEL-17 | Proposta: Vercel Authentication no escopo "All Deployments". A web só abre para a conta Vercel do dono, antes do login do app. LHCI e testes usam o segredo de bypass. SEO só se mede em produção. **Confirmar com o usuário**: é um redirect a mais na experiência | Fase 4 (ADR) · Fase 5 · Fase 7 (runbook: perda da conta Vercel) | `curl` anônimo na produção devolve o login da Vercel; com o cabeçalho de bypass devolve 200 |
| D-VERCEL-18 | Preview nunca fala com dado real: no ambiente Preview, `CAJUI_API_ORIGIN` aponta para mock ou fica sem valor | Fase 5 (threat model) · Fase 7 | `/api/health` num preview não alcança a Oracle |
| D-VERCEL-19 | Nenhum segredo no bundle web: o build recebe só configuração pública (base `/api`); proibido `--dart-define` com segredo; variável da Vercel é usada só no roteamento de borda | Fase 5 (checklist) · Fase 6 | Varredura de segredos sobre `build/web` no CI |
| D-VERCEL-20 | Não enviar `.map` (se um dia for preciso, ligar Protected Source Maps, incluído no Hobby) | Fase 7 (`deploy.sh`) | CI falha se houver `*.map` em `build/web` |

## O que não se aplica, e por que

- **Vercel Functions, Routing Middleware, ISR, Cron, Blob, Global Config**: o backend é Dart na Oracle; usar compute da Vercel criaria segundo backend e consumiria cota.
- **Image Optimization**: o app desenha em canvas e não usa `<img>` servido pela Vercel.
- **Web Analytics e Speed Insights**: injetam script de terceiro num painel financeiro de usuário único; a CSP proposta nem permitiria.
- **`cleanUrls`**: só existe um `index.html`.
- **Password Protection, Trusted IPs, Passport**: pagos ou Enterprise; violam o custo zero.
- **Integração Git, comentários e previews por PR**: descartados por menor privilégio (D-VERCEL-05). A URL de preview sai do stdout da CLI se for preciso comentar no PR.
- **Build Output API escrita à mão**: o `vercel build` já gera `.vercel/output` a partir do `vercel.json`.
- **Domínio próprio e HSTS customizado**: domínio custa dinheiro; `cajui-app.vercel.app` herda HSTS com preload.
- **Flat Rate CDN, Spend Management, Log Drains**: recursos do plano Pro.

## Pontos de atenção

1. **Premissa errada no plano: "arquivos com hash do Flutter".** A saída do `flutter build web` usa nomes fixos (`main.dart.js`, `main.dart.wasm`, `flutter_bootstrap.js`, `canvaskit/`), e a própria FAQ do Flutter exemplifica `max-age=0` para js, wasm e json. `immutable` prenderia o usuário em versão velha ou misturaria engine novo com app velho. A revalidação custa uma ida e volta por arquivo; a nota do Lighthouse não sofre (auditoria de peso 0).
2. **Cache por padrão em rewrite externo.** O projeto será criado depois de 2026-04-06, então a borda respeita o `Cache-Control` do upstream. Se a sessão web for por cookie, a proteção implícita "requisição com `Authorization` não é cacheada" some. Um `no-store` esquecido poderia deixar dado financeiro no CDN; por isso as três camadas da D-VERCEL-14 e o teste de contrato.
3. **Remoção sem aviso.** Os termos permitem derrubar projeto Hobby a critério da Vercel. Sem a D-VERCEL-02 o modo consulta depende de boa vontade.
4. **TLS termina na Vercel.** Com o rewrite, o dado financeiro passa em claro pela borda de um terceiro. É aceitável porque esse terceiro já entrega o código do app, mas precisa constar no threat model, não ficar implícito.
5. **Token de deploy de longa duração.** Sem OIDC, o `VERCEL_TOKEN` no GitHub publica código que lê dados financeiros. Compromete-se o GitHub, compromete-se a web. Escopo mínimo, Environment protegido, rotação.
6. **Preview contra produção.** Sem a D-VERCEL-18, qualquer build de branch falaria com o backend real.
7. **Streaming.** A doc garante stream longo se houver bytes a cada 120 s, mas não fala de retenção de resposta nem de WebSocket em rewrite externo. SSE só entra depois do spike.
8. **Uso justo.** A página de rewrites descreve proxy de API como uso previsto, mas as listas "Examples of fair use" e "Never fair use" vieram vazias na leitura. O tráfego de um usuário é irrisório; risco residual baixo, não nulo.
9. **COEP e terceiros.** `credentialless` muda o carregamento de recurso de outra origem. O Flutter busca fonte de fallback em `fonts.gstatic.com` por padrão (`fontFallbackBaseUrl`). Com fontes embutidas o português fica coberto; emoji ou glifo raro pode virar quadradinho ou violação de CSP. Testar.
10. **`routes` junto de `rewrites`.** A doc diz que convivem, mas não detalha a ordem de avaliação. Validar em preview que `/api` vence o fallback de SPA.
11. **Vercel Authentication como UX.** Dá defesa em profundidade de graça, mas põe o login da Vercel antes do login do Cajui e amarra o acesso web à conta Vercel (risco de ficar trancado do lado de fora). O projeto exige UX de alto padrão: decisão do usuário, por isso está marcada como proposta.
12. **Log de runtime de 1 h no Hobby.** Depurar o proxy tem janela curta; o backend precisa logar o suficiente, sem PII.
13. **`*.vercel.app` é domínio compartilhado.** Cookie sempre com prefixo `__Host-`, nunca com atributo `Domain`. O nome `cajui-app` precisa estar livre no momento da criação.

## Páginas lidas

- https://vercel.com/docs/plans/hobby — cotas incluídas, pausa de 30 dias, comparação com o Pro, proteção de deployment incluída.
- https://vercel.com/docs/limits — limites gerais, timeout de proxy de 120 s, upload pela CLI, rotas por deploy, logs, restrição de repositório de organização.
- https://vercel.com/docs/limits/fair-use-guidelines (e a variante `.md`) — tabela de uso típico e definição de uso comercial; listas de exemplos vieram vazias.
- https://vercel.com/legal/terms — cláusula do Hobby (uso pessoal ou não comercial; remoção a critério da Vercel); atualizado em 2026-06-01.
- https://vercel.com/docs/project-configuration/vercel-json — propriedades, exemplos de `headers` e `rewrites` (SPA e origem externa), precedência do sistema de arquivos, `routes` com `transforms` e `env`, `trailingSlash`, remoção de `public`.
- https://vercel.com/docs/rewrites (canônico: /docs/routing/rewrites) — rewrites externos, cache por padrão a partir de 2026-04-06, opt-out, observabilidade, `/.well-known` reservado.
- https://vercel.com/changelog/cdn-origin-timeout-increased-to-two-minutes — semântica do timeout: primeiro byte em 120 s e stream enquanto houver dados.
- https://vercel.com/kb/guide/vercel-reverse-proxy-rewrites-external — confirma proxy reverso como uso suportado; não cobre cabeçalhos encaminhados nem streaming.
- https://vercel.com/docs/cli/deploy e https://vercel.com/docs/cli/build — `--prebuilt`, `--prod`, `--archive`, stdout como URL, limitação das variáveis de sistema, `.vercel/output`.
- https://vercel.com/kb/guide/how-can-i-use-github-actions-with-vercel — workflows de preview e produção, segredos, `git.deploymentEnabled`, ausência de OIDC.
- https://vercel.com/docs/build-output-api e https://vercel.com/docs/builds/build-image — estrutura `.vercel/output`; imagem Amazon Linux 2023 e runtimes (sem Flutter).
- https://vercel.com/docs/headers/security-headers (canônico: /docs/cdn-security/security-headers) — orientação de CSP.
- https://vercel.com/docs/cdn-security/encryption — TLS, redirect 308, HSTS padrão de `*.vercel.app` e de domínio próprio.
- https://vercel.com/docs/caching/cache-control-headers e https://vercel.com/docs/caching/cdn-cache — padrão de cache, tabela de recomendações, prioridade dos cabeçalhos de CDN, critérios de resposta cacheável.
- https://vercel.com/docs/compression — gzip e brotli; lista de tipos MIME (inclui wasm).
- https://vercel.com/docs/manage-cdn-usage — definições de Fast Data Transfer, Fast Origin Transfer e Edge Requests.
- https://vercel.com/docs/deployment-protection, .../usage-and-pricing, .../vercel-authentication e .../protection-bypass-automation — métodos, escopos, disponibilidade por plano, cookie por URL, cabeçalho de bypass.
- https://vercel.com/docs/environment-variables — ambientes, cifragem em repouso, limite de 64 KB, vigência só em deployment novo.
- https://vercel.com/kb/guide/are-vercel-preview-deployment-indexed-by-search-engines — `noindex` automático em preview e em produção antiga.

## Não verificado

- **Listas "Examples of fair use" e "Never fair use"**: vazias nas duas leituras. Não confirmei se proxy consta como uso proibido.
- **Rewrite externo e Fast Origin Transfer**: a página define o recurso como tráfego entre CDN e Functions e não cita rewrite externo. O impacto na cota de 10 GB fica a confirmar no painel de uso.
- **Cabeçalhos encaminhados ao upstream** (`x-forwarded-for`, `Host`), retenção de resposta em SSE e WebSocket em rewrite externo: nenhuma página lida cobre. Dependem do spike da D-VERCEL-15.
- **Ordem de avaliação entre `routes` e `rewrites`** no mesmo arquivo.
- **`buildCommand` vazio**: a doc só garante que string vazia pula o `installCommand`; por isso o esboço usa um comando de checagem.
- **Requisitos de CSP do Flutter Web** (`wasm-unsafe-eval`, estilos inline, workers por blob): as páginas do Flutter lidas não citam CSP. A política do esboço é rascunho a validar em Report-Only.
- **Vercel Authentication e cabeçalho `noindex`** em produção protegida: não documentado nas páginas lidas.
- **Especificação do runner e cota de minutos do GitHub Actions**: fora desta fonte.
