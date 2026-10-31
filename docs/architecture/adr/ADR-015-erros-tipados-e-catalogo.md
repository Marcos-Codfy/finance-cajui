# ADR-015 — Erros tipados, do domínio à tela

- **Estado:** aceita em 2026-09-20, no checkpoint da Fase 4
- **Data:** 2026-09-20
- **Implementa:** o [catálogo de erros](../../spec/error-catalog.md)

## Contexto

O catálogo lista 45 erros, cada um com gatilho, texto e saída, e proíbe o erro genérico. Um catálogo só vale se o código **não conseguir** fugir dele. Com exceções, foge fácil: um `throw` esquecido vira "Algo deu errado" na tela, e o compilador não avisa.

## Decisão

1. **Regra de negócio recusada não é exceção: é valor de retorno.** Os casos de uso devolvem `Result<T>` — um tipo selado, próprio e mínimo, com `Ok` e `Err` —, e o erro é uma `Failure`.
2. **`Failure` é uma hierarquia selada no domínio**, um tipo por situação, carregando os dados que o texto do erro usa:
   ```dart
   sealed class Failure { const Failure(); }
   final class VoucherBalanceExceeded extends Failure {
     const VoucherBalanceExceeded({required this.balance, required this.requested});
     final Money balance;
     final Money requested;
   }
   ```
   O `switch` sobre `Failure` é exaustivo: falha nova sem tratamento não compila.
3. **`ErrorCode` e `ErrorClass` são enums em `packages/api_contract`**, com um valor por linha do catálogo. App e servidor compartilham o pacote: código que não está no catálogo não existe.
4. **Três traduções, cada uma num lugar só:**

   | De → para | Onde | O que faz |
   |---|---|---|
   | `Failure` → `ErrorCode` + status HTTP + `detail` | servidor, camada `presentation` | Monta o corpo de erro da API |
   | corpo de erro → `Failure` | app, camada `infrastructure` | Reconstrói a falha tipada; corpo desconhecido vira `E-SRV-01`, com o `ref` |
   | `Failure` → texto e saídas | app, **um arquivo**, ao lado do design system | A redação do catálogo, com os valores formatados |

5. **Exceção continua existindo para o que é defeito**: estado impossível, contrato quebrado, falha de entrada e saída. Na borda de cada camada ela é capturada e convertida — `E-SRV-01` no servidor, `E-APP-01` no app —, com o tipo da exceção registrado, sem dado financeiro. Cada `E-APP-01` visto vira item do `BACKLOG.md`.
6. O texto de erro **nunca vem da API**. A API manda código e valores; o app escreve a frase.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Exceções para tudo | O compilador não cobra o tratamento. É como o erro genérico nasce |
| Pacote de `Either` ou `Result` de terceiros (`fpdart`, `dartz`) | Trazem um vocabulário funcional inteiro para usar dois construtores. Com `sealed` e `switch`, o tipo próprio tem vinte linhas e nenhuma dependência no domínio |
| Códigos como `String` | Erro de digitação só aparece em execução, e nada garante cobertura |
| Texto de erro montado no servidor | Espalha a redação por dois lugares, prende o texto a um deploy do backend e abre caminho para texto técnico vazar na tela |

## Consequências

- **Bom:** "nenhum erro genérico" deixa de ser promessa e vira propriedade do código. Acrescentar um erro obriga a tocar no enum, na falha, nas três traduções e no texto — e o compilador aponta cada lugar esquecido.
- **Bom:** trocar a redação de um erro é editar um arquivo do app.
- **Custo:** mais tipos e mais `switch` do que um `try/catch`. É o mesmo custo do estado selado por tela ([ADR-002](ADR-002-estado-com-riverpod.md)), pelo mesmo motivo.
- **Custo:** app antigo pode receber um código que ainda não conhece. Cai em `E-SRV-01` com o `ref`, e a RNF-COMPAT-05 cobre o caso de app antigo demais (`E-REQ-03`).

## Como se confere

- Teste que percorre `ErrorCode.values`: todo código tem classe, texto e ao menos uma saída.
- Teste que percorre o catálogo em Markdown e compara com o enum: **documento e código não podem divergir**.
- Teste que passa todos os textos pela lista de termos proibidos do guia de voz (RN-944) — a mesma que valida a saída da IA.
- Teste de contrato: cada rota, provocada a falhar, devolve exatamente o corpo de erro especificado.

## Atualização de 2026-10-30: o pedido de fora vira valor na borda

O item 5 da decisão deixava a exceção para o defeito e a capturava "na borda de cada camada". Os decodificadores do contrato (`JsonReader`, `CreateEntryRequest.fromJson` e os codecs) lançam `FormatException` ao primeiro campo que não bate (RNF-SEC-09), e até aqui o único lugar que a convertia em `E-REQ-01` era a última barreira do servidor (`Middlewares.errorBoundary`). Funcionava, mas dependia de ninguém esquecer que a barreira existe.

- **`Decoded<T>`**, em `packages/api_contract`, é o resultado de ler o que veio de fora: `Understood` (com o valor) ou `Refused` (com o código do catálogo). `Decoded.of` é a fronteira: a `FormatException` nasce e morre ali, e qualquer outra exceção continua subindo, porque é defeito do programa.
- **`RequestBody`**, no servidor, lê o corpo (teto de tamanho incluído) e o decodifica sem deixar exceção sair: JSON inválido ou fora do esquema vira `E-REQ-01`, e corpo grande demais vira `E-REQ-04`. Todas as rotas que recebem corpo passam por ele e tratam o resultado num `switch` exaustivo.
- **A barreira continua**, mas só como rede de segurança para o que ninguém previu (`E-SRV-01`).
- No **app**, o que cruza a camada de dados já voltava como valor (`Result`, `ApiOutcome`, `CodeOutcome`, `ReadOutcome`); o leitor nativo de comprovante passou a devolver `ReadFailed` também quando o módulo nativo não existe, como o leitor vazio, o que um teste de contrato das duas portas apontou.

Conferido por `decoded_test.dart` (contrato), `request_body_test.dart` (servidor) e `port_contracts_test.dart` (app).
