# Regras de negócio

Cada regra tem um identificador estável (`RN-NNN`), é verificável e aponta para sua origem. O identificador aparece no nome do teste que a cobre (`test('RN-304 compra à vista no cartão conta na data da compra', …)`), de modo que regra sem teste e teste sem regra ficam visíveis.

## Numeração

Blocos de centena, para uma área crescer sem renumerar as outras. Número nunca é reaproveitado: regra retirada fica na tabela como **revogada**, com o motivo.

| Faixa | Área | Arquivo |
|---|---|---|
| RN-101 a RN-199 | Dinheiro, renda e as duas moedas | [income-and-tenders.md](income-and-tenders.md) |
| RN-201 a RN-299 | Lançamentos e pagamentos | [entries-and-payments.md](entries-and-payments.md) |
| RN-301 a RN-399 | Cartão de crédito | [credit-card.md](credit-card.md) |
| RN-401 a RN-499 | Blocos e orçamento do mês | [blocks-and-budget.md](blocks-and-budget.md) |
| RN-501 a RN-599 | Dívidas | [debts.md](debts.md) |
| RN-601 a RN-699 | Indicadores | [indicators.md](indicators.md) |
| RN-701 a RN-799 | Captura e classificação | [capture-and-classification.md](capture-and-classification.md) |
| RN-801 a RN-899 | Retorno periódico | [feedback.md](feedback.md) |
| RN-901 a RN-999 | Assistente e privacidade | [assistant-and-privacy.md](assistant-and-privacy.md) |

## Formato

| Coluna | Conteúdo |
|---|---|
| **ID** | `RN-NNN` |
| **Regra** | Uma frase afirmativa, no presente, que pode ser verdadeira ou falsa para um dado estado do sistema |
| **Exemplo ou teste** | Um caso concreto com números, que vira teste |
| **Origem** | De onde veio: `prompt` (pedido original), `decisão AAAA-MM-DD` (resposta do dono do produto), um `D-…` da [pesquisa](../../research/README.md), ou `modelagem` (consequência lógica das anteriores) |

Regras marcadas com **⚑ validar** são decisões de modelagem que o dono do produto ainda não viu; ficam valendo como proposta até o checkpoint da Fase 2.

## Onde as regras vivem no código

As regras RN-1xx a RN-6xx são **domínio puro**: moram em `packages/domain`, sem dependência de Flutter, de Shelf, de JSON ou de rede, e rodam iguais no app e no servidor. As RN-7xx a RN-9xx envolvem serviços externos e ficam na camada de aplicação, com o domínio definindo apenas as portas.

Todo cálculo é função pura dos eventos do log: os mesmos eventos produzem sempre os mesmos números, em qualquer máquina. É isso que permite recalcular um mês inteiro a partir do log, conferir um snapshot e testar regra com dados fixos.

## Convenções que valem para todas

- **Fuso de negócio.** "Hoje", "esta semana" e "este mês" são avaliados no fuso configurado do domicílio (padrão `America/Araguaina`). O servidor nunca usa o fuso da própria máquina.
- **Mês de competência** é o mês de calendário, do dia 1 ao último dia, no fuso de negócio.
- **Semana** é a de calendário, de segunda a domingo.
- **Arredondamento.** Onde uma divisão não é exata, a regra diz como arredonda. Sem indicação, vale RN-102.
- **Rejeitar é diferente de avisar.** "É rejeitado" significa que a operação não acontece e o usuário recebe um erro do [catálogo](../error-catalog.md). "Avisa" significa que a operação acontece e o app sinaliza.
