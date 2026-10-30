# API HTTP do Cajui

Documentação das rotas do servidor do Cajui, com os requests e os responses de cada uma. É um entregável da disciplina de Dispositivos Móveis II.

Tudo aqui foi escrito a partir da **leitura do código**: o servidor (`server/`) e o contrato que o app e o servidor compartilham (`packages/api_contract/`). Nenhuma rota foi chamada pela rede para escrever este texto. O que o código não deixa claro está marcado como "não verificado" (lista completa na seção 9).

Todos os valores de exemplo são **fictícios** (estabelecimento "Mercado do Bairro", ids como `e-0001`, valores em centavos como `4590`). Nenhum endereço, chave, token ou segredo real aparece neste documento.

---

## 1. Visão geral

| Item | Como é |
|---|---|
| Base | `https://<servidor>`. O endereço de produção não é publicado aqui. |
| Versão | Tudo fica sob `/v1`. A única exceção é `GET /health`. |
| Formato | JSON em UTF-8. As respostas saem com `content-type: application/json; charset=utf-8`. O servidor lê o corpo como JSON e não confere o cabeçalho `Content-Type` do pedido. |
| Dinheiro | **Centavos, sempre inteiros.** Os campos terminam em `Cents`: `4590` é R$ 45,90. Número com casa decimal (`45.90`) é recusado. |
| Datas | Dia: `AAAA-MM-DD` (sem hora). Mês: `AAAA-MM`. Instante (carimbo de versão): ISO 8601 **com fuso**, como `2026-10-28T12:00:00Z`. O servidor devolve instantes em UTC. |
| "Hoje" | O servidor usa o dia de Brasília (UTC menos 3 horas) para decidir o que é "data futura". |
| Ids | Quem cria o item escolhe o `id` (até 64 caracteres; fatos aceitam até 96). Ele é a chave de idempotência. |
| Autenticação | Cabeçalho `Authorization: Bearer <token>`. Há duas formas de obter acesso (seção 4). |
| Limite de taxa | 120 pedidos por minuto por origem e 600 por minuto no total (valores padrão do código). Acima disso: `429` com `E-RATE-01`. |
| CORS | Existe, e libera uma única origem de navegador: a da web de consulta. Serve para a web ler as respostas. O app Android não manda `Origin` e não é afetado. |
| Rastreio | Toda resposta traz o cabeçalho `x-request-ref`. O mesmo valor vai no campo `ref` do corpo de erro. |

---

## 2. Quadro-resumo das rotas

Legenda de autenticação:

- **Nenhuma**: a rota responde sem token.
- **Token**: serve a chave da casa **ou** a sessão aberta pelo código do autenticador.
- **Chave da casa**: só a chave da casa escreve. A sessão do código recebe `403 E-AUTH-03`.

| # | Método | Caminho | Autenticação | O que faz |
|---|---|---|---|---|
| 1 | GET | `/health` | Nenhuma | Diz se o servidor está de pé. |
| 2 | POST | `/v1/auth/code` | Nenhuma | Troca o código de 6 dígitos do autenticador por um token de sessão (só leitura e conversa). |
| 3 | POST | `/v1/receipts/classify` | Chave da casa | Lê o texto (e as fotos) de um comprovante e devolve uma proposta de lançamento. |
| 4 | POST | `/v1/statements/read-part` | Chave da casa | Lê uma página de extrato e devolve as movimentações conferidas. |
| 5 | POST | `/v1/assistant/ask` | Token | Faz uma pergunta ao assistente (Juju). |
| 6 | GET | `/v1/head` | Token | Devolve o topo do registro de eventos (para saber se há novidade). |
| 7 | GET | `/v1/categories` | Token | Lista as categorias. |
| 8 | POST | `/v1/categories` | Chave da casa | Cria ou atualiza uma categoria. |
| 9 | GET | `/v1/cards` | Token | Lista os cartões de crédito. |
| 10 | POST | `/v1/cards` | Chave da casa | Cria ou atualiza um cartão. |
| 11 | GET | `/v1/income` | Token | Lista recebimentos, acertos do vale e o saldo do vale. |
| 12 | POST | `/v1/income` | Chave da casa | Registra um recebimento. |
| 13 | POST | `/v1/voucher/adjustments` | Chave da casa | Registra um acerto do saldo do vale. |
| 14 | GET | `/v1/facts` | Token | Lista os fatos que o servidor só guarda e devolve. |
| 15 | POST | `/v1/facts` | Chave da casa | Guarda um fato (fatura paga, dívida, plano da planilha etc.). |
| 16 | GET | `/v1/plan` | Token | Lê o plano do mês. |
| 17 | POST | `/v1/plan` | Chave da casa | Define o plano do mês, inteiro. |
| 18 | GET | `/v1/entries` | Token | Lista os lançamentos (opcionalmente de um mês). |
| 19 | POST | `/v1/entries` | Chave da casa | Cria um lançamento. |
| 20 | PUT | `/v1/entries/{id}` | Chave da casa | Corrige um lançamento. |
| 21 | DELETE | `/v1/entries/{id}` | Chave da casa | Cancela um lançamento. |
| 22 | POST | `/v1/entries/{id}/reversals` | Chave da casa | Registra um estorno de uma compra. |
| 23 | GET | `/v1/reversals` | Token | Lista os estornos. |

A ordem acima é a do código (`server/lib/src/app.dart`): `health`, `auth`, `receipts`, `statements`, `assistant`, `head`, cadastro, entradas, fatos e livro.

---

## 3. Convenções que valem para todas as rotas

### 3.1 Leitura estrita do corpo

O servidor trata todo corpo como não confiável. A leitura é feita campo a campo (`JsonReader`, em `packages/api_contract/lib/src/json_reader.dart`):

| Situação | O que acontece |
|---|---|
| Corpo que não é JSON válido, está vazio, ou cuja raiz não é um objeto (por exemplo, uma lista) | `400` com `E-REQ-01` |
| **Campo a mais**, que a rota não conhece | `400` com `E-REQ-01` |
| Campo **obrigatório** ausente, `null` ou de tipo errado (texto onde se espera inteiro, inteiro onde se espera texto etc.) | `400` com `E-REQ-01` |
| Texto obrigatório vazio (depois de tirar os espaços das pontas) ou acima do limite de caracteres | `400` com `E-REQ-01` |
| Texto **opcional** vazio ou acima do limite | Tratado como **ausente**, sem erro |
| Instante opcional (`definedAt`, `revisedAt`) sem fuso ou ilegível | Tratado como **ausente**, sem erro |
| Lista obrigatória vazia ou com itens demais | `400` com `E-REQ-01` |
| Lista opcional ausente | Lista vazia |
| Data que não existe no calendário (`2026-02-30`) | `400` com `E-REQ-01` |
| Valor de enumeração desconhecido (forma de pagamento, bloco, tipo...) | `400` com `E-REQ-01` |

Nas tabelas de campos abaixo, "Obrigatório: sim" segue essa regra. Os limites de tamanho são em caracteres.

### 3.2 Idempotência

Reenviar o mesmo pedido (a resposta se perdeu, a fila offline tentou de novo) **não cria um segundo fato**. O registro de eventos guarda cada evento com uma chave e, se a chave já existe, devolve o evento que já estava lá (`packages/persistence/lib/src/event_store.dart`).

| Rota | De onde vem a chave |
|---|---|
| `POST /v1/entries` | O `id` do lançamento. Reenviar o mesmo `id` com conteúdo diferente **não altera** o lançamento: use `PUT`. |
| `PUT /v1/entries/{id}` | O `id` mais uma impressão do conteúdo: a mesma correção não repete, uma correção diferente grava. |
| `POST /v1/categories`, `POST /v1/cards`, `POST /v1/plan` | Uma impressão do conteúdo. |
| `POST /v1/income` | O `id` do recebimento. |
| `POST /v1/voucher/adjustments` | O `id` do acerto. |
| `POST /v1/facts` | O `id` do fato. |
| `POST /v1/entries/{id}/reversals` | O `id` do estorno. |

### 3.3 Quem vence entre dois aparelhos

Cadastro e plano levam um carimbo `definedAt`. A versão **mais nova** vale, não a que chegou por último. Quando o servidor mantém a versão que já tinha, responde `200` com `"kept": true` e não grava nada. Carimbo mais de 10 minutos à frente do relógio do servidor é recusado com `400 E-REQ-01`.

### 3.4 Tamanho do corpo

| Rota | Teto do corpo |
|---|---|
| Padrão | 64 KiB |
| `POST /v1/receipts/classify` | 9 MiB |
| `POST /v1/statements/read-part` | 4 MiB |

Acima do teto: `413` com `E-REQ-04`. O servidor olha o tamanho declarado antes de ler o corpo.

---

## 4. Autenticação

Toda rota exige `Authorization: Bearer <token>`, **exceto** `GET /health` e `POST /v1/auth/code`. O cabeçalho precisa começar exatamente com `Bearer ` (B maiúsculo, um espaço).

O código implementa duas formas de obter acesso. Nenhuma das duas é descrita aqui com valores reais.

### 4.1 Chave da casa (acesso completo)

- É **um segredo só**, o mesmo em todos os aparelhos do dono, configurado no servidor.
- O app Android leva a chave de fábrica; a web pede que a pessoa a digite uma vez.
- O servidor guarda apenas o **hash** da chave e compara em tempo constante.
- **Não expira.** Dá acesso de leitura **e** escrita (escopo `device`).
- O aparelho pode mandar o cabeçalho opcional `X-Cajui-Device: <nome>` (letras, números, `_` e `-`, de 1 a 64 caracteres). Ele **não prova nada**: serve só para cada aparelho ter a sua própria conversa com o assistente. Sem ele, vale o nome `casa`.

### 4.2 Código do autenticador (sessão da web, só leitura)

- A pessoa digita o código de 6 dígitos de um app autenticador (padrão TOTP, RFC 6238, passo de 30 segundos).
- `POST /v1/auth/code` troca o código por um **token opaco** (aleatório, sem significado próprio). O servidor guarda só o hash do token.
- O token vale **30 dias** e tem escopo `webReadOnly`: pode fazer `GET` e `POST /v1/assistant/ask`. Qualquer outra escrita recebe `403 E-AUTH-03`.
- Cada passo de 30 segundos vale **uma vez** (o código visto por cima do ombro não abre uma segunda sessão). O servidor tolera um passo antes e um depois, por causa de relógios de celular.
- **Trava:** 5 códigos errados seguidos fecham a porta por 15 minutos. Nesse período, até o código certo é recusado.
- As sessões ficam gravadas no registro (só o hash) e voltam depois de um reinício, enquanto o segredo do autenticador não for trocado.

### 4.3 O que o 401 devolve

Sem cabeçalho, com token desconhecido ou vencido: `401` com `E-AUTH-03`, sempre igual. Sessão só de leitura tentando escrever: `403` com `E-AUTH-03`. O servidor não explica o motivo (é de propósito).

```http
HTTP/1.1 401 Unauthorized
content-type: application/json; charset=utf-8
x-request-ref: a1b2c3

{"error":{"code":"E-AUTH-03","class":"segurança","detail":{},"ref":"a1b2c3","retryAfterSeconds":null}}
```

Fonte: `server/lib/src/auth/authenticate.dart`, `session_book.dart`, `session_scope.dart`, `household_key.dart`, `totp.dart`, `code_routes.dart`.

---

## 5. Limite de taxa e CORS

### 5.1 Ordem dos filtros

Cada pedido passa, nesta ordem, por (`server/lib/src/app.dart`):

1. Identificador do pedido (`ref`).
2. Registro de acesso (só método, caminho sem a consulta, status e duração; nunca corpo nem valor).
3. CORS.
4. Barreira de erros (nenhuma exceção chega ao cliente como texto livre).
5. Limite de taxa.
6. Autenticação.
7. A rota.

O limite de taxa vem **antes** da autenticação, então tentar token errado também gasta cota. `GET /health` também conta.

### 5.2 Limite de taxa

- Janela fixa de 1 minuto. Valores padrão do código: 120 por origem e 600 no total.
- A "origem" é o endereço de quem conecta. O cabeçalho `X-Forwarded-For` só é considerado quando quem conecta é a própria máquina (o proxy reverso local). Vindo de fora, é ignorado.
- Ao passar do limite: `429`, cabeçalho `Retry-After: <segundos>` e corpo `E-RATE-01` com `detail.seconds` e `retryAfterSeconds`.

```http
HTTP/1.1 429 Too Many Requests
retry-after: 12
content-type: application/json; charset=utf-8

{"error":{"code":"E-RATE-01","class":"limite","detail":{"seconds":12},"ref":"a1b2c3","retryAfterSeconds":12}}
```

Fonte: `server/lib/src/http/rate_limiter.dart`, `middlewares.dart`.

### 5.3 CORS

- Só a **origem configurada** para a web de consulta recebe os cabeçalhos CORS. Qualquer outra origem passa sem cabeçalho nenhum, e o navegador dela bloqueia sozinho.
- O `OPTIONS` (pergunta prévia do navegador) dessa origem recebe `204`, com `access-control-allow-methods: GET, POST, PUT, DELETE`, `access-control-allow-headers: authorization, content-type, x-cajui-device` e `access-control-max-age: 600`.
- O `OPTIONS` é respondido **antes** do limite de taxa e da autenticação.
- Não há cookie: a sessão web é um token em memória.

Fonte: `server/lib/src/http/cors.dart`.

---

## 6. Erros

### 6.1 Corpo padrão

Toda resposta de erro tem este corpo, e nenhum outro:

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

| Campo | Tipo | Significado |
|---|---|---|
| `code` | texto | Código do catálogo (`E-AAAA-NN`). |
| `class` | texto | Classe do erro: `validação`, `regra`, `captura`, `rede`, `sincronização`, `ia`, `limite`, `segurança`, `dados`, `aparelho`, `servidor` ou `app`. |
| `detail` | objeto | Só os valores que o texto do erro usa (por exemplo, centavos). Nunca texto livre, nunca pilha de execução. Pode vir vazio (`{}`). |
| `ref` | texto | Identificador curto da ocorrência (6 caracteres hexadecimais). Liga o erro visto ao registro do servidor. |
| `retryAfterSeconds` | inteiro ou `null` | Em quantos segundos tentar de novo. Vem preenchido em `E-RATE-01`, `E-AI-02` e outros casos de espera; vem junto do cabeçalho `Retry-After`. |

**A API manda o código e os valores; quem escreve a frase é o app**, a partir do catálogo (`docs/spec/error-catalog.md`). Por isso o corpo não tem mensagem em texto.

### 6.2 Erros que podem aparecer em qualquer rota

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do esquema (seção 3.1). Só em rotas com corpo. |
| 401 | `E-AUTH-03` | Token ausente, desconhecido ou vencido. |
| 403 | `E-AUTH-03` | Sessão só de leitura tentando escrever. |
| 413 | `E-REQ-04` | Corpo acima do teto (seção 3.4). |
| 429 | `E-RATE-01` | Limite de taxa. |
| 500 | `E-SRV-01` | Qualquer falha interna não prevista. O corpo nunca traz o motivo. |
| 503 | `E-DATA-01` | A cadeia do registro de eventos não confere. `detail.seq` diz a partir de qual evento. |

Nas seções de cada rota, estão listados só os erros **específicos** dela.

### 6.3 Tabela dos códigos do catálogo

A coluna "HTTP" é o status com que a API devolve o código (`packages/api_contract/lib/src/error_code.dart`); "só no app" quer dizer que o código nasce no aparelho. A última coluna diz se alguma rota lida **emite** o código hoje.

| Código | Classe | HTTP | Significado | Emitido pelas rotas? |
|---|---|---|---|---|
| `E-ENTRY-01` | regra | 422 | A soma das linhas de pagamento difere do valor do lançamento. | Sim: lançamentos |
| `E-ENTRY-02` | validação | 422 | Data da compra no futuro. | Sim: lançamentos |
| `E-ENTRY-03` | validação | 422 | Valor zero ou negativo (do lançamento ou de uma linha). | Sim: lançamentos |
| `E-ENTRY-04` | regra | 422 | Estorno maior que o que resta da linha do lançamento. | Sim: estornos |
| `E-VOUCHER-01` | regra | 422 | Pagamento no vale maior que o saldo. | Não nas rotas lidas |
| `E-VOUCHER-02` | regra | 422 | Categoria não elegível ao vale. | Sim: lançamentos |
| `E-CARD-01` | validação | 422 | Dia de fechamento ou de vencimento fora de 1 a 31. | Não (ver nota na seção 7.10) |
| `E-CARD-02` | regra | 422 | Categoria com nome que representa cartão ou fatura. | Sim: categorias |
| `E-BUDG-01` | validação | 422 | Faixa com mínimo maior que o máximo. | Não (no plano vira `E-REQ-01`) |
| `E-BUDG-02` | regra | 422 | Fechar um mês que ainda não terminou. | Não nas rotas lidas |
| `E-BUDG-03` | regra | 422 | Ajuste abaixo do mínimo da faixa. | Não nas rotas lidas |
| `E-BUDG-04` | regra | 422 | Remanejamento maior que a folga da origem. | Não nas rotas lidas |
| `E-DEBT-01` | validação | 422 | Parcelas pagas maior que o total de parcelas. | Não (num fato vira `E-REQ-01`) |
| `E-CAPT-01` | captura | só no app | A leitura não achou texto. | Não |
| `E-CAPT-02` | captura | só no app | Tipo de arquivo que o app não lê. | Não |
| `E-CAPT-03` | captura | só no app | Arquivo acima de 15 MB. | Não |
| `E-CAPT-04` | captura | só no app | PDF protegido por senha. | Não |
| `E-CAPT-05` | captura | só no app | O app de origem não liberou a leitura. | Não |
| `E-CAPT-06` | captura | só no app | Sem espaço para guardar o arquivo. | Não |
| `E-CAPT-07` | captura | só no app | Uma página passou de 10 s na leitura. | Não |
| `E-NET-01` | rede | só no app | Sem conexão numa ação que só existe com rede. | Não |
| `E-NET-02` | rede | só no app | O servidor não respondeu em 10 s. | Não |
| `E-SYNC-01` | sincronização | 422 | Um comando da fila offline foi rejeitado pelo servidor. | Não nas rotas lidas |
| `E-SYNC-02` | sincronização | 409 | Conflito de escrita: outro comando gravou primeiro. | Não nas rotas lidas |
| `E-AI-01` | ia | 503 | A IA não respondeu a tempo, ou está fora do ar (ou o servidor está sem a credencial da IA). | Sim: IA |
| `E-AI-02` | ia | 429 | O serviço de IA limitou as requisições. Vem com `Retry-After`. | Sim: assistente e extrato |
| `E-AI-03` | ia | 403 | Teto mensal de tokens da IA atingido. | Sim: assistente e extrato; em comprovante, como aviso |
| `E-AI-04` | ia | 200 (502 no extrato) | Resposta da IA fora do esquema. | Sim: aviso no comprovante; erro `502` no extrato |
| `E-AI-05` | ia | 200 | Página do extrato lida só em parte. | Não como erro: a resposta traz `"partial": true` |
| `E-AUTH-01` | segurança | só no app | Biometria indisponível no aparelho. | Não |
| `E-AUTH-02` | segurança | só no app | Biometria não reconhecida. | Não |
| `E-AUTH-03` | segurança | 401 (403 para sessão só de leitura) | Sessão, chave ou código recusado. | Sim |
| `E-AUTH-04` | segurança | 401 | Código do autenticador errado, já usado ou entrada em espera. | Não: `POST /v1/auth/code` responde `E-AUTH-03` |
| `E-RATE-01` | limite | 429 | Limite de taxa do servidor. | Sim |
| `E-DATA-01` | dados | 503 | Cadeia do registro de eventos quebrada. | Sim |
| `E-DATA-02` | dados | 503 | Resumo guardado e registro de eventos discordam. | Não nas rotas lidas |
| `E-DATA-03` | dados | só no app | O registro do aparelho não abre. | Não |
| `E-STORAGE-01` | aparelho | só no app | Armazenamento do aparelho cheio. | Não |
| `E-REQ-01` | servidor | 400 | Corpo da requisição fora do esquema. | Sim |
| `E-REQ-02` | servidor | 404 | O item pedido não existe (lançamento, categoria desconhecida, id do caminho diferente do corpo). | Sim |
| `E-REQ-03` | servidor | 426 | App antigo demais para a API. | Não: nenhuma rota lida confere versão do app |
| `E-REQ-04` | servidor | 413 | Corpo acima do limite da API. | Sim |
| `E-SRV-01` | servidor | 500 | Erro interno do servidor. | Sim |
| `E-SRV-02` | servidor | 503 | Servidor reiniciando ou em atualização. | Não nas rotas lidas |
| `E-SRV-03` | servidor | 200 | Último backup há mais de 36 horas. | Não nas rotas lidas |
| `E-WEB-01` | app | só no app | A web não desenhou o primeiro quadro em 10 s. | Não |
| `E-APP-01` | app | só no app | Exceção não prevista dentro do app. | Não |

---

## 7. Rotas

### 7.1 `GET /health`

**Para que serve:** responde "estou de pé" e nada mais. É o que o deploy e um vigia de fora perguntam. Não diz versão, não diz se a IA está ligada e não diz quantos lançamentos existem.

**Autenticação:** nenhuma. Passa pelo limite de taxa.

**Parâmetros:** nenhum.

**Request**

```http
GET /health HTTP/1.1
Host: <servidor>
```

**Response de sucesso**

```http
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8

{"status":"ok"}
```

**Erros possíveis:** `429 E-RATE-01`, `500 E-SRV-01`.

**Fonte:** `server/lib/src/app.dart` (método `_health`); isenção de autenticação em `server/lib/src/auth/authenticate.dart`.

---

### 7.2 `POST /v1/auth/code`

**Para que serve:** a web de consulta troca o código de 6 dígitos do autenticador por um token de sessão. A sessão **só lê e conversa** (seção 4.2).

**Autenticação:** nenhuma (é a rota de quem ainda não entrou). Por isso é a única com trava de tentativas.

**Parâmetros:** nenhum de caminho nem de consulta.

**Request**

```http
POST /v1/auth/code HTTP/1.1
Host: <servidor>
Content-Type: application/json

{"code":"123456"}
```

(O código `123456` é só um exemplo fictício.)

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `code` | texto | sim | De 1 a 8 caracteres. Para ser aceito, precisa ter exatamente 6 dígitos e ser o código válido do momento. Campo a mais no objeto: `400`. |

**Response de sucesso**

```http
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8

{"token":"<token-de-sessao>"}
```

`<token-de-sessao>` é um valor aleatório e opaco; vale 30 dias. Use-o em `Authorization: Bearer <token>`.

**Erros possíveis**

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato (campo `code` ausente, não é texto, vazio, com mais de 8 caracteres, ou campo a mais). |
| 401 | `E-AUTH-03` | Código errado, código já usado, porta fechada pelas 5 falhas seguidas, ou servidor sem o segredo do autenticador. A resposta é a mesma nos quatro casos. |
| 429 | `E-RATE-01` | Limite de taxa. |

**Fonte:** `server/lib/src/auth/code_routes.dart`.

---

### 7.3 `POST /v1/receipts/classify`

**Para que serve:** recebe o texto que o celular leu de um comprovante (e, se houver, até 3 fotos) e devolve uma **proposta** de lançamento: valor, data, categoria, forma de pagamento e o que ficou em dúvida.

**Autenticação:** chave da casa. Sessão da web só de leitura recebe `403`.

**Parâmetros:** nenhum de caminho nem de consulta.

**Request**

```http
POST /v1/receipts/classify HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "text": "MERCADO DO BAIRRO\n28/10/2026\nTOTAL R$ 45,90\nPIX",
  "examples": [
    { "merchant": "Mercado do Bairro", "categoryId": "c-mercado" }
  ]
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `text` | texto | não* | O texto lido no celular. De 1 a 60000 caracteres; vazio ou maior que isso é tratado como ausente. |
| `images` | lista de textos | não* | Até 3 imagens em **base64**. Cada uma, depois de decodificada, tem até 2 MiB e precisa ser JPEG, PNG ou WebP (conferido pelos primeiros bytes, nunca pelo que o app declarou). Lista com mais de 3 itens, item que não é texto ou imagem fora do formato: `400`. |
| `examples` | lista de objetos | não | O que a pessoa já corrigiu. Cada item: `merchant` (texto, até 80) e `categoryId` (texto, até 64), ambos obrigatórios no item. Valem os **20 últimos**; os anteriores são descartados sem erro. Item com categoria que o servidor não conhece é ignorado. |

\* É preciso mandar `text` **ou** `images` (ou os dois). Sem nenhum dos dois: `400 E-REQ-01`. Campo a mais: `400`.

**Response de sucesso (`200`)**

A proposta. Cada campo "propostos" é um objeto com a **zona de confiança** junto.

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

(Os valores de `confidence` e `source` do exemplo são ilustrativos; o que importa é o formato.)

| Campo da resposta | Tipo | Observação |
|---|---|---|
| `documentKind`, `amountCents`, `occurredOn`, `categoryId`, `paymentKind` | objeto | Cada um tem `value` (o valor resolvido, ou `null`), `candidates` (opções, quando ficou em dúvida entre duas ou três), `confidence` (`high`, `medium` ou `low`) e `source` (`learnedRule`, `fixedRule`, `ai` ou `none`). Campo em dúvida vem com `value: null` e `candidates` preenchido. |
| `documentKind.value` | texto | `purchase`, `statementPayment`, `incomeReceipt`, `ownTransfer` ou `statement`. |
| `paymentKind.value` | texto | `physicalCash`, `pix`, `debit`, `bankSlip`, `creditCard` ou `mealVoucher`. |
| `merchant`, `description` | texto ou `null` | Estabelecimento lido e descrição sugerida. |
| `installments` | inteiro ou `null` | Número de parcelas, quando o texto fala em parcelas. |
| `warnings` | lista de textos | Códigos do catálogo que explicam por que a IA **não** participou: `E-AI-01`, `E-AI-03` ou `E-AI-04`. A proposta continua válida. |
| `lines` | lista | Só aparece quando o documento é um extrato. Cada linha: `occurredOn`, `description`, `amountCents`, `kind`, `categoryId`, `paymentKind` e, se for o caso, `doubtful: true`. |

**O que a resposta garante**

- É **sempre uma proposta válida**, com `200`. Se a IA estiver fora do ar, sem orçamento de tokens ou devolver algo fora do esquema, o servidor usa só as regras locais e explica em `warnings`. A captura nunca para por causa da IA.
- A resposta da IA só entra depois de validada contra um esquema fechado: campo desconhecido ou de tipo errado descarta a resposta inteira (`E-AI-04`); valor fora do permitido é descartado sozinho.
  - A categoria é, obrigatoriamente, **uma das categorias cadastradas no servidor**.
  - O valor é inteiro, positivo e de no máximo R$ 1.000.000,00. Sem foto, só vale se estiver escrito no texto.
  - A data não pode estar no futuro; vinda de foto, não pode ter mais de 730 dias.
  - A descrição passa por um filtro de "cara de nome de compra".
  - Parcelas: de 2 a 48.
- O servidor **mascara dados pessoais** do texto antes de enviá-lo à IA, mesmo que o app já tenha mascarado.
- Com foto, a IA é sempre consultada; só com texto, ela fica de fora quando a regra que a própria pessoa ensinou já resolveu a categoria.
- O corpo do pedido não vai para o registro de acesso. O uso da IA grava só números (tokens), nunca o pedido nem a resposta.
- Respostas já pagas ficam em cache (por um resumo do conteúdo), e repetir o mesmo comprovante não gasta de novo.

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Nem `text` nem `images`; `images` com mais de 3 itens, fora de base64 ou fora do formato de imagem; `examples` fora do formato; campo a mais. |
| 413 | `E-REQ-04` | Corpo acima de 9 MiB. |

Falhas da IA **não** viram erro HTTP nesta rota: viram `warnings` (veja acima).

**Fonte:** `server/lib/src/ai/receipt_routes.dart`; classificador em `server/lib/src/ai/ai_receipt_classifier.dart`; esquema validado em `ai_suggestion.dart`; formato da resposta em `packages/api_contract/lib/src/proposal_codec.dart`.

---

### 7.4 `POST /v1/statements/read-part`

**Para que serve:** lê **uma página** de extrato por pedido e devolve as movimentações que passaram na conferência do servidor. Quem faz o laço página a página é o celular ("Lendo a página 3 de 7"). A sessão da web, que só consulta, não lê extrato.

**Autenticação:** chave da casa.

**Parâmetros:** nenhum de caminho nem de consulta.

**Request**

```http
POST /v1/statements/read-part HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "lines": [
    "12/10 MERCADO DO BAIRRO 45,90",
    "13/10 PADARIA DO EXEMPLO 12,00"
  ],
  "page": 1,
  "pageCount": 2,
  "period": "2026-10",
  "examples": [
    { "merchant": "Mercado do Bairro", "categoryId": "c-mercado" }
  ]
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `lines` | lista de textos | não* | Linhas da página, já mascaradas, **sem quebra de linha** dentro. Até 400 linhas, cada uma com até 300 caracteres. A posição na lista (a partir de 1) é o número da linha que a resposta cita. |
| `page` | inteiro | sim | Página atual, a partir de 1. Não pode passar de `pageCount`. |
| `pageCount` | inteiro | sim | Quantas páginas o extrato tem. No máximo 200. |
| `image` | texto (base64) | não* | Imagem da página, só quando o OCR veio fraco. Até 2 MiB decodificada; JPEG, PNG ou WebP. Texto base64 maior que o limite é tratado como ausente. |
| `period` | texto `AAAA-MM` | não | Mês do extrato, quando uma página anterior já o disse. Mês inexistente: `400`. |
| `examples` | lista de objetos | não | Igual ao de `receipts/classify` (`merchant`, `categoryId`). Aceita até 200 itens (mais que isso: `400`), mas valem só os 20 últimos. O servidor ainda descarta exemplos de categoria desconhecida e exemplos "sobre pessoas". |

\* É preciso mandar `lines` com pelo menos uma linha **ou** `image`. Sem nenhum dos dois: `400 E-REQ-01`.

**Response de sucesso (`200`)**

```json
{
  "movements": [
    {
      "line": 1,
      "day": 12,
      "month": 10,
      "description": "Mercado do Bairro",
      "amountCents": 4590,
      "kind": "expense",
      "categoryId": "c-mercado",
      "confidence": "high",
      "paymentKind": "pix"
    }
  ],
  "period": "2026-10"
}
```

| Campo | Tipo | Observação |
|---|---|---|
| `movements` | lista | Até 60 movimentações por página, na ordem da página. |
| `movements[].line` | inteiro ou `null` | Número da linha de onde saiu (a partir de 1). `null` quando só a imagem a mostrava. |
| `movements[].day`, `month` | inteiros | Dia (1 a 31) e mês (1 a 12), **como o extrato escreve**. |
| `movements[].year` | inteiro | Só aparece quando a linha trouxe o ano (2000 a 2100). |
| `movements[].description` | texto | Nome curto e legível (até 80 caracteres). |
| `movements[].amountCents` | inteiro | Sempre positivo (de 1 a 100000000). O sentido está em `kind`. |
| `movements[].kind` | texto | `expense`, `income`, `cardPayment` ou `ownTransfer`. |
| `movements[].doubtful` | booleano | Só aparece, com `true`, quando o tipo é só palavra da IA, sem nada escrito na linha que o confirme. |
| `movements[].categoryId` | texto ou `null` | Palpite de categoria, sempre uma categoria do servidor. |
| `movements[].confidence` | texto | `high`, `medium` ou `low`. |
| `movements[].paymentKind` | texto ou `null` | Mesmos valores do comprovante. |
| `period` | texto ou `null` | Mês (`AAAA-MM`) quando a página o escreve. |
| `partial` | booleano | Só aparece, com `true`, quando a página foi lida **só em parte** (resposta da IA cortada duas vezes, ou mais de 60 movimentações). É o aviso do catálogo `E-AI-05`. |

**O que a resposta garante**

- Só saem movimentações que passaram nas conferências do servidor: o valor está escrito na linha citada (ou em outra da página); a data existe, está escrita na página e não é futura; a categoria é da lista enviada; o nome é uma marca conhecida ou passou pelo filtro; a palavra escrita na linha manda no tipo. A que não passa **cai fora sozinha**, sem derrubar as outras.
- As linhas são mascaradas **de novo** no servidor antes de irem à IA.
- Resposta cortada pelo teto de tokens é relida em duas metades, uma vez. Se cortar de novo, valem as movimentações completas e a página sai com `"partial": true`: nada é cortado em silêncio.
- Páginas lidas por inteiro ficam em cache. Página lida em parte não fica.

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Nem linha nem imagem; `page` fora do extrato; linha com quebra de linha ou grande demais; base64 inválido; imagem grande demais ou fora do formato; `period` inexistente; campo a mais. |
| 403 | `E-AI-03` | Teto mensal de tokens da IA atingido. |
| 413 | `E-REQ-04` | Corpo acima de 4 MiB. |
| 429 | `E-AI-02` | O serviço de IA pediu uma pausa. Vem com `Retry-After` e `retryAfterSeconds`. |
| 502 | `E-AI-04` | A resposta inteira da IA não se aproveita (fora do esquema). O celular tenta a página de novo. |
| 503 | `E-AI-01` | IA fora do ar, sem resposta a tempo, ou servidor sem a credencial da IA. |

**Fonte:** `server/lib/src/ai/statement_routes.dart`; leitura em `ai_statement_reader.dart`; conferências em `statement_movements.dart`; contrato em `packages/api_contract/lib/src/statement_page_request.dart`, `statement_page_reply.dart` e `statement_movement.dart`.

---

### 7.5 `POST /v1/assistant/ask`

**Para que serve:** faz uma pergunta ao assistente (a Juju). O servidor monta o resumo do mês e o cadastro a partir do **seu próprio estado**; o app manda só a pergunta (e, opcionalmente, os números que a tela dele mostra). Na sessão completa, o assistente também pode agir: lançar, cancelar, registrar renda e abater dívida.

**Autenticação:** token (chave da casa **ou** sessão do código). É a **única** rota de escrita liberada para a sessão só de leitura. Nessa sessão, o assistente só consulta e responde que lançar se faz no celular.

**Parâmetros:** nenhum de caminho nem de consulta. A conversa é separada por aparelho (cabeçalho opcional `X-Cajui-Device`, seção 4.1).

**Request**

```http
POST /v1/assistant/ask HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
X-Cajui-Device: aparelho-teste
Content-Type: application/json

{"message":"Quanto gastei no mercado este mês?"}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `message` | texto | sim | De 1 a 1000 caracteres. |
| `month` | objeto | não | Os números do mês como a tela os mostra. Ver abaixo. |

O objeto `month`, quando vem, tem `period` (texto, até 10 caracteres), `hasPlan` (booleano) e **12 inteiros em centavos**: `cashIncome`, `voucher`, `fixedBills`, `subscriptions`, `dayToDay`, `debtInstallments`, `tithe`, `totalOut`, `voucherCovered`, `outOfPocket`, `result` e `owed`. Se qualquer campo faltar ou tiver outro tipo, o objeto inteiro é **ignorado sem erro** e o servidor usa os números que ele mesmo tem. Campo a mais na raiz do pedido: `400`.

**Response de sucesso (`200`)**

```json
{
  "text": "Você gastou R$ 45,90 no mercado este mês.",
  "outOfScope": false,
  "fallback": false,
  "sources": [],
  "actions": []
}
```

Exemplo quando o assistente agiu no livro:

```json
{
  "text": "Lancei R$ 45,90 em Mercado do Bairro.",
  "outOfScope": false,
  "fallback": false,
  "sources": [],
  "actions": [
    { "kind": "recorded", "id": "e-0002", "label": "Mercado do Bairro", "amountCents": 4590 }
  ]
}
```

| Campo | Tipo | Observação |
|---|---|---|
| `text` | texto | A resposta, em **texto puro** (marcas de negrito, título e código são removidas). No máximo 1200 caracteres: o que passa disso é cortado, não recusado. |
| `fallback` | booleano | `true` quando a IA não conseguiu responder e o servidor devolveu a frase fixa. O que a IA já tinha feito no livro continua feito e vem em `actions`. |
| `outOfScope`, `sources` | booleano, lista | Mantidos por compatibilidade: sempre `false` e `[]`. |
| `actions` | lista | O que o assistente **fez** no livro nesta resposta. Cada ação tem `kind` (`recorded`, `cancelled`, `income` ou `paidDown`), `id` (do lançamento ou do recebimento), `label`, `amountCents` e, só em `paidDown`, `debtId`. É o que permite a tela oferecer "Desfazer". |

**O que a resposta garante**

- Os valores em dinheiro que o texto cita precisam ter **origem conhecida**: o resumo do mês, o cadastro, o que as ferramentas devolveram ou o que a pessoa digitou. Se a IA citar valor sem origem, ela é chamada de volta **uma vez**; se insistir, sai a resposta de formato fixo (`fallback: true`), que é melhor que um número errado dito com segurança.
- A pergunta é mascarada de dados pessoais e dos nomes da casa antes de ir à IA.
- Antes de qualquer chamada à IA, o servidor confere o teto mensal de tokens.
- Cada pergunta pode disparar até 4 rodadas de ferramentas; na última, o modelo precisa responder com o que já tem.
- Na sessão só de leitura, as ferramentas de escrita nem são oferecidas à IA, e são recusadas no servidor se ela pedir.
- Quando a conversa age sobre o livro, grava pelo **mesmo caminho** das rotas de lançamento.

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | `message` ausente, vazia, com mais de 1000 caracteres ou que não é texto; campo a mais. O corpo é conferido **antes** de saber se a IA está ligada. |
| 403 | `E-AI-03` | Teto mensal de tokens atingido. |
| 429 | `E-AI-02` | O serviço de IA pediu uma pausa. Vem com `Retry-After`. |
| 503 | `E-AI-01` | IA fora do ar, sem resposta a tempo, disjuntor aberto, ou servidor sem a credencial da IA. |

**Fonte:** `server/lib/src/assistant/assistant_routes.dart`; conversa em `assistant_service.dart`; formato da resposta em `assistant_answer.dart` e `assistant_action.dart`; números do mês em `packages/api_contract/lib/src/month_figures.dart`.

---

### 7.6 `GET /v1/head`

**Para que serve:** a pergunta mais barata que um aparelho pode fazer. Os aparelhos a repetem de tempos em tempos (a cada 20 segundos, segundo o comentário do código) para saber se há algo novo para baixar.

**Autenticação:** token.

**Parâmetros:** nenhum.

**Request**

```http
GET /v1/head HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

```json
{ "seq": 42, "ledgerSeq": 40 }
```

| Campo | Tipo | Observação |
|---|---|---|
| `seq` | inteiro | O número de eventos no registro (a âncora contra o corte do fim do registro). |
| `ledgerSeq` | inteiro | O `seq` do último evento que **mexeu no livro**. Uso da IA grava evento, mas não conta aqui: é este número que indica "há o que baixar". |

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/head_routes.dart`.

---

### 7.7 `GET /v1/categories`

**Para que serve:** lista as categorias, com a versão em vigor de cada uma.

**Autenticação:** token.

**Parâmetros:** nenhum.

**Request**

```http
GET /v1/categories HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

```json
{
  "categories": [
    {
      "id": "c-mercado",
      "name": "Mercado",
      "block": "variable",
      "groupId": "g-casa",
      "voucherEligible": true,
      "definedAt": "2026-10-28T12:00:00.000Z"
    }
  ]
}
```

`definedAt` só aparece quando a versão em vigor tem carimbo.

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/catalog_routes.dart`; formato em `packages/api_contract/lib/src/category_codec.dart`.

---

### 7.8 `POST /v1/categories`

**Para que serve:** cria uma categoria ou atualiza uma existente (mesmo `id`). Entre duas versões vale a de `definedAt` mais novo.

**Autenticação:** chave da casa.

**Parâmetros:** nenhum.

**Request**

```http
POST /v1/categories HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "c-mercado",
  "name": "Mercado",
  "block": "variable",
  "groupId": "g-casa",
  "voucherEligible": true,
  "definedAt": "2026-10-28T12:00:00Z"
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `id` | texto | sim | De 1 a 64 caracteres. |
| `name` | texto | sim | De 1 a 40 caracteres. Não pode representar cartão ou fatura (palavras como "cartão" e "fatura" são recusadas). |
| `block` | texto | sim | Até 16 caracteres; um de `fixed`, `variable`, `debt`, `subscription`. Outro valor: `400`. |
| `groupId` | texto | sim | De 1 a 64 caracteres. |
| `voucherEligible` | booleano | não | Se o vale alimentação paga esta categoria. Padrão `false`. |
| `definedAt` | texto (instante) | não | ISO 8601 com fuso. Mais de 10 minutos no futuro: `400`. |

**Response de sucesso**

Gravou (`201`):

```json
{ "id": "c-mercado", "seq": 12 }
```

A versão que já estava vale (a mesma de novo, ou mais velha): `200`, sem gravar nada:

```json
{ "id": "c-mercado", "kept": true }
```

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato; `block` desconhecido; `definedAt` no futuro. |
| 422 | `E-CARD-02` | O nome parece um cartão ou fatura. `detail.name` traz o nome recusado. No catálogo, cartão é forma de pagamento, nunca despesa. |

**Fonte:** `server/lib/src/ledger/catalog_routes.dart`; `packages/api_contract/lib/src/category_codec.dart` e `catalog_version.dart`.

---

### 7.9 `GET /v1/cards`

**Para que serve:** lista os cartões de crédito. Do cartão só se guarda o que a conta da fatura pede: nome, dias e limite (e a cor do plástico). **Número de cartão nunca existe no Cajui.**

**Autenticação:** token.

**Parâmetros:** nenhum.

**Request**

```http
GET /v1/cards HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

```json
{
  "cards": [
    {
      "id": "card-0001",
      "name": "Cartão de teste",
      "closingDay": 25,
      "dueDay": 5,
      "creditLimitCents": 300000,
      "skin": "pequi",
      "definedAt": "2026-10-28T12:00:00.000Z"
    }
  ]
}
```

`creditLimitCents` vem `null` quando não há limite informado. `skin` e `definedAt` só aparecem quando existem.

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/catalog_routes.dart`; `packages/api_contract/lib/src/card_codec.dart`.

---

### 7.10 `POST /v1/cards`

**Para que serve:** cria ou atualiza um cartão (mesmo `id`). Vale a versão de `definedAt` mais novo.

**Autenticação:** chave da casa.

**Parâmetros:** nenhum.

**Request**

```http
POST /v1/cards HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "card-0001",
  "name": "Cartão de teste",
  "closingDay": 25,
  "dueDay": 5,
  "creditLimitCents": 300000,
  "skin": "pequi",
  "definedAt": "2026-10-28T12:00:00Z"
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `id` | texto | sim | De 1 a 64 caracteres. Também é o `paymentMethodId` das linhas de pagamento no cartão. |
| `name` | texto | sim | De 1 a 40 caracteres. |
| `closingDay` | inteiro | sim | Dia em que a fatura fecha (1 a 31). Dia 31 vale como último dia nos meses mais curtos. |
| `dueDay` | inteiro | sim | Dia em que a fatura vence (1 a 31). |
| `creditLimitCents` | inteiro ou `null` | não | Limite, em centavos. |
| `skin` | texto | não | Cor do plástico, como palavra. Até 20 caracteres; vazio ou maior que isso vira ausente. |
| `definedAt` | texto (instante) | não | ISO 8601 com fuso. Mais de 10 minutos no futuro: `400`. |

**Response de sucesso**

Gravou (`201`): `{ "id": "card-0001", "seq": 13 }`.
A versão que já estava vale (`200`): `{ "id": "card-0001", "kept": true }`.

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato; `definedAt` no futuro. |

> **Nota (não verificado em execução):** o catálogo prevê `E-CARD-01` (422) para dia fora de 1 a 31, mas, pelo código desta rota, esse caso não é traduzido: a leitura do cartão usa o resultado do domínio sem tratar a recusa, e a falha cai na barreira de erros, que responde `500 E-SRV-01`. O app confere o dia antes de enviar.

**Fonte:** `server/lib/src/ledger/catalog_routes.dart`; `packages/api_contract/lib/src/card_codec.dart`; regra de dias em `packages/domain/lib/src/card/credit_card.dart`.

---

### 7.11 `GET /v1/income`

**Para que serve:** devolve, numa resposta só, os recebimentos, os acertos de saldo do vale e o saldo do vale. Quem lê quer o saldo, e o saldo depende dos dois. Recebimento **não é lançamento**: não tem categoria e nunca se compensa com um gasto.

**Autenticação:** token.

**Parâmetros:** nenhum.

**Request**

```http
GET /v1/income HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

```json
{
  "receipts": [
    {
      "id": "r-0001",
      "sourceId": "sal-0001",
      "tender": "cash",
      "amountCents": 100000,
      "receivedOn": "2026-10-05",
      "note": "Renda de exemplo"
    }
  ],
  "voucherAdjustments": [
    { "id": "aj-0001", "adjustmentCents": -500, "on": "2026-10-20", "reason": "Acerto de exemplo" }
  ],
  "voucherBalanceCents": 12000
}
```

| Campo | Tipo | Observação |
|---|---|---|
| `receipts[]` | objetos | Recebimentos em vigor. O desfeito (fato `income.cancelled`) não aparece. `sourceId` pode ser `null`; `note` só aparece quando existe. |
| `receipts[].tender` | texto | `cash` (dinheiro) ou `mealVoucher` (vale alimentação). São moedas diferentes e **nunca se somam**. |
| `voucherAdjustments[]` | objetos | Como foram gravados (ver `POST /v1/voucher/adjustments`). |
| `voucherBalanceCents` | inteiro | Saldo do vale, **recalculado** a partir dos fatos: créditos recebidos, menos o que os lançamentos vivos pagaram em vale, mais os acertos e estornos. |

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/income_routes.dart`; `packages/api_contract/lib/src/income_codec.dart`; saldo em `server/lib/src/ledger/ledger_state.dart`.

---

### 7.12 `POST /v1/income`

**Para que serve:** registra um recebimento (salário, crédito do vale, entrada avulsa).

**Autenticação:** chave da casa.

**Parâmetros:** nenhum.

**Request**

```http
POST /v1/income HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "r-0001",
  "sourceId": "sal-0001",
  "tender": "cash",
  "amountCents": 100000,
  "receivedOn": "2026-10-05",
  "note": "Renda de exemplo"
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `id` | texto | sim | De 1 a 64 caracteres. Chave de idempotência. |
| `sourceId` | texto | não | De onde veio (por exemplo, um salário do plano). Até 64 caracteres; vazio ou maior vira ausente. |
| `tender` | texto | sim | `cash` ou `mealVoucher`. Outro valor: `400`. |
| `amountCents` | inteiro | sim | Em centavos, **maior que zero**. Zero ou negativo: `400`. |
| `receivedOn` | texto `AAAA-MM-DD` | sim | Data que existe no calendário. |
| `note` | texto | não | Nome do recebimento. Até 40 caracteres; vazio ou maior vira ausente. |

**Response de sucesso (`201`)**

```json
{ "id": "r-0001", "seq": 14 }
```

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato; `tender` desconhecido; `amountCents` zero ou negativo; data inexistente. |

**Fonte:** `server/lib/src/ledger/income_routes.dart`; `packages/api_contract/lib/src/income_codec.dart`.

---

### 7.13 `POST /v1/voucher/adjustments`

**Para que serve:** registra um **acerto do saldo do vale**: o app admite que o saldo de verdade é o do cartão do vale, e não o que ele calculou. Não é renda nem despesa. O valor **pode ser negativo**.

**Autenticação:** chave da casa.

**Parâmetros:** nenhum.

**Request**

```http
POST /v1/voucher/adjustments HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "aj-0001",
  "adjustmentCents": -500,
  "on": "2026-10-20",
  "reason": "Acerto de exemplo"
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `id` | texto | sim | De 1 a 64 caracteres. Chave de idempotência. |
| `adjustmentCents` | inteiro | sim | Em centavos; positivo ou negativo. |
| `on` | texto `AAAA-MM-DD` | sim | Data que existe no calendário. |
| `reason` | texto | sim | De 1 a 120 caracteres. |

**Response de sucesso (`201`)**

```json
{ "id": "aj-0001", "seq": 15 }
```

**Erros possíveis:** `400 E-REQ-01` (corpo fora do formato ou data inexistente), além dos da seção 6.2.

**Fonte:** `server/lib/src/ledger/income_routes.dart`; `packages/api_contract/lib/src/income_codec.dart`.

---

### 7.14 `GET /v1/facts`

**Para que serve:** lista os **fatos** que o servidor só guarda e devolve, sem fazer conta com eles: fatura paga, dívida, plano da planilha e outros (seção 7.15). Existem para os dois celulares mostrarem a mesma coisa e para o celular reinstalado não pedir tudo de novo.

**Autenticação:** token.

**Parâmetros:** nenhum.

**Request**

```http
GET /v1/facts HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

```json
{
  "facts": [
    {
      "id": "f-0001",
      "type": "statement.settled",
      "payload": {
        "id": "s-0001",
        "cardId": "card-0001",
        "dueMonth": "2026-11",
        "amountCents": 10000,
        "paidOn": "2026-10-30"
      }
    }
  ]
}
```

Cada fato volta com `id`, `type` e `payload` (já **normalizado**: só os campos que o formato do tipo conhece).

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/fact_routes.dart`; `packages/api_contract/lib/src/device_fact.dart`.

---

### 7.15 `POST /v1/facts`

**Para que serve:** guarda um fato. A chave é o `id` que o aparelho deu a ele; mandar de novo não grava de novo.

**Autenticação:** chave da casa.

**Parâmetros:** nenhum.

**Request**

```http
POST /v1/facts HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "f-0001",
  "type": "statement.settled",
  "payload": {
    "id": "s-0001",
    "cardId": "card-0001",
    "dueMonth": "2026-11",
    "amountCents": 10000,
    "paidOn": "2026-10-30"
  }
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `id` | texto | sim | De 1 a 96 caracteres. |
| `type` | texto | sim | Um dos tipos da tabela abaixo. Outro valor: `400`. |
| `payload` | objeto | sim | O conteúdo, no formato do tipo. Qualquer tropeço (campo que falta, tipo errado, valor que o domínio recusa) vira `400 E-REQ-01`. Nenhum texto no primeiro nível do `payload` pode passar de 80 caracteres. |

Tipos aceitos e o que vai no `payload`:

| `type` | O que é | Campos do `payload` |
|---|---|---|
| `statement.settled` | Fatura de cartão paga | `id`, `cardId`, `dueMonth` (`AAAA-MM`), `amountCents` (maior que zero), `paidOn` (`AAAA-MM-DD`) |
| `debt.defined` | Dívida cadastrada | `id`, `creditor`, `kind` (`loan`, `financing`, `cardInstallment`, `cardRevolving`, `informal` ou `overdueBill`), `installmentCents`, `dueDay` e, conforme o caso, `totalInstallments`, `paidInstallments`, `firstMonth`, `cardId`, `payoffCents`, `payoffQuotedOn`, `balanceCents`, `informedOn`, `note`, `definedAt` |
| `debt.installment-paid` | Parcela de dívida paga | `debtId`, `entryId` |
| `debt.ordered` | Ordem de quitação das dívidas | `ids` (lista de textos), `definedAt` |
| `month.closed` | Mês fechado (o servidor ainda aceita, mas o app não grava mais) | `month`, `revision` (zero ou mais), `cashResultCents`, `closedOn` |
| `budget.defined` | Plano da planilha | `definedAt`, `salaries` (`id`, `name`, `amountCents`, `payDay`), `voucherCents`, `titheBasisPoints` (0 a 10000), `lines` (`id`, `name`, `amountCents`, `group`, `categoryId`, opcionais `paymentMethodId`, `note`, `dueDay`), `legacyDebtInstallmentsCents` |
| `household.named` | Nomes da casa | `names` (até 6 nomes, cada um com nome e sobrenome e até 80 caracteres), `definedAt` |
| `merchant.learned` | Resposta lembrada (estabelecimento para categoria) | `key`, `definedAt` (com fuso) e opcionais `categoryId`, `treatment` (`expense`, `income`, `household`, `ownAccount` ou `ignore`), `aboutPerson` |
| `income.cancelled` | Recebimento desfeito | `receiptId`, `on` (`AAAA-MM-DD`). **É o único fato que muda conta no servidor**: o recebimento desfeito sai da lista de recebimentos e dos números da Juju. |

Os limites finos de cada campo seguem os leitores do contrato (`packages/api_contract/lib/src/*_codec.dart`) e as regras do domínio. Neste documento só os principais estão detalhados.

**Response de sucesso (`201`)**

```json
{ "id": "f-0001", "seq": 16 }
```

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato; `type` desconhecido; `payload` que não é objeto; conteúdo que o formato do tipo recusa (inclusive recusas de regra, como `E-DEBT-01`, que aqui também viram `E-REQ-01`). |

**Fonte:** `server/lib/src/ledger/fact_routes.dart`; `packages/api_contract/lib/src/device_fact.dart` e os codecs de cada tipo (`debt_codec.dart`, `budget_plan_codec.dart`, `household_codec.dart`, `learned_answer_codec.dart`, `income_cancellation_codec.dart`, `month_close_codec.dart`, `card_codec.dart`).

---

### 7.16 `GET /v1/plan`

**Para que serve:** lê o plano do mês como o aparelho o cadastrou. O plano não tem histórico no servidor: vale o mais novo pelo carimbo.

**Autenticação:** token.

**Parâmetros:** nenhum.

**Request**

```http
GET /v1/plan HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

Mesmo formato do corpo de `POST /v1/plan` (seção 7.17). Sem plano definido, volta o plano vazio (zeros e listas vazias).

```json
{
  "cashIncomeCents": 100000,
  "debtInstallmentsCents": 0,
  "definedAt": "2026-10-28T12:00:00.000Z",
  "fixed": [
    {
      "id": "fx-0001",
      "name": "Internet de teste",
      "amountCents": 9990,
      "dueDay": 10,
      "categoryId": "c-casa",
      "paymentMethodId": "pm-pix"
    }
  ],
  "variables": [
    { "categoryId": "c-mercado", "minCents": 20000, "maxCents": 40000, "voucherEligible": true }
  ]
}
```

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (método `_readPlan`); `packages/api_contract/lib/src/month_setup_codec.dart`.

---

### 7.17 `POST /v1/plan`

**Para que serve:** define o plano do mês **inteiro, de uma vez** (não campo a campo), para o servidor nunca ficar com meio plano. Reenviar o mesmo plano não cria fato novo; um plano diferente cria.

**Autenticação:** chave da casa.

**Parâmetros:** nenhum.

**Request**

```http
POST /v1/plan HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "cashIncomeCents": 100000,
  "debtInstallmentsCents": 0,
  "definedAt": "2026-10-28T12:00:00Z",
  "fixed": [
    {
      "id": "fx-0001",
      "name": "Internet de teste",
      "amountCents": 9990,
      "dueDay": 10,
      "categoryId": "c-casa",
      "paymentMethodId": "pm-pix"
    }
  ],
  "variables": [
    { "categoryId": "c-mercado", "minCents": 20000, "maxCents": 40000, "voucherEligible": true }
  ]
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `cashIncomeCents` | inteiro | sim | Renda em dinheiro prevista; zero ou mais. |
| `debtInstallmentsCents` | inteiro | sim | Parcelas de dívida do mês; zero ou mais. |
| `definedAt` | texto (instante) | não | ISO 8601 com fuso. Mais de 10 minutos no futuro: `400`. |
| `fixed` | lista | não | Contas fixas. Até 50 itens; ausente vale lista vazia. |
| `fixed[].id` | texto | sim | De 1 a 64 caracteres. |
| `fixed[].name` | texto | sim | De 1 a 40 caracteres. |
| `fixed[].amountCents` | inteiro | sim | Zero ou mais. |
| `fixed[].dueDay` | inteiro | sim | Dia do vencimento, de 1 a 31. |
| `fixed[].categoryId` | texto | sim | De 1 a 64 caracteres. |
| `fixed[].paymentMethodId` | texto | sim | De 1 a 64 caracteres. |
| `variables` | lista | não | Faixas de gasto variável. Até 50 itens; ausente vale lista vazia. |
| `variables[].categoryId` | texto | sim | De 1 a 64 caracteres. |
| `variables[].minCents` | inteiro | sim | Zero ou mais. Não pode ser maior que `maxCents`. |
| `variables[].maxCents` | inteiro | sim | Zero ou mais. O Cajui planeja o mês pelo máximo, o pior caso. |
| `variables[].voucherEligible` | booleano | não | Padrão `false`. |

Em todos os níveis, **campo a mais** é recusado. Valor negativo também.

**Response de sucesso (`200`)**

Atenção: esta rota responde `200`, e não `201`.

```json
{ "seq": 17 }
```

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato; valor negativo; `dueDay` fora de 1 a 31; faixa com mínimo maior que o máximo (aqui o `E-BUDG-01` do catálogo vira `E-REQ-01`); `definedAt` no futuro. |

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (método `_definePlan`); `packages/api_contract/lib/src/month_setup_codec.dart`.

---

### 7.18 `GET /v1/entries`

**Para que serve:** lista os lançamentos, **inteiros** (com as linhas de pagamento, para saber o que foi dinheiro e o que foi vale), e a lista dos ids cancelados.

**Autenticação:** token.

**Parâmetros de consulta**

| Nome | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `month` | texto `AAAA-MM` | não | Filtra pelo mês do lançamento. O servidor compara como texto: um valor que não existe ou fora do formato devolve lista vazia, sem erro. Sem o parâmetro, devolve todos. |

**Request**

```http
GET /v1/entries?month=2026-10 HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

```json
{
  "entries": [
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
  ],
  "cancelledIds": []
}
```

Cada item de `entries` tem o mesmo formato do corpo de `POST /v1/entries` (seção 7.19). Campos opcionais só aparecem quando têm valor: `installments`, `installmentAmountCents` (só em compra parcelada com juros), `origin` (só quando não é `manual`) e `revisedAt`.

`cancelledIds` lista os ids dos lançamentos cancelados. É o que faz o outro aparelho cancelar em vez de mandar o lançamento de volta.

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (método `_listEntries`); `packages/api_contract/lib/src/entry_codec.dart`.

---

### 7.19 `POST /v1/entries`

**Para que serve:** cria um lançamento (uma compra). O servidor **confere de novo** as regras do domínio: nunca confia no que o app já validou.

**Autenticação:** chave da casa.

**Parâmetros:** nenhum.

**Request**

```http
POST /v1/entries HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

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

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `id` | texto | sim | De 1 a 64 caracteres. Criado no aparelho; é a chave de idempotência. |
| `description` | texto | sim | O que foi comprado. De 1 a 200 caracteres. |
| `amountCents` | inteiro | sim | Valor em centavos. Precisa ser maior que zero (senão `422 E-ENTRY-03`). |
| `occurredOn` | texto `AAAA-MM-DD` | sim | Data da compra, que exista no calendário. Não pode ser depois de "hoje" (senão `422 E-ENTRY-02`). |
| `categoryId` | texto | sim | De 1 a 64 caracteres. Precisa ser uma categoria cadastrada no servidor (senão `404 E-REQ-02`). |
| `paymentLines` | lista | sim | De 1 a 20 linhas. A soma dos valores precisa ser igual a `amountCents` (senão `422 E-ENTRY-01`). |
| `paymentLines[].paymentMethodId` | texto | sim | De 1 a 64 caracteres. Para cartão de crédito, é o `id` do cartão. |
| `paymentLines[].kind` | texto | sim | Um de `physicalCash`, `pix`, `debit`, `bankSlip`, `creditCard`, `mealVoucher`. Outro valor: `400`. |
| `paymentLines[].amountCents` | inteiro | sim | Em centavos, maior que zero (senão `422 E-ENTRY-03`). |
| `isExceptional` | booleano | não | Gasto fora do padrão. Padrão `false`. |
| `installments` | inteiro | não | Número de parcelas de compra no cartão. Menos de 2 (ou ausente) é compra à vista. Mais de 24: `400`. Exige uma linha `creditCard` cujo `paymentMethodId` seja um cartão cadastrado; senão `400`. As datas das parcelas são **recalculadas** pelo servidor a partir do cartão e da data da compra. |
| `installmentAmountCents` | inteiro | não | Valor de cada parcela, quando a compra tem **juros**. Só vale se as parcelas somam mais que a compra e nenhuma é maior que ela; senão é ignorado, sem erro. |
| `origin` | texto | não | Como nasceu: `manual`, `share` ou `notification`. Ausente vale `manual`. Outro nome: `400`. Texto vazio ou com mais de 16 caracteres vira ausente. |
| `revisedAt` | texto (instante) | não | Quando foi corrigido pela última vez (ISO 8601 com fuso). Mais de 10 minutos no futuro: `400`. |

Se um pagamento usa `mealVoucher`, a categoria precisa ser elegível ao vale (senão `422 E-VOUCHER-02`).

**Response de sucesso (`201`)**

```json
{ "id": "e-0001", "seq": 18 }
```

Casos que **não** devolvem `201`:

| Caso | Resposta |
|---|---|
| O `id` pertence a um lançamento que algum aparelho já **cancelou** (ele não ressuscita) | `200` com `{ "id": "e-0001", "cancelled": true }` |
| O `id` já existe | `201` com o `seq` do evento original; nada é alterado. |

**Erros possíveis** (além dos da seção 6.2)

A ordem das conferências é: corpo (`400`), categoria desconhecida (`404`), lançamento cancelado (`200`), carimbo no futuro (`400`), formato de data, tipo e parcelas (`400`), regras do domínio (`422`).

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato; data inexistente; `kind` ou `origin` desconhecido; parcelamento sem cartão conhecido ou acima de 24; `revisedAt` no futuro. |
| 404 | `E-REQ-02` | `categoryId` que o servidor não conhece. |
| 422 | `E-ENTRY-01` | A soma das linhas difere do valor. `detail`: `amountCents`, `linesTotalCents`. |
| 422 | `E-ENTRY-02` | Data da compra no futuro. `detail`: `occurredOn`, `today`. |
| 422 | `E-ENTRY-03` | Valor do lançamento ou de uma linha zero ou negativo. `detail`: `amountCents`. |
| 422 | `E-VOUCHER-02` | Pagamento no vale em categoria não elegível. `detail`: `category`. |

Exemplo de erro:

```json
{"error":{"code":"E-ENTRY-01","class":"regra","detail":{"amountCents":4590,"linesTotalCents":4000},"ref":"a1b2c3","retryAfterSeconds":null}}
```

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (métodos `_createEntry` e `_gate`); contrato em `packages/api_contract/lib/src/create_entry_request.dart`, `payment_line_dto.dart` e `entry_codec.dart`; tradução das recusas em `failure_mapper.dart`.

---

### 7.20 `PUT /v1/entries/{id}`

**Para que serve:** corrige um lançamento. **Nada é reescrito**: o fato antigo continua no registro, e o lançamento passa a mostrar a versão nova no lugar dele, na mesma posição da lista.

**Autenticação:** chave da casa.

**Parâmetros de caminho**

| Nome | Tipo | Regra |
|---|---|---|
| `id` | texto | O id do lançamento. Precisa ser igual ao `id` do corpo. |

**Request**

```http
PUT /v1/entries/e-0001 HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "e-0001",
  "description": "Mercado do Bairro (corrigido)",
  "amountCents": 5000,
  "occurredOn": "2026-10-28",
  "categoryId": "c-mercado",
  "paymentLines": [
    { "paymentMethodId": "pm-pix", "kind": "pix", "amountCents": 5000 }
  ],
  "isExceptional": false,
  "revisedAt": "2026-10-29T10:00:00Z"
}
```

**Campos do request:** os mesmos de `POST /v1/entries` (tabela da seção 7.19). O `revisedAt` é o que decide qual correção vale entre dois celulares: a mais nova, e não a que chegou por último.

**Response de sucesso (`200`)**

```json
{ "id": "e-0001" }
```

Outros casos de `200`:

| Caso | Corpo |
|---|---|
| Já existe uma versão **mais nova** (outro aparelho corrigiu depois): a correção mais velha não passa por cima | `{ "id": "e-0001", "kept": true }` |
| O lançamento foi cancelado | `{ "id": "e-0001", "cancelled": true }` |

Pelo código, se o servidor não conhece o `id` e ele não foi cancelado, a correção faz o lançamento passar a existir (não exercitado).

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Mesmos casos do `POST /v1/entries`. |
| 404 | `E-REQ-02` | `id` do caminho diferente do `id` do corpo; ou categoria desconhecida. |
| 422 | `E-ENTRY-01`, `E-ENTRY-02`, `E-ENTRY-03`, `E-VOUCHER-02` | As mesmas regras do `POST /v1/entries`. |

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (método `_reviseEntry`).

---

### 7.21 `DELETE /v1/entries/{id}`

**Para que serve:** cancela um lançamento. **Cancelar não apaga**: grava o fato de que ele não vale mais. O cancelado sai de toda visão, mas continua no registro, e seu id aparece em `cancelledIds` de `GET /v1/entries`.

**Autenticação:** chave da casa.

**Parâmetros de caminho**

| Nome | Tipo | Regra |
|---|---|---|
| `id` | texto | O id do lançamento. |

**Request**

```http
DELETE /v1/entries/e-0001 HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

Sem corpo.

**Response de sucesso (`200`)**

```json
{ "id": "e-0001" }
```

Cancelar o que já está cancelado é repetição e também responde `200`, com `{ "id": "e-0001", "cancelled": true }`.

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 404 | `E-REQ-02` | O lançamento nunca existiu (cancelar o que não existe seria inventar um cancelado eterno). |

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (método `_cancelEntry`).

---

### 7.22 `POST /v1/entries/{id}/reversals`

**Para que serve:** registra um **estorno**: o dinheiro de uma compra que voltou. O estorno não altera o lançamento original; é um fato próprio, ligado a ele, que reduz o gasto da categoria no mês da data do estorno e volta pela mesma forma de pagamento. O servidor confere de novo se ainda resta o que estornar naquela linha.

**Autenticação:** chave da casa.

**Parâmetros de caminho**

| Nome | Tipo | Regra |
|---|---|---|
| `id` | texto | O id do lançamento estornado. Precisa ser igual ao `entryId` do corpo. |

**Request**

```http
POST /v1/entries/e-0001/reversals HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "rv-0001",
  "entryId": "e-0001",
  "paymentMethodId": "pm-pix",
  "amountCents": 1000,
  "occurredOn": "2026-10-29"
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `id` | texto | sim | De 1 a 64 caracteres. Identificador do estorno. |
| `entryId` | texto | sim | De 1 a 64 caracteres. Igual ao `id` do caminho. |
| `paymentMethodId` | texto | sim | De 1 a 64 caracteres. A forma de pagamento da linha que volta; precisa ser uma das linhas do lançamento. |
| `amountCents` | inteiro | sim | Em centavos, **maior que zero**. Zero ou negativo: `400`. |
| `occurredOn` | texto `AAAA-MM-DD` | sim | Data do estorno, que exista no calendário. |

**Response de sucesso (`201`)**

```json
{ "id": "rv-0001" }
```

**Erros possíveis** (além dos da seção 6.2)

| HTTP | Código | Quando |
|---|---|---|
| 400 | `E-REQ-01` | Corpo fora do formato; `amountCents` zero ou negativo; data inexistente. |
| 404 | `E-REQ-02` | `entryId` diferente do `id` do caminho; ou lançamento que o servidor não conhece. |
| 422 | `E-ENTRY-04` | O estorno passa do que resta da linha, ou a forma de pagamento não está no lançamento. `detail`: `remainingCents`, `requestedCents`. |

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (método `_reverseEntry`); `packages/api_contract/lib/src/reversal_codec.dart`; regra em `packages/domain/lib/src/ledger/reversal.dart`.

---

### 7.23 `GET /v1/reversals`

**Para que serve:** lista os estornos registrados.

**Autenticação:** token.

**Parâmetros:** nenhum.

**Request**

```http
GET /v1/reversals HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

**Response de sucesso (`200`)**

```json
{
  "reversals": [
    {
      "id": "rv-0001",
      "entryId": "e-0001",
      "paymentMethodId": "pm-pix",
      "amountCents": 1000,
      "occurredOn": "2026-10-29"
    }
  ]
}
```

**Erros possíveis:** apenas os da seção 6.2.

**Fonte:** `server/lib/src/ledger/ledger_routes.dart` (método `_listReversals`); `packages/api_contract/lib/src/reversal_codec.dart`.

---

## 8. Exemplos de fluxo

Os exemplos usam só valores fictícios. `<token>` é um marcador: troque pelo valor que você tem.

### 8.1 Fluxo do app: criar e listar lançamentos (chave da casa)

A criação de lançamentos exige a **chave da casa**. A sessão aberta pelo código do autenticador é só de leitura e recebe `403 E-AUTH-03` ao tentar escrever (fluxo 8.2).

**Passo 1. Cadastrar a categoria**

```http
POST /v1/categories HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{"id":"c-mercado","name":"Mercado","block":"variable","groupId":"g-casa","voucherEligible":true}
```

Resposta: `201` com `{"id":"c-mercado","seq":12}`.

**Passo 2. Criar o lançamento**

```http
POST /v1/entries HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
Content-Type: application/json

{"id":"e-0001","description":"Mercado do Bairro","amountCents":4590,"occurredOn":"2026-10-28","categoryId":"c-mercado","paymentLines":[{"paymentMethodId":"pm-pix","kind":"pix","amountCents":4590}]}
```

Resposta: `201` com `{"id":"e-0001","seq":13}`.

Se a resposta se perder e o app mandar **o mesmo pedido de novo**, o servidor devolve `201` com o mesmo `seq` e não cria outro lançamento (idempotência pelo `id`).

**Passo 3. Listar os lançamentos do mês**

```http
GET /v1/entries?month=2026-10 HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

Resposta `200`:

```json
{"entries":[{"id":"e-0001","description":"Mercado do Bairro","amountCents":4590,"occurredOn":"2026-10-28","categoryId":"c-mercado","paymentLines":[{"paymentMethodId":"pm-pix","kind":"pix","amountCents":4590}],"isExceptional":false}],"cancelledIds":[]}
```

**Passo 4. Cancelar o lançamento**

```http
DELETE /v1/entries/e-0001 HTTP/1.1
Host: <servidor>
Authorization: Bearer <token>
```

Resposta: `200` com `{"id":"e-0001"}`. Um novo `GET /v1/entries?month=2026-10` devolve `"entries":[]` e `"cancelledIds":["e-0001"]`.

### 8.2 Fluxo da web de consulta: código, token, leitura e pergunta

**Passo 1. Trocar o código por um token**

```http
POST /v1/auth/code HTTP/1.1
Host: <servidor>
Content-Type: application/json

{"code":"123456"}
```

Resposta: `200` com `{"token":"<token-de-sessao>"}`.

**Passo 2. Ler os lançamentos com o token**

```http
GET /v1/entries?month=2026-10 HTTP/1.1
Host: <servidor>
Authorization: Bearer <token-de-sessao>
```

Resposta: `200`, igual ao passo 3 do fluxo anterior.

**Passo 3. Tentar escrever (vai ser recusado)**

```http
POST /v1/entries HTTP/1.1
Host: <servidor>
Authorization: Bearer <token-de-sessao>
Content-Type: application/json

{"id":"e-0002","description":"Padaria do Exemplo","amountCents":1200,"occurredOn":"2026-10-29","categoryId":"c-mercado","paymentLines":[{"paymentMethodId":"pm-pix","kind":"pix","amountCents":1200}]}
```

Resposta: `403` com `E-AUTH-03`. A sessão da web só lê. A recusa acontece na autenticação, antes de o corpo ser lido.

**Passo 4. Perguntar ao assistente (permitido)**

```http
POST /v1/assistant/ask HTTP/1.1
Host: <servidor>
Authorization: Bearer <token-de-sessao>
Content-Type: application/json

{"message":"Quanto gastei no mercado este mês?"}
```

Resposta: `200` com `text`, `fallback`, `actions` e os campos de compatibilidade (seção 7.5). Nessa sessão, `actions` vem vazio, porque o assistente só consulta.

---

## 9. O que não foi verificado

Este documento nasceu da leitura do código. Ficam de fora, ou com ressalva:

1. **Nada foi executado.** Nenhuma rota foi chamada; os exemplos de resposta foram montados a partir dos codecs e das rotas, não copiados de uma execução. Os valores `seq`, `ref` e `definedAt` dos exemplos são ilustrativos.
2. **Corpo exato do `404` para rota que não existe** (devolvido pelo roteador, não pelo catálogo de erros) e o comportamento de `HEAD` e de `OPTIONS` vindo de origem diferente da configurada: não foram lidos nem testados.
3. **`E-CARD-01` em `POST /v1/cards`:** pela leitura do código, um dia fora de 1 a 31 não vira `422`, e sim `500 E-SRV-01` (nota na seção 7.10). Não foi exercitado.
4. **`PUT /v1/entries/{id}` para um id desconhecido** criar o lançamento é conclusão da leitura do código, não de um teste.
5. **Reenvio do mesmo estorno** (mesmo `id`) numa segunda tentativa: o servidor refaz a conferência do que resta com o estorno original já contado, então o resultado pode ser `E-ENTRY-04`. Não foi verificado.
6. **Códigos do catálogo sem rota que os emita** nas rotas lidas: `E-VOUCHER-01`, `E-BUDG-02` a `E-BUDG-04`, `E-SYNC-01`, `E-SYNC-02`, `E-DATA-02`, `E-REQ-03`, `E-SRV-02`, `E-SRV-03` e `E-AUTH-04`. O catálogo os prevê; a tabela da seção 6.3 marca cada um. Pode haver emissão em outro lugar (por exemplo, no proxy ou no app), que não foi investigada.
7. **Valores padrão do código** (limite de taxa de 120 e 600 por minuto; prazos da IA de 8, 25 e 35 segundos; tetos de tamanho): a composição do servidor pode sobrescrevê-los em produção. Os valores efetivos de produção não foram conferidos, e o teto mensal de tokens da IA não é publicado aqui.
8. **Conteúdo da resposta da IA** (`text` do assistente, `categoryId` e `confidence` sugeridos): depende do modelo. Só o **formato** e as garantias de validação foram documentados. O significado fino de `candidates`, `confidence` e `source` segue o domínio de recibos e não foi detalhado campo a campo.
9. **Regras finas dos fatos** (`debt.defined`, `budget.defined`, `household.named`): os campos listados na seção 7.15 são os principais; limites e validações de domínio (dívida, linha do plano, nome com sobrenome) foram lidos só em parte.
10. **Endereço de produção, origem da web de consulta, nome do segredo e demais detalhes de implantação:** de propósito, não estão neste documento.
11. **Content-Type do pedido:** o código não o confere; se um proxy à frente do servidor o exige, isso não foi verificado.
