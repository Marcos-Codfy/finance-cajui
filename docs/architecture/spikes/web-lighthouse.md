# Spike A — Flutter Web e Lighthouse

**Pergunta.** O plano apontou a meta de Lighthouse ≥ 90 como o maior risco da definição de pronto: Flutter Web desenha em canvas e carrega um runtime de mais de 1 MB. A meta fecha, com a árvore de acessibilidade ligada? Responde BL-002 e BL-019.

**Resposta curta.** Fecha, com folga, em **performance (100)** e **acessibilidade (100)**. **Boas práticas para em 81**, por uma única auditoria que vem do motor do Flutter e não do nosso código — vira exceção documentada na ADR-013. O spike também achou dois desperdícios, já corrigidos, e um orçamento estourado (fontes).

## O que foi medido

| Item | Valor |
|---|---|
| Amostra | A gallery do design system: 17 páginas, 62 estados de tela, fontes e sons do pacote. É o mesmo motor, as mesmas fontes e os mesmos componentes do app — mas **não é o app** (ver [Limites](#limites-desta-medição)) |
| Builds | `flutter build web --wasm` e `flutter build web --release` (JavaScript), os dois com `--no-web-resources-cdn` · Flutter 3.47.5 |
| Semântica | **Ligada desde a abertura** (`SemanticsBinding.instance.ensureSemantics()`), como manda a RNF-WEB-03. Nenhuma medição foi feita com ela desligada |
| Ferramenta | Lighthouse 13.5.0, preset `desktop` (tela 1350 × 940, rede simulada de 10 Mbps e 40 ms, CPU sem redução) · Chrome 153 sem interface · 3 rodadas por build, mediana |
| Servidor | `spikes/web-lighthouse/serve.mjs`: Brotli, `application/wasm`, isolamento de origem (COOP e COEP) e `noindex` — o que a hospedagem de produção faz e um servidor de teste comum não faz |
| Máquina | O notebook de desenvolvimento (índice de referência do Lighthouse: 3442) |

Como repetir, da raiz: `spikes/web-lighthouse/measure.sh wasm packages/design_system/gallery/build/web_wasm`.

## Resultado

Mediana de três rodadas, depois das duas correções descritas abaixo.

| Medida | WebAssembly | JavaScript | Orçamento | Situação |
|---|---|---|---|---|
| Performance | **100** | **99** | ≥ 90 (RNF-WEB-01) | ✔ |
| Acessibilidade | **100** | **100** | ≥ 95 | ✔ |
| Boas práticas | **81** | **81** | ≥ 95 | ✘ — [exceção](#boas-práticas-81-e-o-porquê) |
| FCP | 0,23 s | 0,17 s | ≤ 0,8 s (RNF-WEB-04) | ✔ |
| LCP | 0,34 s | 0,22 s | ≤ 1,2 s | ✔ |
| TBT | 0 ms | 94 ms | ≤ 150 ms | ✔ |
| CLS | 0 | 0 | ≤ 0,05 | ✔ |
| Speed Index | 0,61 s | 0,84 s | ≤ 1,8 s | ✔ |
| **Primeiro quadro do Flutter** | **0,28 s** | **0,53 s** | ≤ 2,5 s a frio (RNF-WEB-05) | ✔ |
| Transferência total | 2.160 KB | 2.439 KB | ≤ 2.560 KB (RNF-WEB-06) | ✔, com pouca folga no JS |
| Código do app | 587 KB | — | ≤ 1.024 KB | ✔ |
| Fontes | 341 KB | 341 KB | ≤ 200 KB | ✘ — BL-025 |
| Requisições até o primeiro quadro | 15 | 12 | ≤ 20 | ✔ |
| Hosts de terceiros | 0 | 0 | 0 (RNF-WEB-08) | ✔ |

FCP e LCP medem a **casca HTML** (o nome da marca sobre a cor de fundo, que aparece antes de o Flutter subir). Por isso a RNF-WEB-05 exige a medida do primeiro quadro do próprio app, registrada pela marca `cajui:first-frame` — e é ela que importa: **0,28 s em WebAssembly**.

Para onde vai o peso, no build em WebAssembly: runtime `skwasm.wasm` 1.182 KB (55%) · código do app 587 KB · Fraunces 195 KB · Geist 73 KB · Roboto de reserva 73 KB.

## O que o spike mudou

| Achado | Antes | Depois | O que foi feito |
|---|---|---|---|
| Os 10 sons eram baixados na abertura, com o som desligado | 35 requisições · primeiro quadro em 0,92 s | 15 requisições · 0,28 s | `AudioplayersSoundPlayer` carrega sob demanda; a gallery só pré-carrega quando o som é ligado. **Vale para o app**: o som nasce desligado |
| Runtime e fonte de reserva vinham de `gstatic.com` | 2 hosts de terceiros | 0 | Build com `--no-web-resources-cdn`. Entra no script de build da Fase 7 |
| `index.html` do molde do Flutter: sem idioma, sem descrição, título "gallery" | — | `lang="pt-BR"`, descrição, `noindex`, casca com o primeiro quadro em HTML | Reescrito; o mesmo molde serve ao app |

## Boas práticas: 81, e o porquê

Uma auditoria só reprova: **"Uses deprecated APIs" — `Intl.v8BreakIterator`**. A chamada está dentro do motor do Flutter (quebra de linha de texto), não em código nosso, e não há opção de build que a remova. Todas as outras auditorias de boas práticas passam.

Proposta para a ADR-013: o CI afirma **cada auditoria de boas práticas individualmente**, com esta única na lista de exceções, em vez de afirmar a nota. Assim uma regressão nossa continua reprovando o build, e a exceção some sozinha no dia em que o Flutter trocar a API. É a exceção "só por ADR aprovada em checkpoint" que a RNF-WEB-13 prevê.

## Fontes: 341 KB contra 200 KB

Confirma o BL-025, com um agravante: o Flutter embarca uma **Roboto de reserva** (73 KB) para glifos que as fontes do app não têm. Caminhos, para a Fase 6:

1. Recortar Fraunces e Geist para o alfabeto latino e fixar os eixos `SOFT` e `WONK` da Fraunces (só `opsz` e `wght` variam no design).
2. Conferir quais glifos caem na reserva e, se forem poucos, cobri-los nas fontes do app para dispensar a Roboto.
3. Se ainda assim passar de 200 KB, o orçamento sobe por escrito: fonte é identidade, e o total de 2,5 MB continua fechando.

## Limites desta medição

- **A gallery não é o app.** Não tem autenticação, chamadas de rede, gerência de estado nem relatórios. O app vai pesar mais em código (hoje 587 KB de um teto de 1.024 KB) e pode gastar mais CPU na abertura. O motor e as fontes — 70% do peso medido — são os mesmos.
- **Preset desktop, como decidido**: a web é modo consulta no computador. No preset de celular a nota seria menor, e não é o alvo.
- **Rede simulada em máquina local.** Não mede a latência real da hospedagem; a Fase 7 repete a medição contra o endereço publicado.
- **Acessibilidade 100 não é prova de uso com leitor de tela.** O Lighthouse audita a árvore `flt-semantics`; o roteiro manual com leitor de tela continua obrigatório (RNF-A11Y).
- Firefox e Safari não rodam o build em WebAssembly e caem no JavaScript (RNF-WEB-12): os números da coluna JavaScript são o piso deles, não uma promessa.

## Decisões que saem daqui

1. **A web do Cajui é Flutter Web em WebAssembly**, com o JavaScript como caminho de reserva. O risco número 1 do plano está respondido: não é preciso trocar a camada da web.
2. **Semântica sempre ligada na web** custa pouco o bastante para não ser dilema: performance 100 com ela ligada.
3. **Nada é baixado antes do primeiro quadro sem necessidade**: sons sob demanda; sessão restaurada depois do primeiro quadro (RNF-WEB-07).
4. **Boas práticas por auditoria, com uma exceção nomeada** (ADR-013).
5. Os orçamentos "propostos" da RNF-WEB-04 a 06 ficam **confirmados**, menos o de fontes, que segue aberto no BL-025.
