# Referência da API · Cajui

Todos os endpoints do servidor do Cajui, com verbo, formato da requisição e resposta esperada. É a versão curta: os detalhes de cada campo, a lista completa de erros e as fontes no código estão em `docs/api.md`. Os exemplos usam valores fictícios.

## Visão geral

| Verbo | Rota | Autenticação | Sucesso |
|---|---|---|---|
| GET | `/health` | não | 200 |
| POST | `/v1/auth/code` | não | 200 |
| POST | `/v1/receipts/classify` | chave de API | 200 |
| POST | `/v1/statements/read-part` | chave de API | 200 |
| POST | `/v1/assistant/ask` | token | 200 |
| GET | `/v1/head` | token | 200 |
| GET | `/v1/categories` | token | 200 |
| POST | `/v1/categories` | chave de API | 201 (200 se mantida) |
| GET | `/v1/cards` | token | 200 |
| POST | `/v1/cards` | chave de API | 201 (200 se mantido) |
| GET | `/v1/income` | token | 200 |
| POST | `/v1/income` | chave de API | 201 |
| POST | `/v1/voucher/adjustments` | chave de API | 201 |
| GET | `/v1/facts` | token | 200 |
| POST | `/v1/facts` | chave de API | 201 |
| GET | `/v1/plan` | token | 200 |
| POST | `/v1/plan` | chave de API | 200 |
| GET | `/v1/entries` | token | 200 |
| POST | `/v1/entries` | chave de API | 201 |
| PUT | `/v1/entries/{id}` | chave de API | 200 |
| DELETE | `/v1/entries/{id}` | chave de API | 200 |
| POST | `/v1/entries/{id}/reversals` | chave de API | 201 |
| GET | `/v1/reversals` | token | 200 |

## Regras gerais

- **Base URL:** `https://<servidor>`. O app recebe o endereço na hora do build (`--dart-define=CAJUI_API_URL=...`). Tudo fica sob `/v1`, menos `/health`.
- **Formato:** corpo e resposta em JSON, com `content-type: application/json; charset=utf-8`.
- **Autenticação:** `Authorization: Bearer <token>`. Há dois tipos de acesso:
  - **chave de API:** uma senha longa e aleatória que fica gravada no servidor e embutida no app Android na hora do build. Quem a envia lê e escreve; ela não expira;
  - **sessão da web:** token devolvido por `POST /v1/auth/code`. Vale 30 dias e só lê e conversa com o assistente. Ao tentar escrever, recebe `403`.
- **Dinheiro:** centavos, sempre inteiros (`4590` = R$ 45,90). Número com casa decimal é recusado.
- **Datas:** dia em `AAAA-MM-DD`, mês em `AAAA-MM`, instante em ISO 8601 com fuso (`2026-10-28T12:00:00Z`). "Hoje" é o dia de Brasília.
- **Ids:** quem cria o item escolhe o `id`. Ele serve de chave de idempotência: reenviar o mesmo pedido não grava duas vezes.
- **Leitura estrita:** campo a mais, campo obrigatório ausente ou de tipo errado viram `400`. Texto opcional vazio é tratado como ausente.
- **Dois aparelhos:** no cadastro e no plano, vale a versão com `definedAt` mais novo. Se o servidor manter a versão que já tinha, responde `200` com `"kept": true`.
- **Tamanho do corpo:** até 64 KiB, ou 9 MiB no comprovante e 4 MiB no extrato. Acima disso, o servidor responde `413`.
- **Limite de taxa:** 120 pedidos por minuto por origem e 600 no total. Acima disso, responde `429` com `Retry-After`.
- **CORS:** só a origem da web de consulta é liberada. O `OPTIONS` dela responde `204`.
- **Rastreio:** toda resposta traz `x-request-ref`, que é o mesmo `ref` do corpo de erro.

## Modelos

**entry** (lançamento)

```json
{
  "id": "e-0001",
  "description": "Mercado do Bairro",
  "amountCents": 4590,
  "occurredOn": "2026-10-28",
  "categoryId": "c-mercado",
  "paymentLines": [
    { "paymentMethodId": "pm-pix", "kind": "pix", "amountCents": 4590 }
  ],
  "isExceptional": false
}
```

| Campo | Tipo | Regra |
|---|---|---|
| `id` | string | 1 a 64 caracteres, criado no aparelho |
| `description` | string | 1 a 200 caracteres |
| `amountCents` | int | maior que zero |
| `occurredOn` | string | data que existe e não está no futuro |
| `categoryId` | string | categoria cadastrada no servidor |
| `paymentLines` | lista | 1 a 20 linhas, que somam `amountCents` |
| `paymentLines[].kind` | string | `physicalCash`, `pix`, `debit`, `bankSlip`, `creditCard` ou `mealVoucher` |
| `isExceptional` | bool? | padrão `false` |
| `installments` | int? | 2 a 24, só com linha `creditCard` de um cartão cadastrado |
| `installmentAmountCents` | int? | valor da parcela quando há juros |
| `origin` | string? | `manual`, `share` ou `notification` |
| `revisedAt` | string? | instante da última correção |

Cartão de crédito é forma de pagamento, nunca categoria. O vale alimentação é outra moeda e só paga categorias marcadas com `voucherEligible`.

**category**

```json
{ "id": "c-mercado", "name": "Mercado", "block": "variable", "groupId": "g-casa", "voucherEligible": true, "definedAt": "2026-10-28T12:00:00Z" }
```

O campo `block` aceita `fixed`, `variable`, `debt` ou `subscription`. O `name` tem até 40 caracteres e não pode ser "cartão" nem "fatura".

**card**

```json
{ "id": "card-0001", "name": "Cartão de teste", "closingDay": 25, "dueDay": 5, "creditLimitCents": 300000, "skin": "pequi", "definedAt": "2026-10-28T12:00:00Z" }
```

`closingDay` e `dueDay` vão de 1 a 31. `creditLimitCents` pode ser `null`. O Cajui nunca guarda número de cartão.

**receipt** (recebimento)

```json
{ "id": "r-0001", "sourceId": "sal-0001", "tender": "cash", "amountCents": 100000, "receivedOn": "2026-10-05", "note": "Renda de exemplo" }
```

`tender` é `cash` ou `mealVoucher`, e os dois nunca se somam. Recebimento não é lançamento: não tem categoria.

**Erro**

Toda falha tem o mesmo formato. A API não manda frase: manda o código e os valores, e o app monta o texto a partir do catálogo de erros.

```json
{
  "error": {
    "code": "E-ENTRY-01",
    "class": "regra",
    "detail": { "amountCents": 4590, "linesTotalCents": 4000 },
    "ref": "a1b2c3",
    "retryAfterSeconds": null
  }
}
```

| Status | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | corpo fora do esquema |
| 401 | `E-AUTH-03` | token ausente, desconhecido ou vencido; código do autenticador errado |
| 403 | `E-AUTH-03` | sessão da web tentando escrever |
| 403 | `E-AI-03` | teto mensal de tokens da IA atingido |
| 404 | `E-REQ-02` | item inexistente ou id do caminho diferente do corpo |
| 413 | `E-REQ-04` | corpo acima do limite |
| 422 | `E-ENTRY-01..04`, `E-VOUCHER-02`, `E-CARD-01`, `E-CARD-02` | regra do domínio recusou |
| 429 | `E-RATE-01`, `E-AI-02` | limite de taxa do servidor ou da IA, com `Retry-After` |
| 500 | `E-SRV-01` | erro inesperado |
| 502 | `E-AI-04` | resposta da IA fora do esquema (extrato) |
| 503 | `E-AI-01`, `E-DATA-01` | IA fora do ar; registro de eventos não confere |

## Saúde

### GET /health

Diz se o servidor está no ar. É pública e não informa versão.

Resposta 200:

```json
{ "status": "ok" }
```

## Autenticação

### POST /v1/auth/code

Troca o código de 6 dígitos do app autenticador (TOTP) por um token de sessão da web, que só lê e conversa. Cada código vale uma vez. Depois de 5 erros seguidos, a rota fica fechada por 15 minutos.

Requisição:

```http
POST /v1/auth/code
Content-Type: application/json

{ "code": "123456" }
```

Resposta 200:

```json
{ "token": "<token-de-sessao>" }
```

Erros: `400` (corpo fora do formato) e `401 E-AUTH-03` (código errado, já usado ou porta fechada; a resposta é a mesma nos três casos).

## Leitura com IA

### POST /v1/receipts/classify

Recebe o texto lido de um comprovante (e até 3 fotos em base64) e devolve uma proposta de lançamento. Cada campo da proposta vem com o grau de confiança. Se a IA falhar, a rota continua respondendo `200`, usa só as regras locais e explica o motivo em `warnings`.

Requisição:

```http
POST /v1/receipts/classify
Authorization: Bearer <token>

{
  "text": "MERCADO DO BAIRRO\n28/10/2026\nTOTAL R$ 45,90\nPIX",
  "examples": [{ "merchant": "Mercado do Bairro", "categoryId": "c-mercado" }]
}
```

Resposta 200:

```json
{
  "documentKind": { "value": "purchase", "candidates": [], "confidence": "high", "source": "fixedRule" },
  "amountCents":  { "value": 4590, "candidates": [], "confidence": "high", "source": "fixedRule" },
  "occurredOn":   { "value": "2026-10-28", "candidates": [], "confidence": "high", "source": "fixedRule" },
  "categoryId":   { "value": "c-mercado", "candidates": [], "confidence": "high", "source": "learnedRule" },
  "paymentKind":  { "value": "pix", "candidates": [], "confidence": "high", "source": "fixedRule" },
  "merchant": "Mercado do Bairro",
  "description": "Mercado do Bairro",
  "installments": null,
  "warnings": []
}
```

Erros: `400` (sem `text` nem `images`, ou imagem fora do formato) e `413` (mais de 9 MiB).

### POST /v1/statements/read-part

Lê uma página de extrato por pedido; quem percorre as páginas é o celular. Só devolve as movimentações que passam na conferência do servidor:

- o valor está escrito na página;
- a data existe e não está no futuro;
- a categoria é uma das cadastradas;
- a palavra escrita na linha decide o tipo.

Também caem fora o cabeçalho de mês e a linha de total da página.

Requisição:

```http
POST /v1/statements/read-part
Authorization: Bearer <token>

{
  "lines": ["12/10 MERCADO DO BAIRRO 45,90", "13/10 PAGAMENTO DA FATURA 300,00"],
  "page": 1,
  "pageCount": 2,
  "period": "2026-10"
}
```

Resposta 200:

```json
{
  "movements": [
    { "line": 1, "day": 12, "month": 10, "description": "Mercado do Bairro", "amountCents": 4590,
      "kind": "expense", "categoryId": "c-mercado", "confidence": "high", "paymentKind": "pix" },
    { "line": 2, "day": 13, "month": 10, "description": "Pagamento da fatura", "amountCents": 30000,
      "kind": "cardPayment", "categoryId": null, "confidence": "high", "paymentKind": null }
  ],
  "period": "2026-10"
}
```

O campo `kind` pode ser `expense`, `income`, `cardPayment` ou `ownTransfer`. Quando a página foi lida só em parte, a resposta traz `"partial": true`.

Erros: `400`, `403 E-AI-03`, `413`, `429 E-AI-02`, `502 E-AI-04` e `503 E-AI-01`.

### POST /v1/assistant/ask

Faz uma pergunta à assistente (Juju). O servidor monta o resumo do mês com os dados que ele mesmo guarda. Com a chave de API, a assistente também pode lançar, cancelar, registrar ou desfazer um recebimento e abater dívida. Ela só cita valores que vieram dos dados ou da pessoa; se insistir em outro valor, a resposta passa a ter formato fixo (`fallback: true`).

Requisição:

```http
POST /v1/assistant/ask
Authorization: Bearer <token>
X-Cajui-Device: aparelho-teste

{ "message": "Quanto gastei no mercado este mês?" }
```

Resposta 200:

```json
{
  "text": "Lancei R$ 45,90 em Mercado do Bairro.",
  "outOfScope": false,
  "fallback": false,
  "sources": [],
  "actions": [{ "kind": "recorded", "id": "e-0002", "label": "Mercado do Bairro", "amountCents": 4590 }]
}
```

`actions[].kind` pode ser `recorded`, `cancelled`, `income` ou `paidDown`. A lista permite que a tela ofereça "Desfazer".

Erros: `400` (`message` vazia ou com mais de 1000 caracteres), `403 E-AI-03`, `429 E-AI-02` e `503 E-AI-01`.

## Sincronização

### GET /v1/head

É a pergunta mais barata: os aparelhos a fazem a cada 20 s para saber se há algo novo.

Resposta 200:

```json
{ "seq": 42, "ledgerSeq": 40 }
```

## Cadastro

### GET /v1/categories · GET /v1/cards

Respostas 200: `{ "categories": [category] }` e `{ "cards": [card] }`.

### POST /v1/categories · POST /v1/cards

Cria ou atualiza o item com o mesmo `id`; o corpo é o próprio modelo. Prevalece a versão com `definedAt` mais novo.

Resposta 201:

```json
{ "id": "c-mercado", "seq": 12 }
```

Resposta 200, quando a versão do servidor é a mesma ou é mais nova:

```json
{ "id": "c-mercado", "kept": true }
```

Erros: `400`, `422 E-CARD-02` (categoria com nome de cartão ou fatura) e `422 E-CARD-01` (dia de fechamento ou vencimento fora de 1 a 31).

## Recebimentos e vale

### GET /v1/income

Devolve os recebimentos em vigor, os acertos do vale e o saldo do vale, que o servidor recalcula.

```json
{
  "receipts": [receipt],
  "voucherAdjustments": [{ "id": "aj-0001", "adjustmentCents": -500, "on": "2026-10-20", "reason": "Acerto de exemplo" }],
  "voucherBalanceCents": 12000
}
```

### POST /v1/income

O corpo é um `receipt`, com `amountCents` maior que zero. Resposta 201: `{ "id": "r-0001", "seq": 14 }`.

### POST /v1/voucher/adjustments

Acerta o saldo do vale para o valor real do cartão. O valor pode ser negativo, e o `reason` tem de 1 a 120 caracteres.

```json
{ "id": "aj-0001", "adjustmentCents": -500, "on": "2026-10-20", "reason": "Acerto de exemplo" }
```

Resposta 201: `{ "id": "aj-0001", "seq": 15 }`.

## Fatos

### GET /v1/facts · POST /v1/facts

O servidor guarda e devolve fatos para que os dois celulares mostrem a mesma coisa.

```json
{
  "id": "f-0001",
  "type": "statement.settled",
  "payload": { "id": "s-0001", "cardId": "card-0001", "dueMonth": "2026-11", "amountCents": 10000, "paidOn": "2026-10-30" }
}
```

| `type` | O que é |
|---|---|
| `statement.settled` | fatura de cartão paga |
| `debt.defined` | dívida cadastrada |
| `debt.installment-paid` | parcela de dívida paga |
| `debt.ordered` | ordem de quitação das dívidas |
| `month.closed` | mês fechado (aceito, mas o app não grava mais) |
| `budget.defined` | plano da planilha |
| `household.named` | nomes da casa |
| `merchant.learned` | estabelecimento ligado a uma categoria |
| `income.cancelled` | recebimento desfeito (sai da lista e dos números) |

Respostas: o `GET` devolve 200 com `{ "facts": [...] }`; o `POST` devolve 201 com `{ "id": "f-0001", "seq": 16 }`. Erros: `400` (tipo desconhecido ou `payload` fora do formato do tipo).

## Plano do mês

### GET /v1/plan · POST /v1/plan

O plano é enviado inteiro, de uma vez. Sem plano definido, o `GET` devolve o plano vazio.

```json
{
  "cashIncomeCents": 100000,
  "debtInstallmentsCents": 0,
  "definedAt": "2026-10-28T12:00:00Z",
  "fixed": [{ "id": "fx-0001", "name": "Internet de teste", "amountCents": 9990, "dueDay": 10, "categoryId": "c-casa", "paymentMethodId": "pm-pix" }],
  "variables": [{ "categoryId": "c-mercado", "minCents": 20000, "maxCents": 40000, "voucherEligible": true }]
}
```

O `POST` responde **200** (não 201) com `{ "seq": 17 }`. Erros: `400` (valor negativo, `dueDay` fora de 1 a 31 ou mínimo maior que o máximo).

## Lançamentos

### GET /v1/entries

Lista os lançamentos completos e os ids cancelados. O parâmetro opcional `month=AAAA-MM` filtra pelo mês; se o mês não existir, a lista vem vazia.

```http
GET /v1/entries?month=2026-10
Authorization: Bearer <token>
```

Resposta 200:

```json
{ "entries": [entry], "cancelledIds": [] }
```

### POST /v1/entries

Cria um lançamento. O servidor confere de novo as regras do domínio. O corpo é um `entry`.

Resposta 201:

```json
{ "id": "e-0001", "seq": 18 }
```

Se o `id` já existe, a resposta é `201` com o `seq` original e nada muda (para corrigir, use `PUT`). Se o `id` foi cancelado, a resposta é `200` com `"cancelled": true` e o lançamento não volta.

| Status | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | corpo fora do formato, `kind` desconhecido, parcelamento sem cartão |
| 404 | `E-REQ-02` | categoria desconhecida |
| 422 | `E-ENTRY-01` | as linhas não somam o valor |
| 422 | `E-ENTRY-02` | data no futuro |
| 422 | `E-ENTRY-03` | valor zero ou negativo |
| 422 | `E-VOUCHER-02` | vale alimentação numa categoria que ele não paga |

### PUT /v1/entries/{id}

Corrige um lançamento. O corpo é igual ao do `POST`, e o `id` do caminho precisa ser igual ao do corpo. Nada é reescrito: a versão nova toma o lugar da antiga. Entre duas correções, prevalece a de `revisedAt` mais novo.

Respostas 200: `{ "id": "e-0001" }`; `{ "id": "e-0001", "kept": true }` quando já existe uma versão mais nova; e `{ "id": "e-0001", "cancelled": true }` quando o lançamento foi cancelado. Erros: os mesmos do `POST`, e `404` quando os ids diferem.

### DELETE /v1/entries/{id}

Cancela o lançamento. Ele sai de todas as telas, mas continua no registro de eventos.

Resposta 200: `{ "id": "e-0001" }`. Cancelar de novo também responde 200, com `"cancelled": true`. Erro: `404` quando o lançamento nunca existiu.

### POST /v1/entries/{id}/reversals

Registra um estorno: o dinheiro de uma compra que voltou, pela mesma forma de pagamento.

```json
{ "id": "rv-0001", "entryId": "e-0001", "paymentMethodId": "pm-pix", "amountCents": 1000, "occurredOn": "2026-10-29" }
```

Resposta 201: `{ "id": "rv-0001" }`. Erros: `404` (lançamento desconhecido ou `entryId` diferente do caminho) e `422 E-ENTRY-04` (estorno maior que o que resta da linha).

### GET /v1/reversals

```json
{ "reversals": [{ "id": "rv-0001", "entryId": "e-0001", "paymentMethodId": "pm-pix", "amountCents": 1000, "occurredOn": "2026-10-29" }] }
```
