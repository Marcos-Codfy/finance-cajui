# Modelo de dados

Dois níveis: o **modelo de domínio** (o que existe e o que sempre é verdade) e o **modelo de persistência** (como isso é gravado em JSON). O domínio não conhece o segundo: fala com ele por portas, o que mantém aberta a troca por SQLite sem reescrever regra (ADR-004).

Termos em [glossary.md](glossary.md); regras em [rules/](rules/README.md).

## Modelo de domínio

### Objetos de valor

| Objeto | Campos | Invariantes |
|---|---|---|
| `Money` | `cents: int` | Inteiro; operações fechadas em centavos (RN-101 a RN-103) |
| `Tender` | `cash` \| `mealVoucher` | — |
| `AmountRange` | `min`, `max` | `0 ≤ min ≤ max` (RN-420) |
| `BudgetMonth` | `year`, `month` | Mês de calendário no fuso de negócio |
| `LocalDate` | `year`, `month`, `day` | Data sem hora, no fuso de negócio |
| `Confidence` | `high` \| `medium` \| `low` | — |
| `PaymentLine` | `paymentMethodId`, `amount` | `amount > 0`; a moeda vem da forma de pagamento (RN-205) |
| `InstallmentPlan` | `count`, `installments[]`, `interestTotal` | Soma das parcelas = valor + juros (RN-311, RN-314) |

### Entidades

| Entidade | Campos principais | Invariantes |
|---|---|---|
| `Household` | fuso de negócio, início do uso | Única (usuário único) |
| `IncomeSource` | nome, moeda, valor esperado, dia esperado, vigência | RN-130, RN-134 |
| `Category` | nome, bloco, grupo, elegível ao vale | Um bloco e um grupo (RN-202); nunca representa cartão (RN-301) |
| `PaymentMethod` | nome, tipo (`physicalCash`, `pix`, `debit`, `creditCard`, `mealVoucher`, `bankSlip`), moeda | `mealVoucher` ⇔ moeda `mealVoucher` |
| `CreditCard` (especializa `PaymentMethod`) | dia de fechamento, dia de vencimento, limite opcional | Dias entre 1 e 31; RN-303 |
| `Entry` | descrição, valor, data da compra, categoria, linhas de pagamento, parcelamento opcional, fora do padrão, comprovante opcional, origem (`manual` \| `share`) | Soma das linhas = valor (RN-203); data não futura (RN-206) |
| `Reversal` | lançamento de origem, valor, data | Soma dos estornos ≤ valor (RN-210) |
| `FixedExpense` | nome, valor, dia, categoria, forma habitual, vigência | RN-410 a RN-415 |
| `VariableBudget` | categoria, faixa, vigência | RN-420 a RN-427 |
| `Debt` | credor, tipo, parcela, total de parcelas, pagas, dia, início, juros opcionais, lançamento de origem opcional | `pagas ≤ total` (RN-501 a RN-503) |
| `Settlement` | cartão, ciclo, valor, data | Não é despesa (RN-340) |
| `Receipt` | resumo SHA-256, tipo, tamanho, recebido em | Único por resumo (RN-220) |
| `LearnedRule` | estabelecimento normalizado, categoria, criada por qual correção | RN-7xx |

### Visões derivadas

Nunca são gravadas como fato; são sempre recalculáveis a partir dos eventos.

| Visão | Deriva de | Regras |
|---|---|---|
| `CardStatement` | Linhas no cartão + parcelas + estornos do ciclo | RN-330 a RN-333 |
| `VoucherBalance` | Créditos, linhas em vale, estornos, ajustes | RN-120 a RN-123 |
| `MonthPlan` | Fontes, fixos, faixas, calendário de parcelas | RN-430 a RN-433 |
| `MonthIndicators` | `MonthPlan` + lançamentos do mês | RN-6xx |
| `StatementReserve` | Linhas à vista no cartão ainda não liquidadas | RN-320, RN-321 |

## Modelo de persistência

### Princípio

A fonte da verdade é um **log de eventos só de acréscimo**. Tudo o mais — snapshot, índice — é cache que pode ser apagado e refeito. Corrigir é acrescentar um evento, nunca reescrever um (RN-208).

### Envelope do evento

```json
{
  "id": "01J8M3K9Z2Q5W7X4R6T8V0B1C3",
  "type": "EntryRecorded",
  "v": 1,
  "occurredOn": "2026-09-12",
  "recordedAt": "2026-09-12T21:04:37.512Z",
  "deviceId": "dev_01J7…",
  "prev": "sha256:9f2c…",
  "payload": { }
}
```

| Campo | Papel |
|---|---|
| `id` | ULID: único e ordenável por tempo |
| `type` + `v` | Tipo e versão do esquema do `payload`. Esquema antigo é convertido na leitura; o arquivo nunca é reescrito |
| `occurredOn` | Data do fato no fuso de negócio — é ela que decide o mês |
| `recordedAt` | Instante da gravação, em UTC |
| `deviceId` | Aparelho que originou o evento |
| `prev` | Resumo do evento anterior. Encadeia o log: corrupção ou adulteração quebra a cadeia e é detectada na leitura |

### Exemplo: uma compra dividida entre vale e Pix

```json
{
  "type": "EntryRecorded", "v": 1, "occurredOn": "2026-09-12",
  "payload": {
    "entryId": "ent_01J8M3…",
    "description": "Mercado Boa Compra",
    "amountCents": 8600,
    "categoryId": "cat_groceries",
    "paymentLines": [
      { "paymentMethodId": "pm_voucher", "amountCents": 3000 },
      { "paymentMethodId": "pm_pix", "amountCents": 5600 }
    ],
    "isExceptional": false,
    "source": "share",
    "receiptSha256": "b1946ac9…",
    "classification": { "classifier": "deepseek", "confidence": "high", "accepted": true }
  }
}
```

Valores são sempre inteiros de centavos (`amountCents`); datas de negócio são `AAAA-MM-DD`; instantes são ISO 8601 em UTC.

### Catálogo de eventos

| Área | Eventos |
|---|---|
| Domicílio | `HouseholdConfigured` |
| Renda | `IncomeSourceDefined` · `IncomeSourceChanged` · `IncomeSourceDeactivated` · `IncomeReceived` · `VoucherBalanceAdjusted` |
| Cadastro | `CategoryDefined` · `CategoryChanged` · `PaymentMethodDefined` · `PaymentMethodChanged` |
| Lançamento | `EntryRecorded` · `EntryCorrected` · `EntryCancelled` · `EntryReversed` |
| Cartão | `StatementSettled` · `StatementTotalInformed` |
| Orçamento | `FixedExpenseDefined` · `FixedExpenseChanged` · `FixedExpenseEnded` · `VariableBudgetDefined` · `VariableBudgetChanged` · `BudgetReallocated` · `MonthPlanAdjusted` |
| Dívida | `DebtRegistered` · `DebtChanged` · `DebtPayoffQuoteInformed` · `DebtPaidOff` |
| Fechamento | `MonthClosed` · `MonthCloseRevised` |
| Captura | `ReceiptStored` · `ClassificationFeedbackRecorded` · `LearnedRuleCreated` · `LearnedRuleRemoved` |
| Retorno | `ReminderShown` |
| Consumo de IA | `AiUsageRecorded` (tokens de entrada, de saída e em cache, por operação) |

Dados de autenticação — aparelhos pareados, chaves públicas, sessões — **não** ficam neste log: moram em arquivo próprio, com ciclo de vida e permissões próprios.

### Arquivos no servidor

```
data/
  events/2026/2026-09.jsonl     um evento por linha; um arquivo por mês de gravação
  snapshots/2026-09.json        estado consolidado do mês
  index.json                    por mês: arquivo, contagem, id e resumo do último evento
  receipts/b1/b1946ac9….pdf     comprovantes originais, endereçados pelo resumo
  auth/devices.json             aparelhos pareados (fora do log financeiro)
  backups/                      cópias diárias com rotação
```

Todos os arquivos são cifrados em repouso. O formato exato — envelope cifrado por linha ou arquivo reescrito — e a ordem de gravação entre log, índice e snapshot são decididos na ADR-004/005 (BL-015), porque não se anexa a um arquivo cifrado como um todo.

### Garantias de escrita

| Garantia | Como |
|---|---|
| Escrita atômica | Grava em arquivo temporário no mesmo diretório, sincroniza e renomeia |
| Um escritor por vez | Trava de arquivo; conflito é erro com mensagem própria, nunca sobrescrita silenciosa |
| Ordem segura | Primeiro o log; índice e snapshot depois. Queda no meio deixa cache atrasado, que a próxima leitura detecta pelo `index.json` e refaz |
| Validação na entrada e na saída | Todo evento é validado contra o esquema do seu `type` + `v` antes de gravar e depois de ler |
| Integridade | Cadeia de `prev` conferida na leitura do mês; quebra gera o erro de banco corrompido, com o ponto exato |
| Idempotência | Cada comando do app leva uma chave; repetir o envio não duplica o evento (importante para a fila offline) |

### Comprovantes ⚑ validar

O arquivo original é salvo **no aparelho na hora**, para nada se perder sem rede, e **enviado ao servidor** quando houver conexão, cifrado em repouso como o resto. Isso preserva os comprovantes numa troca de aparelho e permite consultá-los na web. A imagem **nunca** vai para a IA: só o texto extraído, já com dados pessoais mascarados. A cópia local pode ser removida depois de confirmado o envio.

## Limites honestos do JSON

Para um usuário, em um servidor, com um escritor por vez, arquivo JSON é suficiente e tem uma virtude real: abre em qualquer editor por SSH, com a ferramenta `dbtool` decifrando. Deixa de ser adequado quando qualquer um destes for verdade:

| Sinal | Por que quebra |
|---|---|
| Dois escritores ao mesmo tempo (segundo usuário, ou app e web gravando juntos com frequência) | Trava de arquivo serializa tudo; não há transação entre arquivos |
| Log do mês acima de algumas dezenas de MB | Reler o mês inteiro a cada consulta passa a pesar |
| Consulta que cruza muitos meses por critério livre | Sem índice secundário, vira varredura |
| Necessidade de reverter várias gravações como uma só | Não existe transação multi-arquivo |

A porta de saída já está no desenho: o domínio depende de `EventStore` e `SnapshotStore`; trocar a implementação JSON por uma SQLite não toca em regra de negócio, e o próprio log é o roteiro de migração.
