# Extrato pela Juju (RN-1100 a RN-1199)

Formato e convenções em [README.md](README.md). A decisão de onde cada parte mora está na [ADR-030](../../architecture/adr/ADR-030-extrato-pela-juju.md).

> **O pedido (11/10/2026).** O dono quer mandar os extratos mensais dos apps dos bancos — compartilhando direto do banco ou anexando na conversa — e conferir com a Juju o que foi lido antes de gravar: "ela deve deduzir e ser inteligente em saber o que é mercado, pix, cartão de crédito, padaria, ifood… o que fica na dúvida ela me pergunte". A proposta aprovada: resumo primeiro, conferência por blocos de categoria, dúvidas uma a uma, a Juju lembra as respostas, e nada é gravado antes de "Pode lançar", com "Desfazer" do lote inteiro.
>
> Estas regras substituem, para o extrato, o teto de 30 linhas e a tela de lista da RN-707. **A tela de lista saiu em 12/10/2026**: com o extrato reconhecido no celular, nenhum caminho chegava mais a ela, e a web, que é só consulta, não recebe arquivo.

Três princípios:

1. **A IA só lê; quem conversa é o app.** As frases da Juju durante o extrato são montadas pelo app a partir do domínio, com o guia de voz. Assim cada número dito é o mesmo que a tela mostra, e a conversa funciona igual em todo extrato.
2. **Nada entra sem passar diante da pessoa**, como na captura (RN-7xx): o que a leitura entendeu com certeza vem agrupado; o que não entendeu vira pergunta.
3. **Ler de novo nunca lança em dobro.** A chave de cada linha vem do conteúdo, e não da ordem em que a IA a devolveu.

## Entrada

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-1100 | Um extrato compartilhado do app do banco, ou anexado pelo clipe da conversa, abre na conversa da Juju. O celular o reconhece pelo texto lido, antes de qualquer IA: cinco ou mais linhas que começam com a data e trazem um valor — três, se o texto diz "extrato" ou "fatura". Assim o extrato nunca passa pela leitura de comprovante, que o mandaria à IA sem a máscara da RN-1106. Documento que não é extrato segue para a conferência de sempre (RN-7xx). A web, que é só consulta, não recebe arquivo | Compartilhar o PDF do extrato no app do banco: o Cajui abre na aba Conversar, com "Lendo o extrato…"; compartilhar um cupom de mercado abre a conferência | dono, 11/10 |
| RN-1101 | Vários arquivos do mesmo compartilhamento (prints de um extrato) são uma leitura só, na ordem recebida. Valem os limites da RN-704 (até 10 arquivos), com até 20 páginas por PDF; o que ficou de fora é dito: "Li as páginas 1 a 20 de 24" | Três prints do extrato: um resumo só, com as movimentações dos três | dono, 11/10 |
| RN-1102 | A leitura é feita uma página por vez, e a Juju diz em que página está: "Lendo a página 3 de 7". Página que falha é tentada mais uma vez; se falhar de novo, as outras seguem e o resumo diz qual ficou de fora | A página 4 falha duas vezes: o resumo traz as outras seis e "A página 4 não deu para ler" | BL-078 |
| RN-1103 | Resposta da IA cortada pelo teto de tamanho é dividida em duas metades e lida de novo, uma vez. Se cortar de novo, valem as movimentações completas, e o resumo avisa que aquela página foi lida em parte (E-AI-05) | Página com 90 movimentações: lida em duas metades, sem perder nenhuma | BL-078 |
| RN-1104 | Sem teto de 30: até 60 movimentações por página e 400 por extrato. O que passar disso é dito, nunca cortado em silêncio. O celular confere a resposta de cada página: linha que começa com data e traz valor (fora saldo, total e limite) e que a IA não citou é pedida de novo, só ela, uma vez; o que ainda faltar é dito no resumo — "2 linhas com data e valor não vieram na leitura: dá para conferir no extrato e lançar à mão" | Extrato de 7 páginas com 140 movimentações: as 140 entram no resumo | dono, 11/10 |
| RN-1105 | Data sem ano ("05/10", "05 OUT") ganha o ano do mês do extrato; na virada, um extrato de janeiro com linha de dezembro ganha o ano anterior. Data depois de hoje faz a linha cair, com aviso | Extrato de outubro/2026, "05/10" → 05/10/2026. Extrato de janeiro/2027, "28/12" → 28/12/2026 | domínio |

## Privacidade

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-1106 | Além da RN-732, o nome de pessoa que vem depois de "PIX ENVIADO", "PIX RECEBIDO", "TRANSF", "TED" ou "DOC" vira `[NOME]` antes de ir para a IA, uma linha de cada vez, sem juntar linhas. O nome de verdade fica no celular, e só ali aparece nas perguntas | "PIX ENVIADO JOAO P SILVA 150,00" vai como "PIX ENVIADO [NOME] 150,00"; a pergunta no celular mostra "Pix para João P Silva" | RN-732 |
| RN-1107 | Resposta lembrada que fala de pessoa (Pix para alguém) nunca vira exemplo para a IA, nem no servidor nem no app | Lembrar "João P Silva é alguém da casa": a regra existe no celular e não aparece nos exemplos enviados | RN-768 |

## O que cada linha é

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-1108 | Marca conhecida pelo jeito como o extrato escreve: "IFD*" e "IFOOD" são **iFood** (Restaurante e lanche); "UBER *TRIP" e "UBER" são **Uber**, "99APP" e "99 TECNOLOGIA" são **99** (Transporte); "NETFLIX.COM" é **Netflix**, "SPOTIFY" é **Spotify**, "APPLE.COM/BILL" é **Apple**, "GOOGLE *YOUTUBE" é **YouTube** (Assinaturas). Prefixo de maquininha ("MP*", "PAG*", "SUMUP*", "EC *", "PICPAY*") sai e deixa o nome da loja. O nome que aparece é sempre o da tabela, e a tabela é literal (RN-733) | "IFD*RESTAURANTE SABOR" → iFood, Restaurante e lanche. "MP*PADARIA BOA VISTA" → Padaria Boa Vista | dono, 11/10 |
| RN-1109 | A categoria de cada linha segue a precedência: resposta lembrada (RN-1116), marca conhecida (RN-1108), IA. A IA só decide sozinha com confiança alta; senão, a linha vira dúvida | "PADARIA BOA VISTA", lembrada como Padaria: entra no bloco Padaria sem perguntar, mesmo que a IA diga Mercado | dono, 11/10 |
| RN-1110 | O tipo de cada linha é despesa, entrada, pagamento de fatura (nunca gasto, RN-756), transferência entre contas suas (nunca gasto, RN-759) ou dinheiro para alguém da casa (nunca gasto, RN-1070). A palavra escrita na linha manda; o que só a IA disse fica em dúvida | "PAGAMENTO DE FATURA" sem dúvida; "PIX ENVIADO [NOME]" sem nome da casa: dúvida | RN-756, RN-759 |
| RN-1111 | Compra parcelada vinda de antes ("LOJA X 02/10" numa fatura) pergunta uma vez, para todas: "8 parcelas de compras de outros meses, R$ 640,00 — lanço como gasto deste mês?". A parcela de uma compra que já está no Cajui não entra de novo | Fatura com "SOFA 03/10 R$ 300,00" e o sofá lançado em 10×: a parcela fica de fora, como "já está no Cajui" | BL-077 |

## A conversa

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-1112 | O resumo vem primeiro: o período, quantas movimentações, e quantos gastos com o total, quantas entradas com o total, e quantos pagamentos de fatura e transferências não contam. Dinheiro e vale nunca se somam (RN-111). As que já estão no Cajui são ditas e ficam fora do lote. "Já está" é casamento um a um: mesmo valor, até dois dias de diferença (o débito cai depois da compra) e uma palavra do lugar em comum quando os dois lados têm nome; cada lançamento serve a uma linha só | "Li 87 movimentações de 1 a 31 de outubro: 62 gastos, R$ 2.371,90; 2 entradas, R$ 3.120,00. 4 pagamentos de fatura e 9 transferências entre suas contas não contam. 10 já estavam no Cajui." | dono, 11/10 |
| RN-1113 | A conferência é por blocos de categoria, do maior total para o menor. Cada bloco diz a categoria, quantas compras, o total e até três nomes, com "e mais N", e oferece **Confere**, **Ver as linhas** e **Corrigir**. Corrigir abre as linhas do bloco, cada uma com a troca de categoria e "Não lançar" | "Mercado — 12 compras, R$ 1.240,00: Assaí, Atacadão, Pão de Açúcar e mais 9. Confere?" | dono, 11/10 |
| RN-1114 | As dúvidas vêm depois dos blocos, uma de cada vez, com as opções em botões: de categoria, as quatro mais prováveis e "Outra"; de tipo, "É um gasto", "Alguém da casa", "Conta minha" e "Não lançar"; de cartão, os cartões cadastrados. Responder passa para a próxima | "Pix para João P Silva, R$ 150,00, em 12/10. O que foi?" [É um gasto] [Alguém da casa] [Conta minha] [Não lançar] | dono, 11/10 |
| RN-1115 | Nada é gravado antes de **Pode lançar**, que diz quantos entram: "Pode lançar (58)". **Conferir depois** guarda a leitura em "Para conferir", sem gravar nada | Fechar o app no meio: a leitura volta em "Para conferir", e as respostas já dadas continuam valendo, porque cada uma é lembrada na hora (RN-1116) | dono, 11/10 |
| RN-1116 | Cada resposta — categoria, "alguém da casa", "conta minha", "não lançar" — é lembrada na hora, pela chave do estabelecimento (a marca, ou o nome normalizado da RN-727) e vale nos próximos extratos e comprovantes, nos dois celulares. Responder de novo troca a anterior: a mais nova vence | Responder "Padaria" para "PADARIA BOA VISTA" em outubro: em novembro, no outro celular, ela já entra no bloco Padaria | dono, 11/10 |

## Gravar e desfazer

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-1117 | Cada linha gravada leva uma chave feita do conteúdo — data, valor, chave do estabelecimento e o número de ordem entre linhas iguais —, e nunca da posição. A chave vem do texto que o banco escreveu, e não da descrição da IA, que muda de uma leitura para outra. Ler o mesmo extrato de novo, compartilhá-lo de novo ou recebê-lo noutra ordem não lança em dobro. O id gravado é a chave mais o carimbo daquele lançamento: a linha cuja chave já está ativa no livro é "já estava"; a desfeita (RN-1119) volta com outro carimbo | Duas compras iguais de R$ 8,00 na mesma padaria no mesmo dia: duas chaves (ordem 1 e 2); ler de novo: nenhuma entra outra vez | revisão de 11/10 |
| RN-1118 | O lote grava linha a linha; a linha que o domínio recusa não derruba as outras, e a Juju diz quais ficaram de fora e por quê, com o texto do catálogo | "Lancei 57. 'Farmácia Central' não entrou: …" | RN-707 |
| RN-1119 | **Desfazer** desfaz tudo o que aquela leitura gravou — gastos e entradas — num toque, e a Juju diz quantos: "Desfiz os 58 lançamentos". Lançar de novo depois de desfazer grava com chaves novas, e nunca é ignorado em silêncio | Desfazer e tocar "Pode lançar" outra vez: os 58 voltam | revisão de 11/10 |
| RN-1120 | Uma entrada de dinheiro gravada pode ser desfeita, como um gasto. Desfeita, ela sai do mês, da renda e da planilha, nos dois celulares e no servidor | Desfazer o salário lido no extrato: a renda do mês volta a ser a esperada | revisão de 11/10 |
