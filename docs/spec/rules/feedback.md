# RN-8xx — Retorno periódico

Formato e convenções em [README.md](README.md). Termos em [glossary.md](../glossary.md). Exemplos completos de cada resumo em [feedback.md](../feedback.md).

A planilha não avisa nada: só mostra a situação para quem abre. O retorno periódico é a resposta a esse silêncio — com o cuidado de não virar cobrança, porque cobrança afasta justamente quem mais precisa olhar (Olafsson2025, Gladstone2021).

## Princípios

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-801 | Todo número de um resumo vem do cálculo determinístico das RN-6xx. A IA, quando participa, só redige | O resumo semanal recebe `limite = 23625` e `gasto = 26000`; nunca soma lançamentos por conta própria | RN-602 |
| RN-802 | Todo resumo tem um **modelo de frase** determinístico. Com a IA fora do ar, sem orçamento de tokens ou com a saída rejeitada, o modelo produz o mesmo resumo, com os mesmos números | Desligar a IA não muda nenhum valor de nenhum resumo | prompt |
| RN-803 | Texto redigido pela IA só é aceito se: todo valor em reais que aparece nele existe no conjunto de números fornecido; nenhum termo da lista proibida do guia de voz aparece; o tamanho está dentro do limite do resumo. Reprovado, vale o modelo | Saída com "R$ 260" quando o fornecido foi "R$ 260,00" passa; com "R$ 300", é rejeitada | D-UX-22 |
| RN-804 | Nenhum resumo soma dinheiro e vale. O vale tem linha própria | "R$ 8,50 em dinheiro · R$ 38,40 no vale", nunca "R$ 46,90" | RN-111 |
| RN-805 | Nenhuma mensagem atribui falha à pessoa. Falta, limite ultrapassado e parcela em aberto são descritos como fato, seguidos de ao menos uma opção concreta | "A semana passou R$ 23,75 do limite. A próxima já considera isso: R$ 226,47." | D-UX-22 |
| RN-806 | Não existe sequência punitiva: o app pode constatar semanas seguidas dentro do limite, mas nunca anuncia que uma sequência "foi quebrada" | "Foi a terceira semana seguida dentro do limite." — e, na seguinte, nenhuma menção | D-UX-22 |
| RN-807 | Todo resumo é uma **visão**: recalcula-se quando um lançamento tardio ou uma correção muda o período. Vale o texto da tela, não o da notificação já enviada | Lançar no domingo às 22h um gasto de sábado atualiza o resumo da semana | RN-601 |

## Diário

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-810 | O resumo do dia está sempre disponível dentro do app, atualizado a cada lançamento | — | prompt |
| RN-811 | Conteúdo: gasto do dia por moeda, número de lançamentos, **resta na semana** (RN-642), lançamentos fora do padrão do dia e capturas em "Para conferir" | "Hoje: R$ 46,90 em 2 lançamentos. Sobram R$ 106,47 até domingo." | prompt |
| RN-812 | Dia sem lançamento é dito sem cobrança e sem insistência | "Nada lançado hoje." — e nada mais, salvo haver captura para conferir | D-UX-22 |
| RN-813 | A **notificação** diária nasce desligada e pode ser ligada, com horário escolhido (padrão 21h) | Instalação nova: nenhuma notificação diária | D-UX-19 ⚑ validar |
| RN-814 | O app **sugere** a marca de fora do padrão quando o valor é pelo menos o dobro da mediana dos lançamentos daquela categoria nos últimos 90 dias, havendo ao menos 5 lançamentos. Sugerir não é marcar | Mercado com mediana de R$ 160; compra de R$ 320: "o dobro do seu costume. Foi compra do mês?" | D-UX-11 ⚑ validar |
| RN-815 | O resumo diário usa sempre o modelo de frase, sem IA: é curto, formular e diário — não justifica o custo | — | modelagem ⚑ validar |

## Semanal

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-820 | O resumo semanal cobre a semana de calendário, de segunda a domingo. Em semana partida pela virada do mês, cada parte aparece com seu limite (RN-644) | 28/09 a 04/10: "28 a 30 de set.: limite R$ 120,00" e "1º a 4 de out.: limite R$ 132,90" | decisão 2026-09-19 |
| RN-821 | Conteúdo: limite da semana, gasto, diferença, as categorias variáveis que passaram do máximo da faixa no mês (RN-423), o limite da semana seguinte e o que vence nos próximos 7 dias | Ver [feedback.md](../feedback.md#semanal) | prompt |
| RN-822 | Quando a semana passa do limite, o resumo mostra **como o excesso se diluiu**: o limite seguinte e quanto ele ficou menor do que seria | "O limite ficou R$ 9,78 menor do que seria." | prompt · RN-641 |
| RN-823 | Por padrão, o resumo é entregue no **domingo às 20h**, com o limite seguinte como prévia; o limite só é definitivo na virada para segunda (RN-641). Dia e hora são configuráveis | Um lançamento no domingo às 23h recalcula o limite da segunda | D-UX-17 ⚑ validar |
| RN-824 | "Semana boa" pode ser falta de lançamento, e o app não sabe a diferença. Havendo dias seguidos sem lançamento, ele informa, sem acusar | "Nenhum lançamento de quarta a sexta. Se faltou algum, dá para lançar agora com a data certa." | modelagem |
| RN-825 | A notificação semanal nasce ligada, em canal de baixa prioridade, sem som nem vibração | — | D-UX-19 |

## Mensal

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-830 | A partir do dia 1, o app avisa uma vez que o mês anterior está pronto para fechar, e lista o que está em aberto: fixo sem lançamento, renda sem recebimento, captura pendente, valor não identificado em fatura | "Setembro está pronto para fechar. Leva 2 minutos para conferir." | RN-442 |
| RN-831 | O fechamento tem duas partes fixas, nesta ordem: **Como foi o mês** e **Como fica adiante** | — | D-UX-13 · Netemeyer2018 |
| RN-832 | "Como foi o mês" começa pelo que foi cumprido — fixos pagos, parcelas pagas, variáveis dentro do previsto — e só depois traz o resultado | "4 fixos pagos · parcela 5 de 12 · 4 de 5 variáveis dentro do previsto." | D-UX-13 |
| RN-833 | Em seguida: resultado realizado (RN-623) comparado ao planejado, os três blocos, variáveis que passaram do máximo, a linha **fora do padrão no mês**, o vale em seção própria e o custo por dia por moeda (RN-651) | "Setembro fechou com R$ 598 de sobra, R$ 40 acima do plano." | prompt |
| RN-834 | A comparação com o mês anterior mostra só mudança relevante: diferença de pelo menos R$ 30 **e** 15% numa categoria ou bloco, no máximo cinco itens, do maior para o menor | Transporte de R$ 218 para R$ 260 (+R$ 42, +19%) entra; luz de R$ 150 para R$ 158 não | modelagem ⚑ validar |
| RN-835 | "Como fica adiante" traz: dívidas e sua previsão de quitação (RN-531), parcelamentos e total comprometido (RN-313), compromissos já conhecidos dos próximos meses (RN-433) e até **três** sugestões, cada uma com valor | "Reservar R$ 146 para gastos fora do padrão." | prompt · D-UX-12 |
| RN-836 | As sugestões vêm, nesta ordem, de: ajuste necessário e folga ajustável (RN-660 a RN-662), provisão de fora do padrão (RN-432) e dívida que termina nos próximos três meses. Nenhuma é aplicada sozinha (RN-663) | — | prompt |
| RN-837 | Mês com falta tem a mesma estrutura e começa igualmente pelo cumprido. A falta é apresentada como valor a recompor, com o que dá para fazer; nada é descontado do mês seguinte por conta própria | "Setembro fechou com falta de R$ 142." + sugestões | RN-443 · D-UX-13 |
| RN-838 | A notificação mensal nasce ligada, em canal de baixa prioridade | — | D-UX-19 |

## Lembretes de vencimento

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-840 | Fixo, parcela de dívida e fatura geram lembrete dois dias antes do vencimento e no dia. Um lembrete por item e por momento; nada em cascata depois do vencimento | Aluguel do dia 10: lembrete no dia 8 e no dia 10; nenhum no dia 11 | D-UX-20 |
| RN-841 | Todo lembrete carrega **contexto de caixa**: valor, data e o efeito sobre o mês. Como o app não conhece o saldo da conta, o efeito é o resultado projetado (RN-621), e o texto se declara estimativa | "Fatura de R$ 640 vence sexta, 5. Pelo que está lançado, o mês continua com sobra de R$ 412 depois de pagar." | D-UX-20 · Medina2021 |
| RN-842 | Se pagar o item deixa o mês com falta, o lembrete diz isso e aponta para os ajustes ou para as dívidas, em vez de só mandar pagar | "… depois de pagar, faltam R$ 60 para fechar o mês. Ver os ajustes." | D-UX-20 · Medina2021 |
| RN-843 | Na tela bloqueada, nenhuma notificação mostra valor de falta, de dívida em aberto ou de limite ultrapassado: o texto é genérico e o número aparece dentro do app, depois do desbloqueio | "Resumo da semana pronto." | D-UX-21 |
| RN-844 | A preferência "ocultar valores nas notificações" esconde todos os valores, inclusive os favoráveis | "Resumo da semana pronto." em qualquer caso | modelagem |
| RN-845 | O retorno é ancorado em momentos favoráveis: renda lançada, vale creditado, semana fechada dentro do limite | Ao lançar o salário: "Salário lançado: R$ 2.400. Faltam R$ 142 para fechar setembro; separei os ajustes que cobrem isso." | D-UX-21 · Olafsson2025 |
| RN-846 | Enquanto o mês está com falta, nenhum aviso é recorrente: no máximo um por evento. Os resumos continuam disponíveis dentro do app | — | D-UX-21 |
| RN-847 | Cada tipo de aviso — vencimentos, diário, semanal, mensal — tem chave independente, com dia e horário próprios | Desligar o semanal não desliga os vencimentos | D-UX-19 |
| RN-848 | Todo aviso exibido grava `ReminderShown`. O fechamento mostra, para cada vencimento avisado, se o item foi pago em dia | "5 vencimentos avisados; 5 pagos em dia." | modelagem |
| RN-849 | Tocar num aviso abre, depois do desbloqueio, a tela do assunto, nunca o painel genérico | Lembrete da fatura abre a fatura | modelagem |

### Como o app decide cada lembrete

Numeradas na faixa do [Meu mês](meu-mes.md) (RN-1080 a RN-1089) porque leem o plano da planilha: Minhas contas, dívidas e cartões. O código está em `packages/domain/lib/src/reminders/`; o aparelho só marca e mostra o que o domínio escreveu.

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-1080 | Têm lembrete: a linha de "Minhas contas" com dia de vencimento e valor maior que zero, menos a paga no cartão (quem vence é a fatura); a parcela de dívida cadastrada, menos a de compra no cartão anterior ao app (vem na fatura, RN-521); e a fatura de cada cartão com valor em aberto. Linha sem dia ou sem valor não tem lembrete: não há o que avisar nem como saber se foi paga | Aluguel dia 10, Streaming sem dia e Música dia 12 paga no cartão: lembram o Aluguel e a fatura do cartão; Streaming e Música, não | decisão 2026-10-11 |
| RN-1081 | O lembrete chega às 9h, no relógio do aparelho, nos dois momentos da RN-840. A lista olha 35 dias à frente e é refeita a cada mudança do livro ou da chave; momento cujo dia já passou não é marcado, e o que não chegou até o fim do dia do vencimento não chega mais | Aluguel do dia 10, hoje 7/10: lembretes em 8/10 e 10/10, às 9h. Hoje 9/10: só 10/10. Hoje 11/10: nenhum de outubro; os de novembro, 8/11 e 10/11 | decisão 2026-10-11 · RN-840 |
| RN-1082 | Conta paga é conta coberta pelo gasto lançado no mês, na categoria dela. O gasto paga primeiro as linhas da categoria sem lembrete próprio, depois as com dia, do vencimento mais cedo ao mais tarde; a primeira que não fica coberta inteira, e as seguintes, seguem em aberto. Na dúvida, o lembrete vai: lembrete a mais incomoda, lembrete a menos custa multa | "Água, luz e internet" com Água 80,00 (dia 10), Luz 180,00 (dia 15) e Internet 90,00 (dia 20). Lançados 80,00: lembra Luz e Internet. Lançados 80,00 + 180,00: só Internet. Lançados 80,00 + 170,00: Luz e Internet — a luz que veio menor não cobre a estimativa | decisão 2026-10-11 |
| RN-1083 | Parcela paga é a que a contagem de pagas já alcançou: as que a pessoa disse no cadastro e as que ligou à dívida depois (RN-520). Na dívida de saldo informado, a contagem começa no primeiro vencimento depois do dia informado | Carnê de 10 parcelas de 120,00 desde outubro, dia 10, nenhuma paga: "Parcela 1 de 10". Com 1 paga: nada em outubro; em novembro, "Parcela 2 de 10" | decisão 2026-10-11 |
| RN-1084 | Fatura em aberto é a fatura calculada (RN-330), com as parcelas das compras anteriores ao app, menos o que já foi pago dela (RN-340). Zero ou menos, sem lembrete | Fatura de 300,00 que vence em 5/11: paga 300,00, nada; paga 100,00, lembra 200,00 | RN-330 · RN-340 |
| RN-1085 | O título diz o que vence e quando; o texto, o valor e o efeito sobre o mês do vencimento, pelo resultado projetado (RN-841). A fatura lembra que as compras já contaram. Na tela bloqueada, sem nome e sem valor — mais estrito que a RN-843 | "Aluguel vence sábado, 10" · "R$ 1.000,00. Pelo que está lançado, outubro continua com sobra de R$ 930,00 depois de pagar." · bloqueada: "Uma conta vence sábado, 10" e "Desbloqueie para ver o valor." | RN-841 · RN-843 |
| RN-1086 | Mês do vencimento com falta: o texto diz quanto falta e aponta Minhas contas (ou Minhas dívidas, na parcela), e o vencimento avisa uma vez só — o primeiro momento que chegar; o outro fica em silêncio (RN-842, RN-846) | O mesmo plano com renda de 2.000,00: "… depois de pagar faltam R$ 240,00 para fechar outubro. Dá para rever em Minhas contas."; chegou o do dia 8, o do dia 10 não chega | RN-842 · RN-846 |
| RN-1087 | Tocar abre o assunto: conta, Minhas contas; parcela, Minhas dívidas; fatura, Cartões de crédito | Lembrete do carnê abre Minhas dívidas | RN-849 |
| RN-1088 | A chave "Lembrar das contas a vencer", em Ajustes, nasce ligada e não depende das outras (RN-847). Desligada, o app entrega lista vazia e o aparelho desmarca tudo. Ligada sem permissão de notificar (Android 13 em diante), a linha diz isso e o toque pede a permissão | Desligar a chave: nenhum lembrete marcado; a revisão de domingo continua | RN-847 |

## Geração e custo

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-850 | Os números de cada resumo são calculados no servidor; a redação por IA dos resumos semanal e mensal roda em lote, fora do horário de pico da DeepSeek, e fica guardada até a entrega | — | prompt |
| RN-851 | O app monta o resumo pelo modelo de frase a partir dos dados locais quando não há rede | — | prompt |
| RN-852 | Cada redação por IA grava `AiUsageRecorded` com a operação (`weeklySummary`, `monthlySummary`) | — | prompt |
| RN-853 | A web mostra os mesmos resumos, em modo consulta | — | decisão 2026-09-19 |

## Modos de exibição

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-860 | Todo relatório tem dois níveis: **simplificado** (os números essenciais) e **detalhado** (tudo). Trocar de nível nunca muda um número, só quantos aparecem | O fechamento simplificado mostra resultado, três blocos, vale e sugestões; o detalhado acrescenta categorias, comparação e lançamentos | prompt |
| RN-861 | A preferência **mais visual** ou **mais numérico** troca a forma, não o conteúdo: o visual usa gráfico onde há parte-todo ou progresso; o numérico usa tabela | — | prompt |
| RN-862 | Gráfico só onde há parte-todo — uma barra empilhada de fixos, variáveis e dívidas sobre a renda, e o vale em barra separada —, progresso, ou o mês a mês (uma barra por mês, para cima o que sobrou e para baixo o que faltou; escolha do dono em 11/10/2026, ADR-026). Todo gráfico tem o número equivalente em texto | — | D-UX-16 · Ancker2006 |
| RN-863 | O resumo diário só tem o nível simplificado | — | modelagem |
| RN-864 | Nível e forma são preferências do aparelho, lembradas entre sessões, e valem também para a web | — | prompt |

## Revisão da semana e widget

Ver [ADR-025](../../architecture/adr/ADR-025-notificacoes-do-banco.md).

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-870 | No domingo, perto das 10h, se há gasto dos últimos sete dias — contando hoje — em Outros ou lançado sozinho pela notificação do banco, e ainda não revisto, chega um aviso em canal de baixa prioridade, sem som (RN-825). Sem nada para revisar, nenhum aviso | "3 gastos da semana ficaram para conferir. Confere em 1 minuto?"; gasto em Outros de dez dias atrás não conta | decisão 2026-10-11 |
| RN-871 | A revisão mostra cada gasto com as categorias a um toque: trocar é corrigir (RN-208); tocar na que ele já tem confirma, sem gravar fato. "Está tudo certo" marca o resto como revisto. O revisto fica só no aparelho e nunca sobe ao servidor | Tocar "Padaria" no gasto em Outros corrige e o tira da lista | decisão 2026-10-11 |
| RN-872 | O widget da tela inicial mostra o que resta na semana (RN-642), o mesmo número do painel, com os botões de câmera e galeria. Sem faixas no plano, mostra o gasto do mês. Passada a semana do número, pede para abrir o app. Nunca mostra o valor do que passou do limite | Plano com 410,00 de variável em dinheiro, semana de 14 a 20 de setembro: "Pode gastar esta semana · R$ 168,82" | decisão 2026-10-11 · RN-843 |
