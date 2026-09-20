# Jornadas

As nove jornadas da [persona primária](personas-and-journeys.md), com os números do [exemplo de setembro de 2026](rules/indicators.md#exemplo-completo). Setembro começa numa terça; o cartão final 4821 fecha dia 25 e vence dia 5. As jornadas A a E e G a I formam um único mês, coerente com a tabela de limites semanais do exemplo; a F usa o cenário alternativo do conserto de R$ 700.

Cada tabela traz o que a pessoa faz, o que pensa e sente, o que o Cajui faz e as regras envolvidas. Texto de tela vem entre aspas e segue o [guia de voz](../brand/voice-and-tone.md). Captura, retorno e assistente são citados pela área (RN-7xx, RN-8xx, RN-9xx) e pelas decisões `D-UX-NN`; `Qn` aponta para as [questões abertas](personas-and-journeys.md#questões-abertas).

## A — Primeiro uso: sair da planilha

**Seg., 31 de ago., à noite, com a planilha aberta ao lado.** Requisito: do primeiro toque ao painel em menos de 10 minutos, para 15 itens (3 rendas, 4 fixos, 5 variáveis, 1 cartão, 2 dívidas). Cada passo concluído já está gravado; dá para parar e voltar.

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Pareia o aparelho e cadastra salário R$ 2.400 (dia 5), segunda renda R$ 800 (dia 20) e vale R$ 600 (dia 1); informa que o vale tem R$ 50 hoje | "Na planilha eu somava tudo." | Mostra dois números lado a lado e diz por que não soma: "Entram R$ 3.200 em dinheiro e R$ 600 em vale." | RN-130, RN-111, RN-121, RN-123, Q1 |
| 2 | Cadastra os 4 fixos com dia e forma habitual; tenta incluir a luz | Pressa; copia da planilha | Pergunta "O valor muda todo mês?" e leva a luz para os variáveis. "Fixos: R$ 1.300." | RN-410, RN-413 |
| 3 | Informa as faixas dos 5 variáveis | "Não sei o mínimo de farmácia." | Aceita mínimo R$ 0; mercado nasce elegível ao vale: "Mercado entra por R$ 800: R$ 650 no vale e R$ 150 em dinheiro." | RN-420, RN-421, RN-113, RN-425 |
| 4 | Cadastra o cartão final 4821 (fecha 25, vence 5); tenta criar "fatura" como fixo | Hábito da planilha | Explica o fechamento com exemplo ("compra no dia 25 já cai na fatura seguinte"). Recusa a "fatura" dizendo o que fazer: "Cartão entra como forma de pagamento. Lance as compras; a fatura aparece sozinha." | RN-301, RN-302, RN-303 |
| 5 | Cadastra o empréstimo (12 × R$ 212, 4 pagas, dia 15) e a geladeira (10 × R$ 150 no cartão, em andamento) | Desconforto ao ver as dívidas juntas | Cada uma com o já pago ao lado do que falta; total só no rodapé. "Empréstimo: faltam 8 parcelas de R$ 212. No ritmo atual, quita em abril de 2027." | RN-501, RN-502, RN-510, RN-531, RN-541, Q2 |
| 6 | Vê o primeiro painel e confere com a planilha | Alívio: "bateu" | "Setembro no plano: sobram R$ 558." · "52% da renda comprometida." · "Limite da primeira semana: R$ 196, de terça a domingo." | RN-620, RN-630, RN-641 |
| 7 | Escolhe dia e hora do resumo semanal; ouve a prévia do som e decide | Curiosidade | Som desligado por padrão, com prévia e controle visível; resumo aos domingos, 20h, em canal silencioso | D-UX-19; retorno (RN-8xx) |

Onde pode dar errado:

- **Para no meio.** O painel funciona com dado parcial e diz o que falta: sem renda, "Cadastre sua renda para ver quanto dela está comprometido" (RN-135, RN-604).
- **Os números não batem com a planilha.** Quase sempre porque ela soma vale e dinheiro ou lança a fatura. Cada indicador mostra a própria conta, para a pessoa achar a diferença (RN-601).
- **Mínimo R$ 0 por desconhecimento** infla a folga ajustável (RN-661); o app sugere rever a faixa depois do primeiro fechamento.
- **Variável esquecido no cadastro.** O primeiro lançamento na categoria conta inteiro além do plano, e o app oferece criar a faixa (RN-424).
- **Geladeira cadastrada à mão** não tem lançamento de origem nem cartão apontado (Q2); **a primeira fatura** pode trazer compras de agosto (Q3).
- **Os 10 minutos** são requisito, não medição: confirmam-se em teste com a planilha real.

## B — Mercado pago parte no vale, parte no Pix

**Sáb., 12 de set.** O vale começou o mês com R$ 650; a compra grande do dia 5 levou R$ 480, e feira e padaria, R$ 140: restam R$ 30. A semana tem limite de R$ 236,25 e R$ 204,00 já gastos: restam R$ 32,25.

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | No caixa, R$ 86,00: passa o vale até zerar (R$ 30,00) e paga R$ 56,00 no Pix | Pressa, fila; "o vale acabou no meio da compra" | — | RN-122 |
| 2 | No app do banco, compartilha o comprovante do Pix com o Cajui | Quer resolver em segundos | Guarda o comprovante, confere duplicidade, extrai o texto no aparelho, mascara CPF e chave Pix e envia só o texto extraído. Se há regra aprendida para o estabelecimento, ela define a categoria antes da IA | RN-220; captura (RN-7xx); D-UX-08 |
| 3 | Confere a tela única: "Mercado Boa Compra · R$ 56,00 · hoje · mercado · Pix" | "Falta o pedaço do vale." | Pergunta: "Você ainda tinha R$ 30,00 no vale. Parte dessa compra foi no vale?" | Q4 |
| 4 | Toca em "Sim, R$ 30,00" | — | O lançamento passa a R$ 86,00, com duas linhas de pagamento: R$ 30,00 no vale e R$ 56,00 no Pix | RN-203, RN-204, RN-205, RN-112 |
| 5 | Lê o efeito, toca no valor e em "Lançar" | Um aperto ao ver que passa do limite; nenhum susto | "Vale: R$ 30,00 → R$ 0,00. Limite da semana: R$ 32,25 → passa R$ 23,75." Só a linha em dinheiro conta na semana; nada é bloqueado | RN-643, RN-647, D-UX-05 |
| 6 | Volta ao painel | "Sei onde estou." | "A semana passou R$ 23,75 do limite. A próxima já considera isso." · "O vale de setembro acabou. O mercado passa a sair do dinheiro: restam R$ 94 do previsto." | RN-642, RN-425, D-UX-03 |

Onde pode dar errado:

- **Sem rede no mercado.** O comprovante fica no aparelho, o texto é extraído ali e a proposta vem das regras locais. "Não consegui falar com o servidor. Seu lançamento está salvo no aparelho e ainda não foi enviado. Ele sobe sozinho quando a conexão voltar." Reenvio não duplica ([data-model.md](data-model.md)).
- **DeepSeek fora do ar.** "A classificação automática está fora do ar. Usei as regras locais — confira a categoria antes de salvar."
- **A parte do vale é esquecida.** O lançamento fica em R$ 56,00 e o saldo do vale no app (R$ 30) se afasta do real (R$ 0). Conserta-se corrigindo o lançamento (RN-208) ou ajustando o saldo (RN-123); a pergunta do passo 3 existe para evitar isso.
- **Vale informado maior que o saldo**: rejeitado, com a divisão proposta (RN-122).
- **Razão social no comprovante** ("BC Comércio de Alimentos Ltda") em vez do nome da fachada: a confiança cai e começa a jornada I.
- **OCR lê R$ 5,60 em vez de R$ 56,00.** O toque sobre o valor é a última barreira (D-UX-05); corrigir depois gera evento de correção (RN-208).
- **Compartilhou duas vezes**: o app avisa e oferece abrir o lançamento existente (RN-220, RN-221).

## C — Compra parcelada no cartão

**Sáb., 19 de set.** O fogão parou. Na loja: R$ 960,00 em 6× sem juros no cartão final 4821.

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Passa o cartão e compartilha o comprovante da compra | "R$ 160 por mês parece pouco." É o desacoplamento entre comprar e pagar | Lê valor, estabelecimento e "parcelado 6×"; propõe categoria "casa" e o cartão final 4821 | captura (RN-7xx); D-UX-05 |
| 2 | Confere a confirmação | Quer saber quando acaba | "Fogão · R$ 960,00 · casa · cartão final 4821 · parcelado em 6×" · "6 parcelas de R$ 160,00, de outubro a março · ainda comprometido R$ 960,00" | RN-311, RN-313, RN-102, RN-303 |
| 3 | Lê o efeito | Surpresa: a semana não muda, o futuro sim | "Esta semana não muda. Em outubro, as dívidas passam de R$ 362 para R$ 522: 57% da renda comprometida." | RN-312, RN-504, RN-630, RN-633 |
| 4 | Marca "fora do padrão", toca no total e em "Lançar" | Decisão consciente, sem culpa | Mostra o acumulado de fora do padrão do ano; grava o lançamento e cria a dívida `cardInstallment` de 6 parcelas, sem juros | RN-240, RN-241, RN-503 |
| 5 | Abre a tela de dívidas | Vê o fim | "Fogão: faltam 6 parcelas · R$ 960 · já pagos R$ 0. No ritmo atual, quita em março de 2027." | RN-531, RN-541 |
| 6 | De outubro a março, não faz nada | — | A parcela entra no plano do mês e na fatura, sem lançamento novo | RN-521, RN-431 |

Onde pode dar errado:

- **Compra no dia 25 ou depois** cai no ciclo seguinte: a primeira parcela conta em novembro, não em outubro (RN-303). Se o banco fecha de outro jeito, a conferência da fatura (jornada D) mostra, e corrige-se o dia de fechamento.
- **O OCR não lê o "6×".** A proposta viraria compra à vista de R$ 960 e derrubaria o limite da semana (RN-310). Em compra no cartão sem indicação de parcelas, a confirmação pergunta "À vista ou parcelado?"; corrigir depois custa dois toques (D-UX-07).
- **Parcelado com juros**: o lançamento é o valor à vista; a diferença aparece à parte, como juros do parcelamento (RN-314).
- **Rateio com resto** (R$ 1.000 em 3× dá 333,34 · 333,33 · 333,33, RN-102): o banco pode pôr o centavo em outra parcela, e ele aparece como "ainda não identificado" na fatura (RN-332).
- **O compromisso novo faz um mês futuro não fechar**: o passo 3 diz isso na hora, no tom da jornada F. Aqui outubro ainda fecha, com R$ 348 de sobra no plano.
- **Devolução da compra parcelada**: o estorno existe (RN-209 a RN-211), mas como ele encerra a dívida criada pela RN-503 ainda não está descrito.

## D — A fatura chega: conferir, achar o que falta, pagar

**Sáb., 26 de set.** O banco avisa: fatura fechada em R$ 860,00, vence seg., 5 de out. Na planilha, este era o dia da linha única que escondia tudo.

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Abre a fatura do cartão no Cajui | Apreensão; espera a confusão de sempre | "Fatura do cartão final 4821 · R$ 800,00 · vence seg., 5 de out. · variáveis R$ 290 · fixos R$ 200 · parcelas R$ 310" — calculada, nunca digitada | RN-330, RN-331 |
| 2 | Informa o total do banco: R$ 860,00 | "Cadê os R$ 60?" | "R$ 60,00 ainda não identificados nesta fatura." Abre os lançamentos do ciclo por data, para conferir com a lista do banco; não cria despesa de ajuste | RN-332 |
| 3 | Acha a farmácia de qua., 23 de set., R$ 60,00, nunca compartilhada; compartilha agora | Alívio por achar; nenhuma bronca | Lança com a data da compra: conta em setembro e nesta semana. "Limite da semana: R$ 75,00 → R$ 15,00." · "R$ 0 ainda não identificados." | RN-310, RN-643, RN-206 |
| 4 | Lê a composição | Entende, pela primeira vez, o que a fatura é | "Dos R$ 860,00, R$ 550,00 já foram contados em setembro e estão reservados; R$ 310,00 são parcelas que contam em outubro." | RN-320, RN-321, RN-311 |
| 5 | Sex., 2 de out.: recebe o lembrete | Sem surpresa | "Fatura de R$ 860,00 vence segunda. R$ 550,00 já estavam reservados; os R$ 310,00 de parcelas estão no plano de outubro. Pelos seus lançamentos, outubro segue com sobra." — declarado como estimativa | D-UX-20; retorno (RN-8xx) |
| 6 | Seg., 5 de out.: paga no banco e compartilha o comprovante | "Não contei nada duas vezes." | Reconhece pagamento de fatura e propõe **liquidação**, nunca despesa: "Pagamento da fatura · R$ 860,00 · cartão final 4821". Reserva: R$ 550,00 → R$ 0,00. As despesas de outubro não mudam | RN-343, RN-340, RN-341, RN-231 |

Onde pode dar errado:

- **Tenta lançar "fatura R$ 860" à mão**: impossível por construção (RN-207, RN-301); a mensagem explica e leva à liquidação.
- **Primeira fatura depois da adoção** pode trazer compras de 25 a 31 de ago., anteriores ao app, que ficariam para sempre como "não identificadas" (Q3).
- **A diferença não é achada.** Continua visível como "ainda não identificados", e a liquidação é aceita assim mesmo (RN-344). O app nunca fecha a conta com despesa inventada (RN-332).
- **Paga menos que o total.** O app pergunta o que foi combinado com o banco e registra o saldo como dívida, com os juros informados (RN-342), em tom sóbrio (RN-542).
- **Anuidade, juros ou multa na fatura**: lançamento comum em "juros e tarifas", pago com o cartão (RN-333).
- **O banco fecha o ciclo de outro jeito** (RN-303): a compra do dia 24 ou 25 falta numa fatura e sobra na seguinte.
- **Lembrete sem contexto de caixa** reduz multa e aumenta cheque especial (Medina2021): por isso o passo 5 nunca é só "pague" (D-UX-20).

## E — Domingo à noite: o resumo semanal

**Dom., 13 de set., 20h.** A semana de 7 a 13 passou do limite no sábado (jornada B).

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Recebe o aviso, silencioso | Espera bronca | Na tela bloqueada, sem valor negativo: "Resumo da semana pronto. Limite da próxima: R$ 226,47." | D-UX-19, D-UX-21 |
| 2 | Abre com a biometria | — | "Semana de 7 a 13 de set.: R$ 260,00 de R$ 236,25. Passou R$ 23,75 do limite. A próxima já considera isso: R$ 226,47 até domingo, 20." | RN-641, RN-642, RN-103 |
| 3 | Toca em "Ver a conta" | Desconfia do número | "Restam R$ 550,00 de variável para 17 dias; 7 deles são da próxima semana." O excesso se diluiu: o limite ficou só R$ 9,78 menor do que seria | RN-641, RN-601 |
| 4 | Percorre os lançamentos da semana e troca uma categoria | Quer a semana certa antes de virar a página | Correção em dois toques, com evento próprio; oferece lembrar do estabelecimento | RN-208, D-UX-07, D-UX-08 |
| 5 | Lê o que vem | Planeja | "Vale: R$ 0,00 desde sábado." · "Empréstimo: parcela 5 de 12, R$ 212,00, vence terça, 15." | RN-120, RN-504, D-UX-20 |
| 6 | Fecha o app em menos de 2 minutos | Tranquilidade | Nada mais a fazer; nenhuma meta nova imposta | D-UX-18 |

Onde pode dar errado:

- **Semana "boa" porque faltou lançar.** O app não sabe o que não foi lançado. Sem acusar: "Nenhum lançamento de quarta a sexta. Se faltou algum, dá para lançar agora com a data certa." O lançamento tardio recalcula o limite corrente (RN-646).
- **Lançamento de domingo chega depois do resumo.** O resumo é visão e se recalcula; o limite da semana seguinte só é definitivo na segunda (RN-641). O aviso já enviado pode ficar defasado: vale o texto da tela.
- **Mês com falta**: o aviso recorrente fica pausado (D-UX-21); o resumo continua dentro do app (Q6).
- **Propostas adiadas** aparecem no topo: "2 comprovantes esperando sua conferência." (Q10)
- **Ritmo errado para a pessoa**: dia, hora e periodicidade são configuráveis; não há evidência de que semanal seja melhor (D-UX-17).

## F — O mês que não fecha: do aviso ao plano de ajuste

**Cenário alternativo do exemplo: qui., 3 de set., antes de qualquer outro gasto, o celular quebra.** Conserto de R$ 700,00 no Pix. A curva emocional está em [personas-and-journeys.md](personas-and-journeys.md#f--a-curva-de-quem-leva-o-susto-e-volta).

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Paga e compartilha o comprovante | Aperto; "lá se foi o mês"; vontade de não olhar | Propõe "manutenção", categoria sem faixa: os R$ 700 contam além do plano. Oferece marcar fora do padrão | RN-424, RN-240, RN-241 |
| 2 | Lê o efeito na confirmação | Espera um número vermelho; encontra uma saída | "Com este lançamento, faltam R$ 142 para fechar setembro. Dá para cobrir sem mexer nos fixos." · "Ver os ajustes" · "Agora não" | RN-621, RN-622, RN-660 a RN-662, D-UX-22 |
| 3 | Toca em "Agora não" | Evitação: hoje não | Aceita sem insistir. Nenhum aviso recorrente; a falta fica no segundo nível do painel, em barro, com sinal, rótulo e ícone, ao lado do botão | RN-670, RN-671, D-UX-21 |
| 4 | Sáb., 5 de set.: lança o salário que entrou | Momento favorável: há dinheiro na conta | Ancora o retorno: "Salário lançado: R$ 2.400. Faltam R$ 142 para fechar setembro; separei os ajustes que cobrem isso." | RN-131, D-UX-21 |
| 5 | Abre "Ver os ajustes" | Surpresa: há margem | Do maior para o menor: lazer até R$ 150 · mercado até R$ 150 · farmácia até R$ 100 · transporte até R$ 80 · luz até R$ 60. "Dá para ajustar até R$ 540." Nenhum vem marcado; nenhum é tratado como supérfluo | RN-661, RN-662 |
| 6 | Escolhe lazer −R$ 100 (250 → 150) e transporte −R$ 42 (260 → 218) | Controle: foi ela quem decidiu | Contador no topo: "Falta ajustar R$ 142 → R$ 42 → R$ 0." Não aceita ajuste abaixo do mínimo da faixa | RN-420, RN-661 |
| 7 | Toca em "Aplicar os ajustes" | Alívio | Grava o plano de ajuste como ação explícita. "Setembro fecha no zero." Recalcula o limite das semanas seguintes | RN-663, RN-622, RN-640, RN-641 |

Onde pode dar errado:

- **O conserto também consome o limite da semana.** Pelo texto atual, o painel abriria em "a semana passou R$ 504 do limite" — o contrário do que a RN-670 pretende (Q5).
- **A falta é maior que a folga.** Conserto de R$ 1.200: faltam R$ 642. "Os variáveis cobrem R$ 540. Os R$ 102 restantes dependem de renda, de fixo ou de dívida." (RN-662), com atalho para cada um; o assistente simula (jornada H).
- **Vale com folga não resolve**: não compensa falta em dinheiro (RN-114), e o app não sugere isso.
- **Os ajustes nunca são abertos.** O mês fecha com falta; ela é informada no fechamento e não vira dívida automática (RN-443).
- **Depois do susto, a pessoa para de lançar.** É o risco central (Olafsson2025, Gladstone2021). As defesas são o passo 3 e a volta sem castigo (RN-252, RN-646).
- **Ajuste confundido com remanejamento.** Ajuste encolhe o plano de um variável; remanejamento cobre um bloco com folga de outro (RN-403). Os dois são explícitos e registrados.

## G — A virada do mês e o fechamento

**Qui., 1º de out.** Setembro terminou com R$ 940 de variável em dinheiro (170 + 260 + 200 + 230 + 80), R$ 40 abaixo do pior caso.

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Acorda com outubro pronto | — | Plano gerado na virada: vale R$ 0 + R$ 600; mercado em dinheiro R$ 200; dívidas R$ 522, com a parcela 1 de 6 do fogão. "Outubro no plano: sobram R$ 348." Primeira semana, de quinta a domingo: limite R$ 132,90 | RN-431, RN-121, RN-425, RN-644, RN-641 |
| 2 | Recebe: "Setembro está pronto para fechar. Leva 2 minutos para conferir." | Curiosidade | Lista o que está em aberto antes de fechar: fixo sem lançamento, renda sem recebimento, proposta adiada, valor não identificado em fatura | RN-414, RN-131, RN-332 |
| 3 | Lê "Como foi o mês" | Satisfação contida | Começa pelo cumprido: "4 fixos pagos · parcela 5 de 12 do empréstimo · 4 de 5 variáveis dentro do previsto." Depois: "Setembro fechou com R$ 598 de sobra, R$ 40 acima do plano." · "Lazer passou R$ 60 do previsto." · "Vale: R$ 650 usados." · R$ 86,73 por dia em dinheiro e R$ 21,67 em vale | RN-623, RN-423, RN-651, D-UX-13 |
| 4 | Lê "Como fica adiante" | Vê o horizonte | "Empréstimo: faltam 7 parcelas; no ritmo atual, quita em abril de 2027." · "Fogão: parcela 1 de 6 em outubro." · provisão de fora do padrão sugerida, sem impor | RN-531, RN-313, RN-432, D-UX-12 |
| 5 | Toca em "Fechar setembro" | Página virada | Grava o fechamento, imutável; a sobra não vira orçamento extra de outubro | RN-440, RN-422 |
| 6 | Sáb., 3 de out.: acha um ônibus de 28 de set., R$ 42,00, e lança | Receio de estragar o mês fechado | Aceita como lançamento tardio: "Setembro rev. 2: + R$ 42,00 em transporte, lançado em 03/10." A sobra passa a R$ 556; a versão anterior fica preservada; outubro não muda | RN-252, RN-441 |

Onde pode dar errado:

- **Tenta fechar antes do fim do mês**: rejeitado, com a data em que poderá (RN-442).
- **Nunca fecha.** Outubro funciona igual (RN-431); "pronto para fechar" fica disponível, sem aviso repetido.
- **Mês apertado.** Mesma estrutura, começando pelo cumprido; "Setembro fechou com falta de R$ 142." vem com o que dá para fazer, e nada é descontado de outubro por conta própria (RN-443, D-UX-13).
- **Semana partida** (28 a 30 de set., limite R$ 120; 1º a 4 de out.) confunde se o painel disser "até domingo" (Q9).
- **Renda recebida diferente da esperada**: o mês calcula com o recebido (RN-131); confere-se antes de fechar.

## H — No computador: entender o mês e conversar com o assistente

**Qui., 17 de set., à noite.** Dois dias depois de pagar a parcela 5 do empréstimo. A semana tem limite de R$ 226,47 e R$ 120,00 gastos.

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Entra no painel pela web | Quer o mês inteiro numa tela grande | Autentica pelo caminho da web, a definir na Fase 4 (BL-011). Mesmo número principal do celular: "Sobram R$ 106,47 até domingo." Nenhuma captura | RN-670 |
| 2 | Lê a composição da renda | Procura onde o dinheiro está preso | Uma barra empilhada sobre os R$ 3.200, com o número ao lado de cada parte: fixos R$ 1.300 (41%) · dívidas R$ 362 (11%) · variáveis pelo pior caso R$ 980 (31%) · sobra R$ 558 (17%). O vale em barra separada | RN-402, RN-111, RN-632, D-UX-16 |
| 3 | Pergunta: "Por que 52% da minha renda está comprometida?" | Quer a conta, não opinião | "Fixos de R$ 1.300 mais parcelas de R$ 362 somam R$ 1.662, de R$ 3.200 em dinheiro: 52%. Moradia responde por 40%." Os números vêm do cálculo do servidor | RN-602, RN-630, RN-631, D-UX-23 |
| 4 | Pergunta: "E se eu pagar R$ 100 a mais por mês no empréstimo?" | Esperança com pé no chão | "Faltam 7 parcelas, R$ 1.484. Pagando R$ 312 por mês, quita em fevereiro de 2027, dois meses antes. É projeção: usei o saldo nominal, sem juros, porque a taxa não foi informada; o efeito real é o que o credor aplicar." | RN-533, RN-510, RN-522, RN-531 |
| 5 | Pergunta: "Onde aplico a sobra?" | Testa o limite | Não recomenda produto financeiro; oferece comparar cenários do próprio orçamento | assistente (RN-9xx) |
| 6 | Vê um lançamento com categoria errada | Quer corrigir ali mesmo | Mostra o lançamento e indica o celular para a correção | Q7 |

Onde pode dar errado:

- **Recarregar a aba derruba a sessão**, que vive em memória porque front e API são sites diferentes: o retorno em um passo é desenho da Fase 3.
- **DeepSeek fora do ar.** "Não consegui falar com o assistente. O painel e os relatórios continuam funcionando, porque não dependem dele. Quer tentar de novo?" (RN-602)
- **A pergunta pede número que não está no contexto do assistente**: ele diz que não tem o dado, em vez de estimar. O contexto são resumos e agregados, nunca o banco inteiro.
- **Computador compartilhado**: `noindex`, sessão em memória, nada persistido no navegador.
- **Custo**: tokens são o único custo variável; o consumo é registrado por operação e fica visível.
- **Firefox e Safari** caem no caminho mais pesado do build; o orçamento de desempenho vale para Chrome e Edge, a confirmar no spike da Fase 4.

## I — O app pergunta porque ficou em dúvida, e a resposta vira regra

**Sex., 18 de set.** R$ 23,90 no débito, na loja de conveniência de um posto.

| # | A pessoa | Pensa e sente | O Cajui | Regras |
|---|---|---|---|---|
| 1 | Compartilha o comprovante: "AUTO POSTO CERRADO LTDA · R$ 23,90" | Pressa | Não há regra aprendida para o estabelecimento; a proposta vem com valor e data em confiança alta e categoria em confiança baixa | D-UX-06; captura (RN-7xx) |
| 2 | Lê a pergunta de esclarecimento | Acha justo: pelo nome, nem ela saberia | "Fiquei em dúvida entre transporte e lazer. O que foi essa compra de R$ 23,90 no posto?" Opções: transporte · lazer · outra categoria, nenhuma pré-selecionada. Nunca grava em "outros" para não perguntar | D-UX-06, D-UX-07 |
| 3 | Toca em "lazer": foi um lanche | — | "Vou lembrar: Auto Posto Cerrado é lazer." com "Desfazer" à vista. A regra é local, nasce desta resposta e não reclassifica o passado | D-UX-08 |
| 4 | Toca no valor e em "Lançar" | Sente que ensinou algo | Lança em lazer, mostra o efeito na semana e conta a sugestão como corrigida, para a taxa real por categoria | RN-643, D-UX-09 |
| 5 | Sex., 25 de set.: mesmo posto, R$ 18,50 | Confere de relance | A regra aprendida roda antes da IA, sem gasto de tokens: "lazer" preenchida e editável, com a nota "lembrei da última vez". Um toque | D-UX-08 |
| 6 | Abre Configurações › Regras aprendidas | Quer ver o que o app sabe | Lista com origem e data; cada regra pode ser apagada | D-UX-08 |

Onde pode dar errado:

- **Estabelecimento ambíguo.** No mês seguinte a compra no posto é combustível, e a regra preenche "lazer". Como toda proposta passa pela confirmação (D-UX-07), o erro é visível; na segunda correção entra a Q8.
- **Pergunta demais cansa.** Três posições — perguntar sempre · só na dúvida · preencher e eu reviso — e limiares configuráveis (D-UX-06, D-UX-10). Categoria com taxa de acerto baixa sobe sozinha para "perguntar" (D-UX-09).
- **Resposta apressada e errada**: "Desfazer" na hora; depois, dois toques no lançamento e apagar a regra.
- **Sem tempo para responder**: "Responder depois" (Q10); até lá, o resta na semana fica defasado.
- **IA fora do ar**: não há pergunta em linguagem natural; o campo vem vazio com seletor, e as regras aprendidas continuam valendo (D-UX-06).
- **O nome no comprovante varia** (razão social, filial). A regra usa o estabelecimento normalizado; normalização ruim faz a regra não disparar, e o fluxo cai de novo na pergunta — nunca em erro silencioso.
- **Primeiro compartilhamento da vida**: antes de tudo, a tela curta de expectativa — o que é lido, um acerto, um erro, tudo editável (D-UX-10).
