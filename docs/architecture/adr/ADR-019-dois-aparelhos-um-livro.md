# ADR-019 — Dois aparelhos, um livro: a edição mais nova vence

**Estado:** aceita · 27/09/2026 — por delegação do dono ("eu quero sincronização, pois eu tenho 2 celulares")
**Substitui em parte:** [ADR-012](ADR-012-modo-offline.md), no que diz sobre conflito entre aparelhos (`E-SYNC-02` com escolha manual)
**Relacionada:** [ADR-004](ADR-004-registro-de-eventos-em-json.md) (o registro só de acréscimo) · [ADR-008](ADR-008-autenticacao.md) (a sessão que a subida precisa)

## Contexto

Até aqui o caminho dos dados era de mão única: o celular mandava, o servidor guardava, a web e o assistente liam. Nenhum aparelho **baixava** o que o servidor tinha — cada um lia só o próprio registro cifrado. Com dois celulares cadastrados, lançar num deles não aparecia no outro; se os dois lançassem, o servidor ficava com a soma e cada celular com a sua metade (BL-062).

O dono tem dois celulares e esperava, desde o começo, que os dois mostrassem a mesma coisa. Há um usuário só, e os dois aparelhos são dele.

A ADR-012 previa, para o caso de dois aparelhos editarem o mesmo lançamento, o conflito `E-SYNC-02` com **escolha manual** — "o app relê o estado e mostra as duas versões". Essa escolha nunca foi construída: o servidor não produz `E-SYNC-02`, e uma tela de "qual das duas vale?" é mais uma coisa a manter para um caso que, entre dois celulares da mesma pessoa, é raro e de baixo prejuízo (uma correção de valor perdida, que a pessoa refaz).

## Decisão

1. **Cada sincronização sobe e depois desce.** O `LedgerSync` manda ao servidor o que falta e, na sequência, o `LedgerPull` compara o que o servidor tem com o livro deste aparelho e grava **só a diferença** — como fatos locais comuns, cada um com chave que nasce do conteúdo, para que descer duas vezes grave uma. O registro do aparelho continua só de acréscimo (ADR-004) e não sabe que um fato veio de fora.

2. **O servidor é o ponto de encontro, não o dono.** Ele não decide nada sozinho: lista o que tem, inclusive o que **já foi cancelado** (`cancelledIds`), e aplica a mesma regra de desempate que os aparelhos aplicam.

3. **Quem manda em cada conflito:**

   | O quê | Regra | Por quê |
   |---|---|---|
   | Lançamento novo | Entra em todo aparelho que não o tem | Não há conflito possível |
   | Correção | **A mais nova pelo carimbo** (`Entry.revisedAt`, UTC, gravado por quem corrigiu) — e não a que chegou por último | Quem ficou sem rede um dia inteiro não apaga, ao voltar, o que o outro corrigiu de manhã |
   | Plano do mês | A mais nova pelo carimbo (`MonthSetup.definedAt`) | Mesmo motivo |
   | Cancelamento | O que um cancelou, os outros cancelam. **Nunca o contrário**: nada recria o que o servidor diz que morreu | Cancelar é a decisão mais deliberada que existe no app (RN-208, RN-995) |
   | Estorno, renda, acerto do vale, cartão | Por identificador: quem não tem, ganha | São fatos, não versões |

   A régua é uma só, `EditStamp.isNewer`, no domínio: carimbo mais novo vence; sem carimbo aqui, nunca; sem carimbo lá, sempre; sem carimbo dos dois lados — registros de antes desta ADR —, ninguém, e vale o que já está.

4. **A versão mais velha não sobe por cima.** Antes de mandar uma correção, o aparelho compara o próprio carimbo com o do servidor; se o do servidor é mais novo, não manda — a descida traz a versão nova para cá. O servidor confere de novo (T-05): `PUT /v1/entries/{id}` com carimbo mais velho que o guardado responde `kept: true` e não grava nada.

5. **A assinatura do lançamento passa a cobrir todo o conteúdo** — valor, data, categoria, descrição, linhas de pagamento, número de parcelas e "fora do padrão". Antes eram só os quatro campos que mudavam número na resposta do assistente; com dois aparelhos, uma correção que só troca a forma de pagamento também precisa atravessar — é ela que diz se saiu do vale ou do dinheiro (RN-111).

6. **Só o que foi cancelado neste aparelho é cancelado no servidor.** "O servidor tem e eu não" também descreve o que o outro aparelho acabou de lançar e ainda não desceu. O `LedgerBook` passa a lembrar o que cancelou (`cancelledIds`), e é só isso que sobe como cancelamento. Foi o defeito que o teste de ponta a ponta achou primeiro: o celular B apagava no servidor o que A tinha lançado.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Conflito com escolha manual (`E-SYNC-02`, ADR-012) | Uma tela a mais, para um caso raro entre dois aparelhos da mesma pessoa. O prejuízo de perder uma correção é uma correção refeita; o prejuízo de uma tela de conflito mal feita é a pessoa não entender o próprio livro |
| "Quem sincronizou por último vence" | É o que acontecia por acidente no plano do mês, e é a pior regra possível com rede móvel: quem fica sem sinal apaga o trabalho do outro ao voltar |
| Contador de versão por lançamento (ADR-004, item 5) | Precisa de um "estado conhecido" por aparelho para saber de que versão se partiu, e o app não guarda marcador de sincronização de propósito — o servidor é o marcador. O carimbo de edição dispensa isso |
| Fundir os dois registros de eventos preservando a cadeia de hash | A cadeia é por aparelho e sequencial (ADR-004); fundir exigiria reescrever registros, que é exatamente o que o registro só de acréscimo proíbe. Descer **fatos novos** para cada registro resolve o mesmo problema sem tocar em nenhum registro antigo |
| CRDT | Resolve concorrência entre muitos escritores; aqui são dois aparelhos de uma pessoa, e o custo em código e em explicação não se paga |

## Consequências

- **Bom:** lançar, corrigir, cancelar, estornar, receber renda, acertar o vale, cadastrar cartão e editar o plano em qualquer um dos dois celulares chega ao outro na próxima sincronização — e a web e o assistente continuam vendo o total.
- **Bom:** sincronizar de novo não duplica nada, em nenhum dos lados; um aparelho reinstalado se completa sozinho a partir do servidor.
- **Custo:** o desempate depende dos **relógios dos dois aparelhos**. Um celular com hora errada pode ganhar ou perder uma disputa que não devia. Celular sincroniza a hora pela rede, então na prática não acontece — mas é uma restrição declarada, não um problema resolvido.
- **Custo:** o que o outro aparelho fez só chega **quando este sincroniza** — ao abrir o app, ao voltar do segundo plano, depois de cada lançamento e antes de uma pergunta ao assistente, sempre com sessão aberta, ou em Ajustes → Enviar ao servidor. Não há empurrão do servidor para o aparelho.
- **Limite:** o servidor recalcula o plano de parcelas a partir do cartão e **ignora o valor da parcela** que o app manda (T-05, BL-054). Por isso os **juros de uma compra parcelada não atravessam**: no outro celular a compra chega com as parcelas certas e os juros zerados. Registrado como BL-063.
- **Limite:** a correção que **só** muda o valor da parcela com juros não é vista como correção pela assinatura — de propósito, para uma compra com juros não parecer corrigida para sempre. É o mesmo limite do item anterior.
- `E-SYNC-02` continua no catálogo, sem produtor. Sai dele quando o catálogo for revisado.

## Como se confere

- `app/test/features/ledger/two_phones_test.dart`: dois `ProviderContainer` — dois celulares, com relógios diferentes de propósito — sobre o mesmo `FakeExchange`, que guarda e devolve como o servidor de verdade. Oito cenários: lançar, não duplicar, corrigir, corrigir só a forma de pagamento, cancelar sem ressuscitar, duas correções concorrentes, plano mais novo, cartão com compra parcelada.
- `app/test/features/ledger/ledger_sync_test.dart`: a versão mais velha não sobe por cima; a mais nova sobe; o que o servidor tem e o aparelho nunca teve não é cancelado.
- `server/test/sync_state_test.dart`: cancelado fica listado; não ressuscita por `POST` nem por `PUT`; correção e plano mais velhos não apagam os mais novos; sem carimbo, vale o último.
- `packages/domain/test/shared/edit_stamp_test.dart` e `packages/api_contract/test/entry_revision_codec_test.dart`.
