# ADR-002 — Estado da interface com Riverpod

- **Estado:** proposta · aguarda o checkpoint da Fase 4
- **Data:** 2026-09-20

## Contexto

Toda tela do Cajui tem, no mínimo, quatro estados — carregando, com dados, erro e sem rede — e várias têm mais ([matriz de telas](../../spec/use-cases.md#telas-e-seus-estados)). A gallery já desenha os 62. Falta decidir como a tela **chega** a cada estado, de um jeito que seja testável sem abrir o app e que não espalhe regra de negócio pelos widgets.

## Decisão

1. **Riverpod**, sem geração de código. O padrão é MVVM, **só na camada `presentation`**: um `Notifier` é o ViewModel da tela.
2. Cada tela tem um **estado imutável e selado** (`sealed class DashboardState`), com um caso por estado da matriz. O widget faz `switch` exaustivo sobre ele: estado novo sem desenho não compila.
3. O `Notifier` só conversa com **casos de uso** da camada `application`. Widget não conhece repositório, HTTP nem armazenamento.
4. Falhas chegam tipadas ([ADR-015](ADR-015-erros-tipados-e-catalogo.md)) e viram o estado de erro com o código do catálogo. Não há `try/catch` em widget.
5. Dependências entram por `Provider` e são trocadas por `overrides` nos testes. Não há localizador de serviço global.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Bloc | Resolve o mesmo problema com mais cerimônia (evento, estado e bloc por tela). Para uma pessoa, o custo por tela pesa; a injeção de dependência ainda pediria outra peça |
| Provider | Depende de `BuildContext` para ler dependência, o que empurra lógica para dentro do widget; erro de escopo só aparece em execução |
| `setState` e `InheritedWidget` puros | É o que o design system usa, e lá basta. No app, com dados assíncronos, fila offline e sessão, vira uma gerência de estado caseira |
| Riverpod com `riverpod_generator` | O gerador exige `build_runner` no ciclo de edição. O ganho é açúcar; o custo é build mais lento e código gerado no repositório |

## Consequências

- **Bom:** o `Notifier` testa-se como classe comum: dado o caso de uso falso, espera-se a sequência de estados. Os quatro estados mínimos viram quatro testes por tela.
- **Bom:** `AsyncValue` não é exposto à tela. O estado selado do projeto diz mais — "sem renda cadastrada" não é "erro" nem "dados".
- **Custo:** um estado selado por tela é mais código que um `AsyncValue` cru. É o preço de o compilador cobrar cada estado.
- **Limite:** o design system **não** depende de Riverpod. Tema e resposta sonora continuam em `InheritedWidget`, para o pacote servir a qualquer app.

## Como se confere

- Teste de `Notifier` por tela, cobrindo cada caso do estado selado.
- Regra de importação (Fase 6): `presentation` importando `infrastructure` reprova o commit.
