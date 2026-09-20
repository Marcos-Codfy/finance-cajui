# Casos de uso — captura por compartilhamento

Formato e convenções em [use-cases.md](../use-cases.md). Fluxo, tela de confirmação e texto de cada estado em [sharing-flow.md](../sharing-flow.md). Regras em [capture-and-classification.md](../rules/capture-and-classification.md). Tudo aqui é **Android**.

## UC-CAPT-01 — Receber um comprovante em imagem

**Gatilho:** "Compartilhar" em qualquer app, escolhendo o Cajui · **Grava:** ao confirmar, `ReceiptStored` + `EntryRecorded` + `ClassificationFeedbackRecorded`, sob a mesma chave (RN-722) · **Regras:** RN-701 a RN-704, RN-710, RN-720, RN-730, RN-740 a RN-746, RN-795

**Fluxo:** 1. O Cajui aparece na lista de destinos. 2. Guarda o original. 3. Lê o texto no aparelho. 4. Classifica por regras; com rede, completa com a IA, enviando só texto mascarado. 5. Mostra a confirmação com a confiança por campo. 6. O usuário confere e toca em "Lançar".

**Erros:** `E-CAPT-01` sem texto legível · `E-CAPT-02` arquivo inválido · `E-CAPT-03` grande demais · `E-CAPT-05` sem permissão de leitura · `E-STORAGE-01` · `E-AI-01`, `E-AI-04` (caem para as regras, sem travar).

**Aceite:**
- Dado um print de Pix de R$ 46,90 na galeria, quando o usuário toca em "Compartilhar", então o Cajui está na lista de destinos.
- Dado o comprovante compartilhado, quando a confirmação abre, então valor, data, descrição, categoria e forma de pagamento estão propostos, cada um com a confiança visível em texto e ícone.
- Dado qualquer captura, quando o tráfego de rede é inspecionado, então a imagem não foi enviada à rota de classificação, e CPF, conta e chave Pix saíram mascarados.
- Dado a captura aberta, quando o usuário sai sem tocar em "Lançar", então nada foi gravado e ela está em "Para conferir".
- Dado a IA fora do ar, quando um comprovante é compartilhado, então a confirmação abre com o que as regras leram e o texto "A classificação automática está fora do ar…", e lançar continua possível.
- Tempo do compartilhar até a confirmação: alvo em RNF-PERF (confirma no spike BL-004).

## UC-CAPT-02 — Receber vários arquivos de uma vez

**Regras:** RN-705

**Aceite:**
- Dado três prints compartilhados juntos, quando o Cajui recebe, então abre "3 comprovantes para conferir · 1 de 3" e cada um tem proposta e confirmação próprias, na ordem recebida.
- Dado o segundo descartado, quando o fluxo termina, então só dois lançamentos existem.
- Dado onze arquivos, quando compartilhados, então o app recebe dez e diz que o limite é dez por vez.

## UC-CAPT-03 — Receber um PDF

**Regras:** RN-711, RN-712

**Erros:** `E-CAPT-04` PDF com senha.

**Aceite:**
- Dado um PDF com camada de texto, quando compartilhado, então o texto vem da camada, sem OCR.
- Dado um PDF escaneado, quando compartilhado, então as páginas sem texto são rasterizadas e lidas por OCR, com "página 2 de 4" na tela.
- Dado um PDF protegido por senha, quando compartilhado, então é recusado com `E-CAPT-04` e o app **não** pede a senha.

## UC-CAPT-04 — Receber texto ou extrato

**Regras:** RN-706, RN-707

**Aceite:**
- Dado uma mensagem de texto com um Pix, quando compartilhada, então segue o mesmo fluxo, sem etapa de leitura de imagem.
- Dado um extrato com 12 movimentações, quando compartilhado, então o app lista 12 propostas, cada uma confirmada ou pulada à parte; pular não grava nada.

## UC-CAPT-05 — Responder à pergunta de esclarecimento

**Grava:** ao confirmar, os eventos de UC-CAPT-01 e `LearnedRuleCreated` · **Regras:** RN-760 a RN-763, RN-796

**Fluxo:** 1. A categoria está na zona baixa, ou os candidatos são de blocos diferentes. 2. O app pergunta, com valor e estabelecimento. 3. O usuário toca num candidato ou descreve. 4. O app confirma o que aprendeu, com "Desfazer".

**Aceite:**
- Dado uma compra de R$ 23,90 no Posto Cajueiro com dúvida entre transporte e alimentação, quando a captura abre, então a pergunta é "Fiquei em dúvida entre transporte e alimentação. O que foi essa compra de R$ 23,90 no Posto Cajueiro?".
- Dado a resposta "alimentação", quando confirmada, então aparece "Vou lembrar: Posto Cajueiro é alimentação." com "Desfazer", e a próxima compra ali vem proposta como alimentação, em zona alta.
- Dado o classificador sem palpite, quando a captura abre, então a categoria vem **vazia** — nunca "Outros" (RN-796).
- Dado "Responder depois", quando tocado, então a captura vai para "Para conferir" e não entra em indicador (Q10).

## UC-CAPT-06 — Corrigir a proposta e gerenciar o que o app aprendeu

**Grava:** `LearnedRuleCreated`, `LearnedRuleRemoved` · **Regras:** RN-763 a RN-767, RN-790 a RN-792

**Aceite:**
- Dado uma proposta "lazer" corrigida para "transporte", quando lançada, então nasce a regra para aquele estabelecimento e o contador registra uma correção.
- Dado uma proposta que veio de regra aprendida, quando o usuário a corrige, então a regra é removida, nenhuma outra é criada, e o app volta a perguntar naquele estabelecimento (RN-766).
- Dado Configurações › O que o Cajui aprendeu, quando aberta, então cada regra aparece com a data e o lançamento que a criou, e pode ser apagada.
- Dado uma única correção, quando feita, então nenhum lançamento antigo muda de categoria.
- Dado a categoria "lazer" com 5 propostas e 3 corrigidas, quando a próxima captura chega, então "lazer" não é proposta em zona alta (RN-792), e Configurações mostra a taxa real: "acertei 2 de 5".

## UC-CAPT-07 — Comprovante de pagamento de fatura

**Grava:** `StatementSettled` · **Regras:** RN-343, RN-756, RN-757

**Aceite:**
- Dado um PDF "Pagamento de fatura — R$ 1.240,00", quando compartilhado, então abre a tela de **liquidação**, com o cartão sugerido, e não a de despesa.
- Dado só a IA indicando pagamento de fatura, sem as regras concordarem, quando a captura abre, então o app pergunta o tipo do documento antes de propor.
- Dado a liquidação confirmada, quando o mês é recalculado, então nenhuma despesa foi acrescentada.

## UC-CAPT-08 — Capturar sem rede

**Regras:** RN-780 a RN-785

**Erros:** `E-SYNC-01` comando da fila rejeitado pelo servidor.

**Aceite:**
- Dado o aparelho em modo avião, quando um comprovante é compartilhado, então original guardado, leitura e classificação por regras acontecem, e a categoria nunca vem em zona alta sem regra aprendida (RN-782).
- Dado o lançamento confirmado sem rede, quando a rede volta, então ele sobe uma única vez, mesmo que o envio seja repetido (chave de idempotência).
- Dado um comando da fila recusado pelo servidor, quando isso acontece, então ele volta para "Para conferir" com o motivo escrito, e nada se perde.
- Nenhum comprovante é perdido por falta de rede: RNF-REL.

## UC-CAPT-09 — Arquivo repetido e lançamento parecido

**Regras:** RN-220, RN-221, RN-725, RN-726

**Aceite:**
- Dado o mesmo PDF compartilhado de novo, quando recebido, então o app avisa "Este comprovante já virou um lançamento em 12/09…" e oferece abrir o lançamento ou lançar mesmo assim.
- Dado um segundo café de R$ 8,50 na mesma padaria no mesmo dia, quando capturado, então o app **pergunta** se é outro; não bloqueia nem descarta.
