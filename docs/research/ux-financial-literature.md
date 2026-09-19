# Literatura de UX financeira

| | |
|---|---|
| Escopo | Seis temas: ansiedade e evitação, contabilidade mental, categorização automática, frequência de feedback, tom de voz, visualização |
| Fontes | Literatura revisada por pares (CHI, MobileHCI, JCR, JMR, Management Science, RFS, AER, REStat, JEL, OBHDP) + um relatório de indústria, marcado como tal |
| Acesso | 2026-09-19 |
| Conferência | Todo DOI abaixo foi consultado em `api.crossref.org/works/<DOI>`: título, autores, periódico, volume, páginas e ano batem com o citado |

## Como ler este documento

Cada decisão de produto carrega a **força da evidência** que a sustenta:

| Rótulo | Significa |
|---|---|
| **Direta** | O estudo observou finanças pessoais do dia a dia |
| **Análoga** | O mecanismo foi medido em outro domínio (investimento, saúde, e-mail) e transferido por raciocínio |
| **Projeto** | Não há estudo; é julgamento de design, declarado como tal |

A maior parte das decisões de tela é **Análoga** ou **Projeto**. Isso não as invalida — significa que elas ficam configuráveis e que o próprio uso do app é o teste.

## Achados por tema

### 1. Ansiedade financeira e evitação

- Em painel de alta frequência com dados bancários e registro de logins, as pessoas olham **mais** as finanças quando têm caixa e recebem renda, e a atenção **cai** quando o saldo passa de positivo para negativo — e cai mais conforme a dívida cresce [Olafsson2025]. É observacional: mostra quando as pessoas olham, não o efeito de uma tela.
- O mesmo padrão aparece em investidores: monitoram mais a carteira em mercado em alta [Karlsson2009], e os logins caem depois de quedas [Sicherman2016].
- A revisão de [Golman2017] explica o mecanismo: informação entra direto no bem-estar, então existe incentivo para evitá-la mesmo quando é útil e gratuita.
- A **vergonha** financeira leva a afastamento e desengajamento das próprias finanças, o que piora as decisões e aprofunda o aperto, em ciclo; é mais danosa que a culpa, e uma intervenção de autoafirmação enfraqueceu o elo [Gladstone2021] (seis estudos, 9.110 participantes).
- Usar **vermelho** para representar dados financeiros altera preferência de risco, expectativa de retorno e decisão de negociação; o efeito some em daltônicos e se atenua na China [Bazley2021]. Testado só em investimento.

### 2. Contabilidade mental

- As pessoas organizam dinheiro em contas mentais, com orçamentos por categoria e uma frequência de avaliação; isso viola a fungibilidade e muda escolhas [Thaler1999].
- Dinheiro carimbado é mais preservado quando **dividido em partes** do que reunido, e um lembrete visual da meta aumenta a poupança [Soman2011] (domicílios de baixa renda).
- **Benefício alimentar não é tratado como dinheiro**: a propensão a gastar em comida a partir do benefício SNAP é de 0,5 a 0,6, muito maior que a partir de dinheiro, mesmo quando os dois seriam economicamente equivalentes [Hastings2018]. É o análogo mais próximo do vale alimentação.
- **Cartão de crédito desacopla compra e pagamento**: a "dor de pagar" enfraquece com cartão e é forte com dinheiro vivo [Prelec1998]. Gasto passado só freia gasto futuro se a pessoa lembra do valor e sentiu o pagamento — o que depende de "ensaiar" o valor e de a saída ser imediata [Soman2001].
- Quitar contas de dívida inteiras prediz eliminar a dívida, independentemente do valor das contas fechadas [GalMcShane2012].

### 3. Categorização automática

- Único número revisado por pares encontrado: classificador de descrições de extrato (bancos espanhóis, 30.844 transações, 15 categorias) com precisão macro de 95,05%, revocação de 87,51% e F por categoria de 80% a 97% [GarciaMendez2020]. É texto de extrato, não OCR de comprovante em português: serve de **teto otimista**, não de meta.
- Decisão sob incerteza: dois limiares de confiança separam **não agir**, **perguntar** e **agir sozinho**; usar diálogo para resolver a dúvida, minimizar o custo do palpite errado, fazer menos quando incerto [Horvitz1999].
- Diretrizes para interação com IA: deixar claro quão bem o sistema funciona, facilitar a correção, desambiguar ou degradar na dúvida, explicar o porquê, aprender com o uso, adaptar com cautela [Amershi2019].
- Com a **mesma** acurácia, o tipo de erro muda a aceitação; e ajustar a expectativa antes do primeiro uso (indicador de acurácia, exemplos, controle do limiar) aumenta satisfação [Kocielnik2019].

### 4. Frequência de feedback e lembretes

- Lembretes aumentam o cumprimento de metas de poupança; funcionam melhor quando citam a meta específica [Karlan2016] (três experimentos de campo).
- **Efeito colateral medido no Brasil**: lembretes para pagar a fatura do cartão reduziram multas por atraso em 14%, mas aumentaram tarifas de cheque especial em 9% — quem já tinha histórico de cheque especial saiu perdendo [Medina2021].
- Feedback mais frequente leva a foco excessivo no dado mais recente e pode **piorar** a decisão em ambiente com ruído [Lurie2009] (laboratório, gestão de estoque).
- Notificação em excesso está associada a emoções negativas [Pielot2014] (15 usuários); conteúdo útil também interrompe [Mehrotra2016].
- Relatório de indústria, não revisado: em 9.035 usuários por 13 semanas, orçamento semanal único, orçamento por categoria e simples resumo **não diferiram** no gasto; quem orçou gastou 1,3 a 1,4 vez o pretendido, e 84% viram o orçamento 5 vezes ou menos [IrrationalLabs2020].

### 5. Tom de voz

- Bem-estar financeiro percebido tem dois componentes distintos: **estresse atual** com o dinheiro e **segurança futura esperada** [Netemeyer2018].
- A base para linguagem não-julgadora é o mecanismo de [Gladstone2021] e [Golman2017] — vergonha e evitação —, não um teste de microcopy.

### 6. Visualização

- O que melhora a precisão do raciocínio quantitativo não é o mesmo que muda comportamento; gráficos de **parte-todo** ajudam, mostrar só o numerador infla a percepção; **não se deve presumir que gráfico é mais intuitivo que texto** [Ancker2006] (revisão sistemática, saúde).
- Meta fácil de visualizar parece mais próxima e aumenta o esforço — mas o benefício aparece **perto do fim** e diminui quando a meta é quebrada em submetas [Cheema2011].
- Gastos **excepcionais** são subestimados no total e inflados um a um, porque cada um é tratado como caso isolado; mostrá-los como conjunto reduz o viés [Sussman2012] (sete estudos).

## O que não encontrei

Buscado e não achado em literatura revisada por pares. Nenhuma citação foi criada para preencher estes espaços.

| Pergunta | O que existe de mais próximo |
|---|---|
| **Tela inicial com número vermelho faz o usuário endividado parar de abrir o app?** | Nenhum experimento manipula a tela inicial e mede abertura. A hipótese é coerente com Olafsson2025, Gladstone2021 e Bazley2021, mas é **extrapolação** |
| Efeito do vermelho em saldo, déficit ou dívida (e com público brasileiro) | Só investimento [Bazley2021] |
| Diário × semanal × mensal em finanças pessoais | Nada direto. Lurie2009 é laboratório; IrrationalLabs2020 só testou semanal |
| Número ótimo de notificações em app financeiro | Só blogs de fornecedor sem método. O teto do Cajui é decisão de projeto |
| Redação julgadora × descritiva testada em app financeiro | Nada; só mecanismo |
| Gráfico × número em tela de orçamento pessoal | Só comunicação de risco em saúde |
| Barra de progresso para quitação de dívida parcelada | Metas financeiras em geral [Cheema2011]; contas de dívida [GalMcShane2012] |
| Precisão de categorização a partir de OCR de comprovante, em português, com LLM | Só extrato em espanhol com SVM |
| Custo cognitivo de corrigir categoria × digitar do zero | Aparece em patentes como alegação sem dado; não usado |
| Vale alimentação brasileiro como conta mental; parcelamento no cartão | Análogo americano [Hastings2018]. Pistas brasileiras vistas e **não conferidas** ficaram de fora |

## Decisões de produto derivadas da literatura

| ID | Tela | Decisão | Base | Força |
|---|---|---|---|---|
| D-UX-01 | Painel | O elemento principal **não** é o déficit do mês. É um indicador prospectivo e acionável — limite semanal restante e custo por dia — que continua útil com o mês no negativo. Sobra/falta e % comprometida ficam no segundo nível da mesma tela, visíveis sem toque: é ordem de leitura, não ocultação | Olafsson2025, Gladstone2021 | Análoga |
| D-UX-02 | Design system | **Vermelho reservado a erro de sistema e ação destrutiva.** Falta do mês, dívida e limite ultrapassado usam a cor de atenção não vermelha da marca ("barro"), sempre com sinal, rótulo e ícone. A versão em vermelho é montada ao lado na Fase 3 para a escolha final | Bazley2021, Gladstone2021, WCAG 1.4.1 | Análoga |
| D-UX-03 | Painel | Vale alimentação é moeda própria em todo o app: saldo de vale e saldo em dinheiro lado a lado, **nunca somados**. Alimentação consome o vale primeiro e marca o ponto de virada para dinheiro. Vale sobrando não compensa falta em dinheiro | Hastings2018, Thaler1999 | Análoga |
| D-UX-04 | Painel | Os três blocos são partições com limite e barra próprios, sem saldo único consolidado como número principal. Cobrir um bloco com outro é ação explícita, registrada no log | Soman2011, Thaler1999 | Análoga |
| D-UX-05 | Confirmação | Compra no cartão vira despesa no bloco **na data da compra** e abate o limite semanal na hora; pagar a fatura é liquidação, não despesa nova. A confirmação mostra o efeito imediato ("limite da semana: R$ A → R$ B") e pede um toque sobre o valor — o "ensaio" de Soman. Parcelado mostra o total comprometido, não só a parcela | Prelec1998, Soman2001 | Análoga |
| D-UX-06 | Confirmação | Três zonas de confiança. Alta: categoria preenchida em chip editável. Média: dois ou três candidatos, nenhum pré-selecionado. Baixa ou IA fora do ar: campo vazio com seletor. Limiares são parâmetro de configuração | Horvitz1999, Amershi2019 | Análoga |
| D-UX-07 | Confirmação | Erro visível em vez de erro silencioso: nunca lançar em "Outros" para evitar perguntar; nenhuma categoria inferida é gravada sem passar diante do usuário. Corrigir depois custa no máximo dois toques e gera evento de correção (o original não é reescrito) | Kocielnik2019, Horvitz1999 | Análoga |
| D-UX-08 | Confirmação | Cada correção cria uma regra local (estabelecimento → categoria) que roda **antes** da IA, com aviso e desfazer ("Vou lembrar: Padaria X é alimentação"). Regras listáveis e apagáveis. Uma correção não reclassifica o passado em massa | Amershi2019, GarciaMendez2020 | Projeto |
| D-UX-09 | Requisitos | A especificação **não presume acurácia**. O requisito é de processo: toda categorização passa pela confirmação e é reversível; o app conta sugestões aceitas × corrigidas por categoria e mostra a taxa real. Categoria com taxa baixa sobe sozinha para "perguntar" | GarciaMendez2020, Kocielnik2019 | Análoga |
| D-UX-10 | Onboarding | Primeiro compartilhamento mostra uma tela curta: o que é lido (OCR local, só texto sai do aparelho), um exemplo de acerto, um de erro, e que tudo é editável. Configurações oferece três posições: perguntar sempre · só na dúvida (padrão) · preencher e eu reviso | Kocielnik2019 | Análoga |
| D-UX-11 | Confirmação | Lançamento "fora do padrão" é atributo do evento, não categoria, e mostra o acumulado na hora: "4º gasto fora do padrão do ano; somam R$ X" | Sussman2012 | Direta |
| D-UX-12 | Fechamento | Linha "Fora do padrão no mês" e sugestão de levar a média dos últimos 12 meses como provisão no bloco de variáveis. Candidata a regra de negócio na Fase 2 | Sussman2012 | Projeto |
| D-UX-13 | Fechamento | Duas partes fixas: "Como foi o mês" e "Como fica adiante" (dívidas que terminam, compromissos, provisão). Começa pelo que foi cumprido antes de mostrar a falta; a falta aparece como valor a recompor, já refletido no novo limite semanal | Netemeyer2018, Gladstone2021 | Projeto |
| D-UX-14 | Dívidas | Nunca é tela de entrada e nunca abre com o total em destaque. Cada dívida é um item com o já pago ao lado do que falta, próxima parcela e data prevista; o total fica no rodapé. Quitar uma dívida é marco visível e sonoro | Olafsson2025, GalMcShane2012 | Análoga |
| D-UX-15 | Dívidas | Número primeiro ("faltam 3 parcelas, R$ 450"), barra de progresso como secundária, contada desde o início. A barra só ganha destaque no último quarto, sem quebrar em mini-metas | Cheema2011 | Análoga |
| D-UX-16 | Painel | Indicadores são **números grandes com uma frase**. Gráfico só onde há parte-todo: uma barra empilhada de fixos, variáveis e dívidas sobre a renda, e o vale em barra separada. Todo gráfico tem o número equivalente em texto | Ancker2006 | Análoga |
| D-UX-17 | Painel | Ritmo semanal para o gasto variável, mensal para o fechamento; "custo por dia" é média do período, sem destaque para hoje nem comparação dia a dia. O painel faz sentido para quem abre uma vez a cada uma a três semanas. **Periodicidade configurável** — não há evidência de que semanal seja melhor | Lurie2009, IrrationalLabs2020, Thaler1999 | Projeto |
| D-UX-18 | Painel | Limite semanal é um número só, sem orçamento por categoria na primeira versão, tratado como informação e não como promessa de mudança de comportamento | IrrationalLabs2020 | Análoga (indústria) |
| D-UX-19 | Notificações | Nenhuma notificação diária por padrão. No máximo resumo semanal, vencimentos e aviso de fechamento, em canal de baixa prioridade, sem som nem vibração. Chave independente por tipo; dia e horário escolhidos. O teto numérico é decisão de projeto | Pielot2014, Mehrotra2016 | Projeto |
| D-UX-20 | Notificações | **Todo lembrete de vencimento carrega contexto de caixa**: valor, data e "quanto sobra depois de pagar". Se pagar deixa o mês em falta, o texto diz isso e aponta para a tela de dívidas em vez de só mandar pagar. O saldo é estimado pelos lançamentos e o aviso se declara como estimativa | Medina2021, Karlan2016 | Direta |
| D-UX-21 | Notificações | Lembretes ancorados em momentos favoráveis (renda lançada, vale creditado, semana dentro do limite). Aviso de limite ultrapassado é um por evento, **sem valor negativo na tela bloqueada**. Nada recorrente enquanto o mês está no negativo | Olafsson2025 | Projeto |
| D-UX-22 | Voz | Regra dura no guia de voz, no prompt de sistema, no fallback por regras e no catálogo de erros: nenhuma mensagem atribui falha à pessoa. Falta é fato e distância a percorrer, seguida de ao menos uma opção concreta. A validação da saída da IA rejeita a lista de termos proibidos. Sem sequência punitiva | Gladstone2021, Golman2017 | Análoga |
| D-UX-23 | Chat | Toda resposta com número diz de onde ele veio (período, blocos e eventos), calculado pelo backend de forma determinística, não pela IA; linguagem de incerteza quando a base é estimativa | Amershi2019 | Análoga |

Estas decisões confirmam e detalham o guia de voz e a paleta já aprovados em `docs/brand/`. O que elas acrescentam de novo: D-UX-01 (o que é o herói do painel), D-UX-05 (data da compra: é o que a literatura sustenta para a pendência do parcelado, que continua sendo decidida na Fase 2), D-UX-20 (contexto de caixa no lembrete) e D-UX-09 (requisito de processo em vez de meta de acurácia).

## Referências

Todas com DOI conferido na Crossref, salvo a última.

1. **Amershi2019** — Amershi, S., Weld, D., Vorvoreanu, M., et al. (2019). Guidelines for Human-AI Interaction. *CHI '19*, 1–13. doi:10.1145/3290605.3300233
2. **Ancker2006** — Ancker, J. S., Senathirajah, Y., Kukafka, R., & Starren, J. B. (2006). Design Features of Graphs in Health Risk Communication: A Systematic Review. *JAMIA*, 13(6), 608–618. doi:10.1197/jamia.M2115
3. **Bazley2021** — Bazley, W. J., Cronqvist, H., & Mormann, M. (2021). Visual Finance: The Pervasive Effects of Red on Investor Behavior. *Management Science*, 67(9), 5616–5641. doi:10.1287/mnsc.2020.3747
4. **Cheema2011** — Cheema, A., & Bagchi, R. (2011). The Effect of Goal Visualization on Goal Pursuit. *Journal of Marketing*, 75(2), 109–123. doi:10.1509/jm.75.2.109
5. **GalMcShane2012** — Gal, D., & McShane, B. B. (2012). Can Small Victories Help Win the War? Evidence from Consumer Debt Management. *Journal of Marketing Research*, 49(4), 487–501. doi:10.1509/jmr.11.0272
6. **GarciaMendez2020** — García-Méndez, S., Fernández-Gavilanes, M., Juncal-Martínez, J., González-Castaño, F. J., & Barba Seara, Ó. (2020). Identifying Banking Transaction Descriptions via Support Vector Machine Short-Text Classification Based on a Specialized Labelled Corpus. *IEEE Access*, 8, 61642–61655. doi:10.1109/ACCESS.2020.2983584
7. **Gladstone2021** — Gladstone, J. J., Jachimowicz, J. M., Greenberg, A. E., & Galinsky, A. D. (2021). Financial shame spirals: How shame intensifies financial hardship. *OBHDP*, 167, 42–56. doi:10.1016/j.obhdp.2021.06.002
8. **Golman2017** — Golman, R., Hagmann, D., & Loewenstein, G. (2017). Information Avoidance. *Journal of Economic Literature*, 55(1), 96–135. doi:10.1257/jel.20151245
9. **Hastings2018** — Hastings, J., & Shapiro, J. M. (2018). How Are SNAP Benefits Spent? Evidence from a Retail Panel. *American Economic Review*, 108(12), 3493–3540. doi:10.1257/aer.20170866
10. **Horvitz1999** — Horvitz, E. (1999). Principles of mixed-initiative user interfaces. *CHI '99*, 159–166. doi:10.1145/302979.303030
11. **Karlan2016** — Karlan, D., McConnell, M., Mullainathan, S., & Zinman, J. (2016). Getting to the Top of Mind: How Reminders Increase Saving. *Management Science*, 62(12), 3393–3411. doi:10.1287/mnsc.2015.2296
12. **Karlsson2009** — Karlsson, N., Loewenstein, G., & Seppi, D. (2009). The ostrich effect: Selective attention to information. *Journal of Risk and Uncertainty*, 38(2), 95–115. doi:10.1007/s11166-009-9060-6
13. **Kocielnik2019** — Kocielnik, R., Amershi, S., & Bennett, P. N. (2019). Will You Accept an Imperfect AI? Exploring Designs for Adjusting End-user Expectations of AI Systems. *CHI '19*, 1–14. doi:10.1145/3290605.3300641
14. **Lurie2009** — Lurie, N. H., & Swaminathan, J. M. (2009). Is timely information always better? The effect of feedback frequency on decision making. *OBHDP*, 108(2), 315–329. doi:10.1016/j.obhdp.2008.05.005
15. **Medina2021** — Medina, P. C. (2021). Side Effects of Nudging: Evidence from a Randomized Intervention in the Credit Card Market. *Review of Financial Studies*, 34(5), 2580–2607. doi:10.1093/rfs/hhaa108
16. **Mehrotra2016** — Mehrotra, A., Pejovic, V., Vermeulen, J., Hendley, R., & Musolesi, M. (2016). My Phone and Me: Understanding People's Receptivity to Mobile Notifications. *CHI '16*, 1021–1032. doi:10.1145/2858036.2858566
17. **Netemeyer2018** — Netemeyer, R. G., Warmath, D., Fernandes, D., & Lynch, J. G., Jr. (2018). How Am I Doing? Perceived Financial Well-Being, Its Potential Antecedents, and Its Relation to Overall Well-Being. *Journal of Consumer Research*, 45(1), 68–89. doi:10.1093/jcr/ucx109
18. **Olafsson2025** — Olafsson, A., & Pagel, M. (2025). The Ostrich in Us: Selective Attention to Personal Finances. *Review of Economics and Statistics*, publicação online antecipada. doi:10.1162/rest_a_01566 (versão anterior: NBER Working Paper 23945, doi:10.3386/w23945)
19. **Pielot2014** — Pielot, M., Church, K., & de Oliveira, R. (2014). An in-situ study of mobile phone notifications. *MobileHCI '14*, 233–242. doi:10.1145/2628363.2628364
20. **Prelec1998** — Prelec, D., & Loewenstein, G. (1998). The Red and the Black: Mental Accounting of Savings and Debt. *Marketing Science*, 17(1), 4–28. doi:10.1287/mksc.17.1.4
21. **Sicherman2016** — Sicherman, N., Loewenstein, G., Seppi, D. J., & Utkus, S. P. (2016). Financial Attention. *Review of Financial Studies*, 29(4), 863–897. doi:10.1093/rfs/hhv073
22. **Soman2001** — Soman, D. (2001). Effects of Payment Mechanism on Spending Behavior: The Role of Rehearsal and Immediacy of Payments. *Journal of Consumer Research*, 27(4), 460–474. doi:10.1086/319621
23. **Soman2011** — Soman, D., & Cheema, A. (2011). Earmarking and Partitioning: Increasing Saving by Low-Income Households. *Journal of Marketing Research*, 48(SPL), S14–S22. doi:10.1509/jmkr.48.SPL.S14
24. **Sussman2012** — Sussman, A. B., & Alter, A. L. (2012). The Exception Is the Rule: Underestimating and Overspending on Exceptional Expenses. *Journal of Consumer Research*, 39(4), 800–814. doi:10.1086/665833
25. **Thaler1999** — Thaler, R. H. (1999). Mental accounting matters. *Journal of Behavioral Decision Making*, 12(3), 183–206. doi:10.1002/(SICI)1099-0771(199909)12:3<183::AID-BDM318>3.0.CO;2-F
26. **IrrationalLabs2020** — Irrational Labs e Common Cents Lab, Duke University (2020). *Budgeting: What Our Research Uncovered.* Estudo de caso, **não revisado por pares**. https://irrationallabs.com/case-studies/budgeting/

## Limites desta revisão

- Os achados vêm dos resumos e, quando disponível, do texto dos artigos; tamanhos de efeito só foram citados quando constam na fonte lida.
- Quase nada foi medido no Brasil: só [Medina2021]. Renda, crédito parcelado e vale alimentação têm particularidades locais que a literatura encontrada não cobre.
- Nenhum estudo avalia um app de usuário único construído por quem o usa. As decisões acima são hipóteses bem fundamentadas, e o contador de uso do próprio app (D-UX-09) é a forma de testá-las.
