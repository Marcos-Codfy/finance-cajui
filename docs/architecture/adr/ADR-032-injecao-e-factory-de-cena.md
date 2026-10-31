# ADR-032 — Injeção de dependência e factory de cena

- **Estado:** aceita em 2026-10-30
- **Data:** 2026-10-30
- **Complementa:** a [ADR-002](ADR-002-estado-com-riverpod.md) e a [ADR-031](ADR-031-navegacao-com-coordinator.md)

## Contexto

Na aula, cada cena é montada por uma **factory**: uma função que cria o servidor, o coordinator e o armazenamento, injeta tudo no ViewModel e devolve a tela pronta, uma vez só, fora do método que redesenha. As dependências compartilhadas vêm de uma **raiz de composição**, e a injeção é manual.

O Cajui já decidiu usar Riverpod para o estado ([ADR-002](ADR-002-estado-com-riverpod.md)), e o Riverpod já é um injetor de dependências. Escrever uma factory de cena à mão, por cima, entregaria a mesma coisa por dois caminhos. O que falta é dizer **onde cada papel da factory mora**.

## Decisão

1. **Injeção por Riverpod.** Cada porta tem um `Provider`, e a raiz de composição (`app/lib/src/app/composition.dart`) é **o único lugar** que liga uma porta ao adaptador ([ADR-001](ADR-001-monorepo-e-dominio-compartilhado.md)). Não há localizador de serviço global.
2. **O papel da factory de cena é dividido em dois:**

   | Papel da factory na aula | Quem faz no Cajui |
   |---|---|
   | Criar a tela com os dados que ela pede | O **Coordinator** da feature: `openCardForm(card:)` monta `CardFormPage(card: card)`; `openCorrection(book, entry)` monta o rascunho e o escopo do formulário |
   | Criar o ViewModel e injetar o que ele precisa | O **provider do ViewModel** (`cardFormProvider`, `debtFormProvider`, `keyProvider`), que lê as portas por `ref` |
   | Montar uma vez só, e não a cada redesenho | O provider é `autoDispose`: o ViewModel nasce quando a cena abre, vive enquanto ela existe e morre ao fechar. Um redesenho (ou um hot reload) não cria outro, porque o estado mora no container, e não no `build` |

3. **O teste troca as peças por `overrides`**: o adaptador de uma porta (`testOverrides`) ou o navegador (`sceneNavigatorProvider`). Nenhum construtor de tela recebe dependência de teste.
4. **Cena que precisa de um valor próprio** (o rascunho de uma correção) o recebe por um **escopo de provider** criado no coordinator, e não por parâmetro encadeado através de widgets.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Injeção manual por construtor, com uma função factory por tela | Duplica o que o Riverpod faz e obriga a passar cada dependência por todos os widgets no caminho |
| `get_it` | Localizador global: qualquer código pega qualquer coisa de qualquer lugar, e o erro de escopo só aparece em execução |
| Uma classe `*_factory.dart` por cena | Tornaria o coordinator uma casca vazia: ele já é quem sabe qual cena abrir e com que dados |

## Consequências

- **Bom:** uma dependência nova entra em um lugar (o provider da porta) e na raiz de composição; nenhuma tela muda.
- **Bom:** o ViewModel é descartado com a cena, então cada abertura começa limpa (sem a recusa da vez anterior).
- **Custo:** quem vem da aula procura uma `*_factory.dart` e não encontra. Esta ADR e o quadro do README dizem onde está cada papel.
- **Limite:** o design system **não** depende de Riverpod ([ADR-002](ADR-002-estado-com-riverpod.md)), então não tem factory nem provider.

## Como se confere

- `composition.dart` é o único arquivo que liga uma porta ao adaptador; o verificador de camadas reprova `application` e `presentation` importando `infrastructure`.
- Testes de ViewModel (`card_form_view_model_test.dart`, `debt_form_view_model_test.dart`, `key_view_model_test.dart`) criam o container com `overrides`, sem montar tela.
