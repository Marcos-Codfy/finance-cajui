# ADR-026 — UX viva: os efeitos no design system, o sensor no app

**Estado:** aceita · 11/10/2026. O dono escolheu as sete ideias de movimento e som da rodada:

1. o pote de água da semana, que esvazia e balança com o celular;
2. os cartões 3D, que inclinam e viram para mostrar o limite;
3. números que rolam e voam do Início para o detalhe;
4. a semente ao lançar e a folha ao desfazer, com vibração leve;
5. o brilho discreto quando o mês fecha no verde;
6. as barras do mês a mês com mola;
7. a Juju respondendo palavra por palavra.

**Relacionada:**
- [ADR-016](ADR-016-motor-de-audio.md): os sons como tokens.
- [ADR-023](ADR-023-meu-mes.md): os números da planilha que os efeitos mostram.
- RN-862: gráficos e números em texto.

## Contexto

Os efeitos precisam ser os mesmos na gallery, na web e nos testes. Só um deles depende de hardware: a inclinação, lida do acelerômetro do Android.

Ler o sensor custa bateria. Também não pode haver nada se mexendo em laço (WCAG 2.2.2).

## Decisão

1. **Os efeitos moram no design system.** São eles: `CajuiWaterGauge`, `CajuiCreditCard3D`, `CajuiRollingAmount`/`CajuiCountUp`, `CajuiHeroNumber`, `CajuiGlow`, `CajuiBarChart` e `CajuiChatBubble(streamed:)`, além dos sons `entrySaved` e `undone`. Todos respeitam o movimento reduzido. Nenhum lê sensor.
2. **A inclinação é uma porta do app** (`TiltSource`). A raiz de composição liga o acelerômetro (`sensors_plus`) só no Android. Na web e no teste não há fonte, e os componentes ficam parados e completos.
   - O sinal passa por um filtro passa-baixa.
   - A pose de repouso (uns 40°) é descontada.
   - O sensor só roda enquanto uma tela **à vista** pedir. "À vista" é `TickerMode`: a aba escondida e a tela coberta não contam. O sensor para quando o app vai para o fundo.
3. **O cartão 3D não mostra número de cartão.** O Cajui não o guarda. A frente mostra os dias de fechamento e de vencimento, e o cartão só aparece quando há limite informado, porque o verso é o uso do limite.
4. **A festa do mês no verde é uma vez por mês.** O mês festejado fica nas preferências (`celebratedMonth`).
   - A festa começa na primeira vez que o mês fecha no verde **à vista**. O Início monta por baixo da conversa, e festa que ninguém vê não conta.
   - Depois de começada, ela não recomeça ao voltar à aba.
   - Mês em que falta não brilha.
5. **O número do mês voa** do cartão do Início para o alto do Meu mês, com a mesma etiqueta (`MonthPage.resultTag`).
6. **Os botões cuja ação tem som próprio ficam mudos** (`CajuiButton(silent: true)`): "Lançar" e "Desfazer". Sem isso, o toque abafaria a semente e a folha.

## Consequências

- Há uma dependência nova, `sensors_plus` (BSD-3, sem custo e sem permissão no Android).
- A RN-862 passa a admitir o gráfico de barras do mês a mês. Ele cumpre a outra metade da regra: todo valor tem o número em texto.

**Não validado:**
- o ritmo real das molas no aparelho;
- os sons e a vibração ouvidos e sentidos no Poco;
- a inclinação com o sensor de verdade.

Tudo isso vai no APK da rodada.
