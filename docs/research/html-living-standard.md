# HTML Living Standard (WHATWG)

| Campo | Valor |
|---|---|
| Fonte | https://html.spec.whatwg.org/multipage/ |
| Versão lida | Living Standard, "Last Updated 17 September 2026" (sem numeração; citar sempre seção + data) |
| Acesso | 2026-09-19 |

## Por que esta fonte importa para o Cajui

- O único HTML que o projeto escreve é o `web/index.html` de shell e as páginas estáticas (prancha da marca, página de erro/fallback). É pouco, mas é o que o navegador, o Lighthouse e o leitor de tela enxergam **antes** do primeiro quadro do Flutter — e o que sobra na tela quando o wasm não sobe.
- A especificação define como `async`/`defer`/`module` buscam e executam. Isso decide se o bootstrap do Flutter bloqueia ou não o parser.
- O modelo de ativação do usuário (sticky/transient) é a regra formal por trás do bloqueio de áudio e do gesto exigido no login.
- A árvore de semântica do Flutter vira elementos DOM com ARIA; o modelo de foco do HTML vale para eles, e o shell não pode atrapalhar.

## O que se aplica

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| §4.1.1 `html` + §3.2.6.2 `lang`: autores são incentivados a declarar `lang` na raiz; valor BCP 47 | Shell e páginas estáticas | D-HTML-01 |
| §4.2.5.4 codificação: declaração inteira nos primeiros 1024 bytes; só `utf-8`; uma por documento | Shell | D-HTML-02 |
| §4.2.2 `title`: no máximo um; deve identificar o documento fora de contexto (histórico, favoritos) | Shell e título por rota | D-HTML-03 |
| §4.2.5.1 nomes padrão de `meta`: `application-name`, `description` (uma só), `theme-color` (aceita `media`), `color-scheme`, `referrer` | Shell | D-HTML-04, 06 |
| `viewport` **não** é definido no HTML Standard (busca no texto de §4.2.5 não retorna nada) | Shell | D-HTML-05 |
| §4.2.5.3 pragma CSP: o `meta` só vale dentro de `head`; `report-uri`, `frame-ancestors` e `sandbox` são removidos; recurso já buscado antes da inserção escapa | Entrega da CSP | D-HTML-09 |
| §4.12.1 `script`: clássico sem atributo bloqueia o parser; `async` busca em paralelo e executa assim que chega, sem ordem; `defer` executa após o parsing, em ordem; módulo é "defer" por natureza e `defer` não tem efeito nele | Bootstrap do Flutter | D-HTML-07 |
| §4.6.7 `preload`: `as` obrigatório; destinos válidos `fetch`, `font`, `image`, `script`, `style`, `track`; a chave do preload inclui URL, destino, modo e modo de credenciais | Pré-carga do wasm/JS | D-HTML-08 |
| §4.6.7 `modulepreload`: põe o módulo no module map; buscar dependências é opcional | Runtime em módulo ES | D-HTML-08 |
| §4.6.7 `preconnect` (dica, não atrasa `load`); §2.5.9 `fetchpriority` = `high`/`low`/`auto`, também dica | Conexão com a API | D-HTML-08 |
| §4.12.2 `noscript`: em `head` só `link`/`style`/`meta`; a própria especificação recomenda evitá-lo, porque não cobre "script ligado, mas falhou" | Falha de carregamento | D-HTML-10 |
| §4.4.14 `main`: no máximo um sem `hidden`; ancestrais só `html`, `body`, `div`, `form` sem nome, custom element | Shell e páginas estáticas | D-HTML-11 |
| §4.3 seções e títulos: pelo menos um título de nível 1; o nível seguinte não pula mais de 1; `nav` só para blocos principais de navegação | Páginas estáticas | D-HTML-11 |
| §4.11.4 `dialog`: `showModal()` põe no top layer e torna o resto do documento inerte; `closedby`; `tabindex` proibido em `dialog` | Páginas estáticas | D-HTML-12 |
| §6.3 `inert`: sem foco, sem hit-test, fora da árvore de acessibilidade; só usar se o conteúdo também estiver visualmente obscurecido | Sobreposição de erro no shell | D-HTML-12 |
| §4.10.18.7 autofill (`username`, `one-time-code`, `webauthn`, `transaction-amount`, `off` para dado sensível/não reutilizável) e §6.8.6 `inputmode` (`numeric`, `decimal`…) | Campos de texto gerados pelo Flutter | D-HTML-13 |
| §6.6 foco: `tabindex` diferente de 0/−1 "é complicado de acertar"; um `autofocus` por escopo | Shell e ordem de tabulação | D-HTML-14 |
| §6.4 ativação do usuário: eventos que ativam = `keydown`, `mousedown`, `pointerdown` (mouse), `pointerup` (não mouse), `touchend`; a transiente dura "no máximo alguns segundos" | Áudio, WebAuthn, clipboard | D-HTML-15 |
| §4.6.7 `manifest`, `icon`, `noopener`, `noreferrer` | Shell e links externos | D-HTML-16 |
| §2.5.8 bloqueio de renderização: folha de estilo externa bloqueia por padrão; `blocking="render"` é opt-in | CSS do shell | D-HTML-17 |

## Decisões

"CI" = job de validação do HTML estático no GitHub Actions (D-HTML-18).

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-HTML-01 | `<html lang="pt-BR">` no shell e em toda página estática. Trecho em outro idioma recebe `lang` próprio | Fase 2 RNF de acessibilidade; Fase 6 | CI (validador) + auditoria de `lang` do Lighthouse |
| D-HTML-02 | `<meta charset="utf-8">` como primeiro filho de `head`, única declaração, dentro dos primeiros 1024 bytes | Fase 6 | CI: script confere o deslocamento em bytes da declaração |
| D-HTML-03 | Um `<title>` que funciona fora de contexto ("Cajui — controle financeiro pessoal"). Em execução, o app troca o título por rota ("Relatórios — Cajui") | Fase 2 RNF (WCAG 2.4.2); Fase 3 (padrão de título) | E2E compara `document.title` em cada rota |
| D-HTML-04 | Uma `meta description` com texto próprio para listagem, sem dado pessoal, e `application-name` = "Cajui" | Fase 3 (texto vem de voz e tom); Fase 6 | Auditoria de descrição do Lighthouse; CI acusa duplicata |
| D-HTML-05 | `<meta name="viewport" content="width=device-width, initial-scale=1">`. Proibidos `user-scalable=no` e `maximum-scale` (zoom é requisito WCAG). Mantido mesmo fora do HTML Standard porque navegador e Lighthouse dependem dele | Fase 2 RNF de acessibilidade | E2E lê a meta **depois** que o Flutter monta (o motor pode reescrevê-la) e falha se houver token proibido |
| D-HTML-06 | `<meta name="color-scheme" content="light dark">` e dois `theme-color`, um por `media="(prefers-color-scheme: …)"`, com as cores da marca. Cosmético: os dados de compatibilidade embutidos na especificação marcam `theme-color` como sem suporte no Firefox | Fase 3 design system | CI valida sintaxe; checagem visual nos dois esquemas |
| D-HTML-07 | Um único script de bootstrap, **externo**, clássico, com `async`, no fim de `body`. Nenhum script que bloqueie o parser. Qualquer segundo script (vigia do D-HTML-10) é externo, `defer` e independente do bootstrap | Fase 4 ADR de carregamento web; Fase 6 | CI: todo `<script>` tem `src` e `async`, `defer` ou `type=module` |
| D-HTML-08 | **Sem** `preload`/`modulepreload`/`fetchpriority` manuais na v1: o carregador escolhe wasm ou JS em tempo de execução e um preload com chave diferente (destino, modo, credenciais) vira download em dobro. Entra só `<link rel="preconnect" href="<API>" crossorigin>`. Preload só depois de medição, com `as="fetch" crossorigin` para `.wasm` e `as="script"` para `.js` | Fase 4 ADR; Fase 2 RNF de desempenho | Lighthouse Performance ≥ 90; console sem aviso de "preload não utilizado"; DevTools mostra a conexão reaproveitada |
| D-HTML-09 | CSP nunca por `<meta http-equiv>` (a especificação remove `frame-ancestors`, `report-uri` e `sandbox`). Ver D-MDN-01 | Fase 4 ADR de cabeçalhos | CI: grep por `http-equiv="content-security-policy"` falha o build |
| D-HTML-10 | Fallback em três camadas no shell: (a) bloco estático visível desde o primeiro byte, com nome, marca e "Carregando…" em `<p role="status">`; (b) removido do DOM no primeiro quadro do Flutter; (c) vigia `defer` troca a mensagem por erro + botão "Tentar de novo" se o primeiro quadro não chegar em N s ou se faltar WebAssembly/WebGL. `<noscript>` cobre apenas JS desligado. Textos vêm do catálogo de erros | Fase 3 `docs/spec/error-catalog.md`; Fase 6 | E2E com JS desligado → texto do `noscript`; E2E bloqueando `main.dart.wasm` e `main.dart.js` → erro aparece após o tempo limite e o botão recebe foco |
| D-HTML-11 | O bloco de fallback é o único `<main>` do shell, com um `<h1>`. É **removido** (não escondido) quando o Flutter monta, para não duplicar landmark com a árvore de semântica. Shell sem `header`/`nav`/`footer` vazios. Páginas estáticas usam `header`/`main`/`footer`, `nav` só para navegação principal, títulos sem pular nível | Fase 3 (modelo de página estática); Fase 6 | axe/Lighthouse: um `main`, ordem de títulos; E2E conta `main` após a montagem |
| D-HTML-12 | No app, `dialog`/`inert` não são usados (o Flutter desenha os próprios diálogos). Em página estática, modal só com `<dialog>` + `showModal()`, nunca `div` com `role`; sem `tabindex` no `dialog`. No shell, quando o erro do D-HTML-10 cobre um Flutter meio carregado, o elemento hospedeiro recebe `inert` e fica visualmente obscurecido | Fase 3 design system (padrão de modal estático); Fase 6 | Teste de teclado: Esc fecha, foco volta ao gatilho; grep por `role="dialog"` em `div` |
| D-HTML-13 | Nenhum campo HTML escrito à mão na v1. Os `<input>` que o Flutter cria são governados por `autofillHints` e `keyboardType`: valor em dinheiro → teclado decimal; código de cadastro de passkey → `one-time-code`; nunca `cc-*`. Se o login adotar UI condicional de passkey, o campo leva `username webauthn` | Fase 2 RN de entrada de valores; Fase 6 | E2E inspeciona `inputmode`/`autocomplete` do elemento ativo |
| D-HTML-14 | Sem `tabindex` positivo. Shell sem `autofocus`; a única exceção é o botão de erro do D-HTML-10. Depois da montagem, a ordem de foco é responsabilidade da árvore de semântica do Flutter | Fase 2 RNF (WCAG 2.4.3, 2.4.7, 2.4.11) | E2E de teclado: Tab desde o carregamento chega ao primeiro controle do app; regra `tabindex` do axe |
| D-HTML-15 | Toda API sujeita a ativação (iniciar áudio, `navigator.credentials.get/create`, clipboard, tela cheia) é chamada dentro do handler do gesto, sem `await` de rede antes. O desafio do WebAuthn é buscado **antes** do clique | Fase 4 ADR de login web; Fase 6 (item de revisão de código) | E2E de login em WebKit e Chromium; teste de som do D-MDN-15 |
| D-HTML-16 | Shell com `rel="manifest"` e `rel="icon"` (SVG + PNG com `sizes`). Link externo em página estática leva `rel="noopener noreferrer"` | Fase 6 | CI (validador) + grep |
| D-HTML-17 | Sem `<style>` inline nem atributo `style` no shell: CSS em `shell.css` externo. Folha externa bloqueia a renderização por padrão, que é o desejado para o splash, e mantém `style-src 'self'` possível (D-MDN-02/03) | Fase 3 (tokens do splash); Fase 6 | CI: grep por `<style` e `style=` no `index.html` |
| D-HTML-18 | Shell e páginas estáticas passam por validador de conformidade HTML (gratuito, no CI). Erro de conformidade quebra o build | Fase 4 ADR de CI; Fase 6 | Job obrigatório no PR |

## O que não se aplica, e por quê

- **Quase todo o capítulo 4 para as telas do app.** Tabelas de relatório, formulários, listas e mídia não viram `<table>`, `<form>`, `<ul>` nem `<video>`: o Flutter pinta em canvas e expõe nós de semântica com ARIA. A semântica nativa do HTML é inalcançável; a equivalência se constrói com widgets `Semantics`, e a conformidade WCAG é julgada nessa árvore, não no que esta especificação descreve.
- **`dialog`, `popover` e `inert` dentro do app**: modalidade e retenção de foco são do Flutter.
- **Validação nativa de formulário, `label for`, `autocomplete` escrito à mão**: não há formulário HTML nosso.
- **Hierarquia de títulos dentro do app**: depende de como o Flutter exporta nível de título; pertence à pesquisa de Flutter/ARIA.
- **`headingoffset`/`headingreset`**: aparecem na edição lida; não usar — suporte de navegador não conferido e nenhuma necessidade.
- **`nomodule`, import maps, `integrity` em script de terceiros**: não há script de terceiros (D-MDN-04).
- **`blocking="render"`, `loading="lazy"`, `srcset`/`picture`**: o shell não tem imagem nem recurso tardio que justifique.
- **Microdata, `iframe`/`sandbox`, `srcdoc`, Web Storage, workers escritos à mão, sintaxe XML**: nada disso é escrito pelo projeto.
- **`meta name="generator"`/`keywords`**: sem valor; `generator` só anuncia a tecnologia a quem faz reconhecimento.

## Pontos de atenção

1. **A especificação governa uma fração mínima do produto.** WCAG 2.2 AA e Lighthouse Acessibilidade ≥ 90 dependem da árvore de semântica do Flutter, que historicamente só nasce sob demanda (botão oculto de acessibilidade) ou forçada no código. Não foi verificado aqui; é o maior risco para a meta da web e precisa ser fechado na pesquisa de Flutter antes da Fase 2.
2. **Lighthouse SEO ≥ 90 briga com privacidade.** App financeiro pessoal não deveria ser indexado, e `noindex` tende a reprovar a auditoria de rastreabilidade. A Fase 2 tem de escolher: shell indexável sem dado nenhum, ou `noindex` com a meta de SEO justificada como exceção. Pesos das auditorias não foram lidos aqui.
3. **O motor do Flutter pode reescrever a meta `viewport`** em tempo de execução, inclusive com `user-scalable=no` (comportamento conhecido, não verificado nesta leitura). Se acontecer, D-HTML-05 falha e bloquear zoom fere a WCAG. Por isso o teste lê a meta depois da montagem.
4. **`noscript` não cobre o caso provável.** JS desligado é raro; wasm/WebGL indisponível, CSP mal configurada ou rede ruim não são. A própria especificação recomenda trocar a página "sem script" por "com script" em tempo de execução — é o D-HTML-10. Sem o vigia, a falha do Cajui na web é tela em branco.
5. **`async` executa assim que chega**, possivelmente antes do fim do parsing. Script no fim de `body` evita depender de elemento ainda inexistente; o vigia usa `defer` justamente para ter o DOM pronto.
6. **Preload errado é pior que nenhum**: a chave inclui modo e credenciais; `as` fora da lista de destinos não faz nada; `.wasm` não tem destino próprio (usa `fetch`). Daí D-HTML-08 começar sem dicas.
7. **Landmark duplicado**: fallback com `<main>` + raiz de semântica do Flutter = dois conteúdos principais para o leitor de tela se o bloco for só escondido por CSS. Remover do DOM.
8. **Ativação transiente e Dart assíncrono**: um `await` de rede entre o clique e a API sensível pode estourar a janela de "alguns segundos" e falhar só em rede lenta, de forma intermitente. D-HTML-15 existe por isso.
9. **Inline zero é decisão conjunta** com a CSP: qualquer `<script>` ou `<style>` inline no shell obriga a hash na política a cada build. Se o template do Flutter trouxer script inline, ele sai para arquivo.
10. **Documento vivo**: a especificação muda quase todo dia. ADR e checklist citam seção + data de leitura, e reler faz parte de qualquer revisão de requisito que dependa dela.

## Páginas lidas

- `https://html.spec.whatwg.org/multipage/` — data da edição (17 September 2026) e sumário.
- `…/multipage/semantics.html` — `html`, `title`, `meta` (nomes padrão, `theme-color` com `media`, `color-scheme`, `description`, `referrer`), pragma de CSP, regra dos 1024 bytes, atributo `as` de `link`. A primeira leitura veio truncada; os trechos de `meta`, do pragma e do `as` foram relidos por extração de texto da mesma URL.
- `…/multipage/dom.html` — atributo `lang` (BCP 47, herança, string vazia) e mecanismo de bloqueio de renderização.
- `…/multipage/scripting.html` — `script` (`async`, `defer`, módulo, listas de execução, `blocking`, `fetchpriority`, `integrity`, `nomodule`) e `noscript` (modelo de conteúdo e a recomendação de evitar).
- `…/multipage/links.html` — `preload`, destinos de preload, consumo de recurso pré-carregado, `modulepreload`, `preconnect`, `dns-prefetch`, `manifest`, `icon`, `noopener`/`noreferrer`.
- `…/multipage/urls-and-fetching.html` — atributos de prioridade de busca, de bloqueio, lazy loading, CORS settings (`anonymous`, `use-credentials`, estado No CORS), referrer policy e nonce.
- `…/multipage/interactive-elements.html` — `dialog`: `show`, `showModal`, `close`, `requestClose`, `closedby`, passos de foco, `method=dialog`, proibição de `tabindex`.
- `…/multipage/interaction.html` — `inert`, ativação sticky/transiente e eventos que ativam, áreas focáveis, `tabindex`, `autofocus`, `inputmode`, `enterkeyhint`.
- `…/multipage/sections.html` — `body`, `article`, `section`, `nav`, `aside`, `h1`–`h6`, `hgroup`, `header`, `footer`, regra de níveis de título.
- `…/multipage/grouping-content.html` — `main`.
- `…/multipage/form-control-infrastructure.html` — nomes de campo de autofill, `on`/`off`, token `webauthn`.

## Não verificado

- `…/multipage/parsing.html` (interação do parser com scripts e folhas de estilo que bloqueiam script): não lido; a regra de execução veio só de `scripting.html`.
- Capítulo 15 (Rendering) e a seção de `popover`: não lidos.
- Comportamentos do Flutter citados em atenção 1 e 3 e em D-HTML-13 (mapeamento de `autofillHints`/`keyboardType` para atributos HTML, reescrita da meta `viewport`, ativação da árvore de semântica): fora desta fonte; conferir na pesquisa de Flutter.
- Pesos e critérios das auditorias do Lighthouse (atenção 2): fora desta fonte.
- Se `navigator.credentials.get()` na mesma origem exige ativação transiente em cada navegador: a especificação HTML define o mecanismo, não a lista de APIs de terceiros; D-HTML-15 assume o pior caso.
- O campo `viewport`: confirmado apenas que **não** está no HTML Standard; a especificação CSS que o define não foi lida.
