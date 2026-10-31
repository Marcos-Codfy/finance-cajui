# ADR-031 — Navegação com Coordinator

- **Estado:** aceita em 2026-10-30
- **Data:** 2026-10-30
- **Complementa:** a [ADR-002](ADR-002-estado-com-riverpod.md) (estado da tela) e a [ADR-001](ADR-001-monorepo-e-dominio-compartilhado.md) (camadas)

## Contexto

Cada tela do app abria as outras sozinha: um método `static open(context)` por tela e uma chamada a `Navigator.of(context)` em cada botão. Eram 26 desses métodos e mais de 60 usos do `Navigator` espalhados pelas telas. Três problemas:

- **A tela conhecia todas as vizinhas.** O Início importava oito páginas só para poder abri-las.
- **Para navegar era preciso um `BuildContext`.** Um ViewModel ou uma notificação não tinha como pedir "abra o detalhe deste lançamento" sem uma tela por perto.
- **Provar para onde um toque leva exigia desenhar a tela.** O teste montava o app inteiro para conferir uma navegação.

A pergunta "quem navega?" é diferente de "como se organiza uma tela?" (MVVM, [ADR-002](ADR-002-estado-com-riverpod.md)) e de "como se entregam as dependências?" ([ADR-032](ADR-032-injecao-e-factory-de-cena.md)). Cada uma tem um padrão só.

## Decisão

1. **Uma porta, `SceneNavigator`**, em `app/lib/src/core/navigation/`, com quatro operações: empilhar uma cena, empilhar um painel que sobe de baixo, fechar e voltar à casca. A implementação, `KeySceneNavigator`, fala com o `Navigator` raiz por uma `GlobalKey` que a raiz do app entrega ao `WidgetsApp`. **É o único arquivo que toca o `Navigator` do Flutter.**
2. **Um Coordinator por feature**, em `presentation`: `LedgerCoordinator`, `BudgetCoordinator`, `CardsCoordinator`, `DebtsCoordinator`, `SettingsCoordinator`, `ReceiptsCoordinator` e `ReviewCoordinator`. Cada um tem métodos com nome de intenção (`openEntry`, `openCardForm`, `askAmount`) e é quem decide **qual cena abrir e com que dados**.
3. **A tela diz o que aconteceu; o Coordinator decide para onde ir.** O botão chama `context.coordinator(ledgerCoordinatorProvider).openEntryForm()`; ele não sabe que `EntryFormPage` existe.
4. **ViewModel não navega.** Um fluxo que termina (gravar um cartão, uma dívida, a chave da casa) vira o estado `Saved` ou `Entered`; a tela escuta o estado e pede o fechamento. Nenhum ViewModel importa navegação.
5. **O acesso a partir da tela** é a extensão `CoordinatorAccess` sobre `BuildContext`. Ela **lê** o coordinator na hora do toque, nunca o observa, então a tela não reconstrói por causa dele. Assim uma tela de lista continua `StatelessWidget`.
6. **A seta de voltar** de toda tela é `context.back`, que passa pelo mesmo `SceneNavigator`.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| `go_router` | Resolve endereço de tela: deep link e URL. O app é Android, e a web é só consulta, sem rota para compartilhar. O que o Cajui tem de "entrada de fora" (notificação, widget, compartilhamento) já chega por canais próprios e vira uma chamada de coordinator |
| Rotas nomeadas do `Navigator` | A tela ainda conheceria o nome de cada vizinha, e o argumento viajaria sem tipo |
| Um contrato e uma implementação por coordinator | Sete interfaces sem ninguém para trocar. O que se troca nos testes é o navegador, e isso a porta única `SceneNavigator` já permite |
| Deixar como estava (`static open` em cada tela) | Mantém os três problemas do contexto |

## Consequências

- **Bom:** o Início deixou de importar as páginas das outras features: importa os coordinators. Mudar o fluxo de uma tela é mexer num coordinator, e não em cada botão.
- **Bom:** os coordinators se testam sem desenhar nada, com um navegador falso que só anota o que lhe pediram (`RecordingSceneNavigator`).
- **Custo:** `context.coordinator(...)` lê um provider pelo contexto, o que lembra um localizador de serviço. Fica restrito a coordinators e ao navegador, e a leitura é sempre na hora do toque.
- **Limite:** a rota ainda é empilhada por cima da casca. Voltar com o botão do sistema segue o `Navigator`, como antes.

## Como se confere

- `app/test/core/navigation/coordinators_test.dart`: cada coordinator, com o navegador falso, abre a cena certa com os dados certos e devolve o resultado de quem desiste como `null`.
- `grep "Navigator\." app/lib` não encontra nenhum uso: o `Navigator` só é tocado por `KeySceneNavigator`, pela chave entregue ao `WidgetsApp`.
- A regra de camadas continua valendo: `application` não importa `presentation`.
