# Casos de uso

Tudo o que o usuário faz no Cajui, com critérios de aceitação verificáveis. Cada caso aponta as regras que o sustentam e o evento que grava; os critérios viram testes de aceitação na Fase 6.

## Arquivos

| Área | Arquivo | Casos |
|---|---|---|
| Configuração inicial | [use-cases/setup.md](use-cases/setup.md) | UC-SETUP-01 a 08 |
| Lançamentos | [use-cases/entries.md](use-cases/entries.md) | UC-ENTRY-01 a 09 |
| Cartão de crédito | [use-cases/credit-card.md](use-cases/credit-card.md) | UC-CARD-01 a 06 |
| Captura por compartilhamento | [use-cases/capture.md](use-cases/capture.md) | UC-CAPT-01 a 09 |
| Orçamento e fechamento | [use-cases/budget-and-closing.md](use-cases/budget-and-closing.md) | UC-BUDG-01 a 07 |
| Dívidas | [use-cases/debts.md](use-cases/debts.md) | UC-DEBT-01 a 05 |
| Retorno e relatórios | [use-cases/insights-and-feedback.md](use-cases/insights-and-feedback.md) | UC-INS-01 a 06 |
| Assistente | [use-cases/assistant.md](use-cases/assistant.md) | UC-ASST-01 a 05 |
| Preferências e segurança | [use-cases/settings-and-security.md](use-cases/settings-and-security.md) | UC-SET-01 a 10 |

## Formato

| Campo | Conteúdo |
|---|---|
| **ID e nome** | `UC-<ÁREA>-NN` |
| **Plataforma** | `Android`, `web` ou `ambas`. O ator é sempre o usuário único |
| **Gatilho** | O que inicia o caso |
| **Grava** | O evento do [catálogo](data-model.md#catálogo-de-eventos) que o caso acrescenta ao log, ou "nada" quando é só leitura |
| **Regras** | Os `RN-…` envolvidos |
| **Fluxo** | Passos numerados do caminho principal |
| **Alternativas e erros** | Desvios, cada erro com seu código |
| **Aceite** | Critérios no formato **Dado / Quando / Então**, com números do [exemplo de setembro de 2026](rules/indicators.md#exemplo-completo) |

## Convenções

- **Plataforma.** Tudo o que grava dado acontece no Android. A web é modo consulta: lê painel, relatórios, faturas, dívidas e conversa com o assistente; não lança, não corrige, não captura (decisão de 2026-09-19).
- **Sem rede.** No Android, todo caso que grava funciona sem rede: o comando entra na fila local com chave de idempotência e sobe depois (RN-781). Os critérios de aceite valem nas duas situações, salvo indicação.
- **Códigos de erro.** Os `E-<ÁREA>-NN` são **provisórios**. O catálogo definitivo (`docs/spec/error-catalog.md`) é escrito na Fase 3 e parte desta lista. Toda mensagem segue a fórmula do guia de voz — o que aconteceu, o que isso significa, o que dá para fazer —, com a exceção deliberada da classe `segurança` (RNF-SEC-18).
- **Texto de tela** nos exemplos segue o [guia de voz](../brand/voice-and-tone.md).

## Códigos de erro provisórios

> **Substituído.** O catálogo definitivo está em [error-catalog.md](error-catalog.md): os códigos abaixo foram mantidos, ganharam texto, saída e origem, e entraram nove novos. Esta tabela fica como registro de qual caso de uso originou cada código.

| Código | Situação | Caso |
|---|---|---|
| `E-ENTRY-01` | Soma das linhas de pagamento diferente do valor | UC-ENTRY-02 |
| `E-ENTRY-02` | Data da compra no futuro | UC-ENTRY-01 |
| `E-ENTRY-03` | Valor zero ou negativo | UC-ENTRY-01 |
| `E-ENTRY-04` | Estorno maior que o que resta do lançamento | UC-ENTRY-05 |
| `E-VOUCHER-01` | Pagamento no vale maior que o saldo | UC-ENTRY-02 |
| `E-VOUCHER-02` | Categoria não elegível ao vale | UC-ENTRY-02 |
| `E-CARD-01` | Dia de fechamento ou de vencimento inválido | UC-SETUP-04 |
| `E-CARD-02` | Tentativa de criar categoria que representa cartão ou fatura | UC-SETUP-03 |
| `E-BUDG-01` | Faixa com mínimo maior que o máximo | UC-SETUP-06 |
| `E-BUDG-02` | Fechar um mês que ainda não terminou | UC-BUDG-05 |
| `E-BUDG-03` | Ajuste abaixo do mínimo da faixa | UC-BUDG-04 |
| `E-BUDG-04` | Remanejamento maior que a folga da origem | UC-BUDG-03 |
| `E-DEBT-01` | Parcelas pagas maior que o total | UC-DEBT-01 |
| `E-CAPT-01` a `E-CAPT-06` | Leitura e arquivo: ver [sharing-flow.md](sharing-flow.md#os-estados-da-tela) | UC-CAPT-01 a 04 |
| `E-NET-01` | Sem conexão numa ação que só existe com rede (assistente, web) | UC-ASST-01 |
| `E-NET-02` | Servidor não respondeu no prazo | todos |
| `E-SYNC-01` | Comando da fila rejeitado pelo servidor | UC-CAPT-08 |
| `E-SYNC-02` | Conflito de escrita: outro comando gravou primeiro | todos |
| `E-AI-01` | IA fora do ar ou sem resposta no prazo | UC-CAPT-01 · UC-ASST-01 |
| `E-AI-02` | Limite de requisições da IA atingido (429) | UC-ASST-01 |
| `E-AI-03` | Orçamento mensal de tokens esgotado | UC-ASST-04 |
| `E-AI-04` | Resposta da IA inválida (JSON malformado, fora do esquema) | UC-CAPT-01 |
| `E-AUTH-01` | Biometria indisponível no aparelho | UC-SET-03 |
| `E-AUTH-02` | Biometria não reconhecida | UC-SET-03 |
| `E-AUTH-03` | Sessão, aparelho ou pino recusado — classe `segurança`, vago de propósito | UC-SET-03 a 06 |
| `E-AUTH-04` | Código de pareamento vencido, usado ou errado — classe `segurança` | UC-SET-04 |
| `E-RATE-01` | Limite de taxa do servidor (429), com o tempo de espera | todos |
| `E-DATA-01` | Cadeia do log quebrada: banco corrompido, com o ponto exato | UC-SET-09 |
| `E-DATA-02` | Resultado inconsistente entre snapshot e log | UC-SET-09 |
| `E-STORAGE-01` | Armazenamento do aparelho cheio | UC-CAPT-01 |
| `E-SRV-01` | Erro interno do servidor (5xx), com identificador para o log | todos |

## Telas e seus estados

O que a Fase 3 precisa desenhar. Toda tela tem, no mínimo: **carregando** (esqueleto), **com dados**, **erro**, **sem rede**.

| Tela | Estados além do mínimo |
|---|---|
| Painel | Vazia de primeiro uso · sem renda cadastrada (RN-604) · variável esgotado (RN-645) · semana partida (RN-644) · com capturas para conferir · modo consulta (web) |
| Lançar | Dividindo pagamento · vale insuficiente · sem faixa na categoria · ligando a um fixo |
| Confirmação de captura | Os 17 estados de [sharing-flow.md](sharing-flow.md#os-estados-da-tela) |
| Para conferir | Vazia · com pendências · completando com a IA |
| Lançamentos | Vazia · filtrada sem resultado · com lançamento tardio · com correção no histórico |
| Fatura | Sem compras no ciclo · com valor não identificado · paga · paga em parte · pago a mais |
| Plano do mês | Mês corrente · mês futuro (só comprometido, RN-433) · com ajuste aplicado |
| Ajustes | Cobre a falta · não cobre (RN-662) · nada a ajustar |
| Fechamento | Pronto para fechar com itens em aberto · com sobra · com falta · fechado · revisado |
| Dívidas | Vazia · com dívidas · com parcela em aberto · dívida quitada (marco) |
| Resumos | Diário, semanal e mensal, cada um nos níveis simplificado e detalhado, nas formas visual e numérica |
| Assistente | Vazia com sugestões · respondendo · IA fora do ar · orçamento de tokens esgotado · sem rede · modo consulta |
| Desbloqueio | Pedindo biometria · não reconhecida · biometria indisponível · recusado |
| Pareamento | Pedindo código · código recusado · pareado |
| Configurações | Regras aprendidas (vazia · com regras) · consumo de tokens · estado do sistema (tudo certo · com aviso) |
| Configuração inicial | Cada passo: vazio · preenchido · com erro de validação |
