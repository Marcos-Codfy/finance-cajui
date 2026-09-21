# ADR-013 — Web de consulta em Flutter Web, e a meta de Lighthouse

- **Estado:** proposta · aguarda o checkpoint da Fase 4 · **contém uma exceção à meta**, que a RNF-WEB-13 só admite por ADR aprovada em checkpoint
- **Data:** 2026-09-20
- **Medido em:** [spike A](../spikes/web-lighthouse.md) · **responde:** BL-002

## Contexto

O plano marcou a meta de Lighthouse ≥ 90 como o maior risco da definição de pronto, e deixou em aberto trocar a tecnologia da web se a medição falhasse. A web do Cajui é **modo consulta, no computador**: ver o mês, a fatura, o fechamento, as dívidas, os resumos, e conversar com o assistente. Não captura, não lê comprovante, não lança.

## O que a medição mostrou

Com a gallery como amostra, a árvore de acessibilidade ligada desde a abertura e o preset desktop:

| Categoria | WebAssembly | JavaScript | Meta |
|---|---|---|---|
| Performance | 100 | 99 | ≥ 90 |
| Acessibilidade | 100 | 100 | ≥ 95 |
| Boas práticas | **81** | **81** | ≥ 95 |
| Primeiro quadro do app | 0,28 s | 0,53 s | ≤ 2,5 s |

## Decisão

1. **A web é Flutter Web, compilada para WebAssembly**, com o build em JavaScript como reserva para navegador sem WasmGC (RNF-WEB-12). Não se troca a camada da web: o risco não se confirmou, e uma segunda tecnologia de interface custaria o design system inteiro de novo.
2. **Escopo fechado: consulta.** Imposto também no servidor — a sessão da web não tem permissão de escrita ([ADR-008](ADR-008-autenticacao.md)).
3. **A semântica nasce ligada** (`ensureSemantics()` na abertura). Toda medição é feita com ela ligada.
4. **Nada de terceiros**: build com `--no-web-resources-cdn`; runtime, fontes e sons saem da própria origem.
5. **Nada antes do primeiro quadro que não seja o primeiro quadro**: sons sob demanda, sessão restaurada depois, casca HTML com a marca enquanto o motor sobe.
6. **Preset desktop** é o alvo oficial da medição, porque é o uso.

### A exceção: boas práticas

A nota para em 81 por **uma única auditoria**: `deprecations` — o motor do Flutter chama `Intl.v8BreakIterator`, API marcada como obsoleta pelo Chrome. Não é código nosso e não há opção de build que a remova.

Em vez de baixar a régua para 80, o CI **afirma cada auditoria de boas práticas pelo nome**, com `deprecations` numa lista de exceções de um item, anotada com o motivo e com a versão do Flutter em que foi observada. Consequências:

- uma regressão **nossa** em qualquer outra auditoria reprova o build;
- uma **segunda** API obsoleta também reprova — a exceção é para esta chamada, não para a categoria;
- no dia em que o Flutter corrigir, a nota sobe sozinha e a exceção é apagada.

A cada atualização do Flutter, a exceção é reavaliada.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Web em HTML e TypeScript | Daria 100 nas três categorias e uma página mais leve. Custaria reescrever tokens, componentes, 62 estados de tela e o domínio noutra linguagem — o fim da fonte única. A medição mostrou que o ganho não paga o custo |
| Baixar a meta de boas práticas para 80 | Esconderia regressões futuras atrás de uma nota folgada |
| Medir com a semântica desligada | Proibido pela RNF-WEB-13, e inútil: performance já é 100 com ela ligada |
| Só o build em JavaScript | Mais lento para subir (0,53 s contra 0,28 s) e com mais bloqueio da thread principal. Fica como reserva |

## Consequências

- **Bom:** uma base de código, um design system e uma gallery servem ao Android e à web.
- **Custo:** o piso de transferência é o motor — 1,2 MB comprimido, 55% do total. Não há como baixar disso; o orçamento de 2,5 MB conta com ele.
- **Custo:** **fontes em 341 KB, contra o teto de 200 KB** (BL-025). É o único orçamento da web estourado, e tem caminho: recorte para o alfabeto latino, eixos fixos e dispensa da Roboto de reserva.
- **Limite:** acessibilidade 100 no Lighthouse audita a árvore de semântica; não substitui o roteiro manual com leitor de tela (BL-019 continua aberto para isso).
- **Limite:** a amostra é a gallery. O app real tem mais código; a medição é repetida na Fase 6, sobre o app, e na Fase 7, contra o endereço publicado.

## Como se confere

- Lighthouse CI no `main` (não em todo PR: BL-023), três rodadas, com as afirmações da RNF-WEB-01 a 06 e a lista de exceções de um item.
- A marca `cajui:first-frame` é o número que decide, não o FCP da casca.
