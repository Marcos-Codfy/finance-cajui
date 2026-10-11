# ADR-022 — A IA lê a foto do comprovante, junto do texto do celular

**Estado:** aceita · 07/10/2026 — por pedido do dono ("eu quero com foto"; "use a melhor estratégia, o mais assertivo possível"; "se for cupom de mercado usa o regex, se não usa a IA, usa os dois")
**Substitui em parte:** [ADR-007](ADR-007-ocr-e-pdf.md) no que diz que nenhuma imagem sai do aparelho; RN-772, RN-774 e RN-780 de [capture-and-classification.md](../../spec/rules/capture-and-classification.md), como anotado lá
**Relacionada:** [ADR-010](ADR-010-integracao-com-a-deepseek.md) (a IA por cima das regras) · [ADR-020](ADR-020-chave-da-casa.md) (a chave com que o celular fala com o servidor)

## Contexto

Até aqui o celular lia o comprovante com o ML Kit e mandava à IA **só o texto**, mascarado. Era a regra do dono em setembro. Em 07/10 ele mudou de ideia, com todas as letras: quer a foto lida pela IA, quer o resultado mais certeiro possível, e não vê problema em a imagem sair do aparelho.

O texto do ML Kit erra justamente onde mais importa: cupom amassado, foto escura, print de banco com o valor em fonte grande e o resto miúdo. E as regras sobre esse texto acertam com exatidão onde o documento é padronizado: o valor ao lado de "TOTAL" ou "VALOR A PAGAR" num cupom fiscal.

O preço foi conferido na fonte: a DeepSeek conta até 1.024 tokens por imagem, no preço normal de entrada do `deepseek-flash`. Uma foto custa uns US$ 0,0007 no pico.

## Decisão

1. **O celular lê primeiro, sempre.** ML Kit na foto (ou nas páginas do PDF) e as regras sobre o texto, sem rede.
2. **Quando as regras bastam, nada sai do celular** (`ReadingStrategy.rulesSuffice`): valor rotulado, data, documento de compra e o nome do lugar dizendo o ramo — o cupom de mercado, de farmácia, de posto. Abre na hora e não custa nada.
3. **Quando não bastam, a foto vai junto do texto.** O celular reduz a imagem a 2.000 px no lado maior, em JPEG, de pé pela marcação EXIF (`AiImage`); de um PDF vão as três primeiras páginas. O servidor manda ao `deepseek-flash` uma mensagem com o texto lido e as imagens, e pede JSON.
4. **Foto que o celular não leu também vai.** Antes ela parava em "não deu para ler"; agora a IA tenta, e só se ela também não achar valor a pessoa vê a saída de sempre (outra foto, ou digitar).
5. **A junção é campo a campo** (`ProposalMerge`):
   - valor: o rótulo das regras manda. Se a IA aponta **outro número do texto**, a tela mostra os dois, o da regra primeiro; número que ela leu só da imagem não tira o rótulo do lugar — pode ser a foto lida torta. A IA desempata quando as regras ficaram entre vários números, e lê sozinha quando o texto não trouxe nenhum. Valor quebrado (23.9) é a IA respondendo em reais, e não vale;
   - data e forma de pagamento: as do texto, quando as regras acharam; as da IA, quando não;
   - categoria: o que a pessoa ensinou manda (RN-765); depois o palpite da IA, com o ramo do lugar lido no celular ao lado;
   - tipo do documento: "compra" é o que as regras dizem quando nenhuma palavra apareceu, e aí vale a IA (é o que reconhece um Pix recebido) — **menos pagamento de fatura**, que só pela IA vira pergunta (RN-757): dar como certo faria uma despesa sumir, e a foto pode trazer o texto de quem quer isso (INJ-07); quando as regras acharam um tipo, divergir também vira pergunta;
   - descrição: a da IA, que lê o nome do lugar como gente.
6. **Sem foto, nada muda**: valor e data da IA continuam valendo só se estão no texto (RN-774). Com foto, valem se não estiverem no futuro, não forem velhos demais e couberem em R$ 1 milhão.
7. A conferência continua: a pessoa bate o olho e confirma com um toque.
8. **A regra só basta sabendo a forma de pagamento.** Cupom de mercado pago no vale, lido como débito, somaria duas moedas que nunca se somam (RN-111). O leitor passou a reconhecer as palavras do vale (vale alimentação/refeição, Alelo, Pluxee/Sodexo, Ticket, VR) antes de "crédito" e "débito"; sem forma nenhuma, a foto vai para a IA.
9. **Falha não é queda.** O servidor que ainda não conhece foto recusa o pedido; o app tenta de novo só com o texto, e a IA continua ajudando. Do lado do servidor, a IA que **recusa** a imagem (4xx) não conta para o disjuntor — o mesmo do assistente — e o pedido segue só com o texto; prazo vencido lendo foto também não conta. O registro do serviço diz o código HTTP do provedor, e só ele.
10. **Reabrir lê o arquivo de novo.** O arquivo fica no aparelho até ser descartado; a captura adiada guarda se é PDF, e ao reabrir a foto volta para a IA — o servidor responde do cache, sem pagar de novo.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Só a IA, sem o texto do celular | Perde a exatidão do rótulo "TOTAL" e o funcionamento sem rede; e a imagem reduzida do provedor deixa letra miúda de cupom comprido ilegível |
| Só a foto quando o celular não leu | Deixaria de fora o Pix e o print de banco, onde o texto é bom e quem erra é a regra da categoria |
| Mandar a foto sempre, até no cupom de mercado | Espera de segundos e custo onde as regras já acertam |
| Mascarar a imagem antes de mandar | Exigiria desenhar tarja sobre CPF e chave Pix na foto; o dono dispensou |

## Consequências

- **Bom:** o comprovante que antes vinha com campo em branco vem preenchido; a foto escura deixa de ser beco sem saída.
- **Custo:** a imagem sai do aparelho como está, com CPF, nome e chave Pix, para a DeepSeek. Risco aceito pelo dono.
- **Custo:** a leitura com foto espera a IA, até 15 segundos no servidor; o app espera até 50 para cobrir o envio pela rede do celular. O cupom de mercado continua instantâneo.
- **Custo:** a rota de classificação aceita até 9 MB por pedido — três imagens de até 2 MB, conferidas pelo tamanho antes de decodificar e pelos primeiros bytes depois. O corpo é lido em bloco de bytes, e não em lista de inteiros, que ocupava oito vezes mais e levava três pedidos ao teto de memória do serviço.

## Como se confere

- Testes do servidor: a foto vai na mesma mensagem que o texto, e a resposta é pedida em JSON; o valor que o celular não leu vem da IA; a IA desempata entre os números lidos; o rótulo TOTAL manda contra número lido só da imagem, e divide o lugar com outro número do texto; valor quebrado não vale; fatura só pela IA vira pergunta; sem foto, valor fora do texto é descartado; só a imagem basta para a IA ler tudo; Pix recebido vira entrada; data futura ou velha não vale; a mesma foto não paga duas vezes; a rota aceita foto acima de 64 KB, recusa o que não é imagem, aceita mais de 20 exemplos e recusa corpo e imagem acima do teto; a IA que recusa a imagem leva o pedido de volta só com texto, sem abrir o disjuntor; prazo vencido lendo foto também não abre.
- Testes do app: cupom de mercado lido inteiro não sai do celular; sem forma de pagamento, sai; o vale é lido como vale; Pix para uma pessoa leva a foto em base64; foto não lida vai sozinha; sem texto e sem foto nada sai; o servidor antigo recusa e o texto vai de novo; vão os 20 exemplos mais recentes; a IA leu o valor e a conferência abre; adiar e reabrir devolve a foto à IA; texto curto compartilhado abre a conferência; ninguém leu e a saída é a de sempre.
- Revisão adversarial com três revisores independentes (junção, servidor, Android): os achados confirmados entraram aqui; o que ficou está no `BACKLOG.md` (BL-073 a BL-075). O tipo do documento ainda não muda a tela — Pix recebido abre a conferência de despesa —; isso entra no passo seguinte, o dos extratos e das entradas.
- Em produção: depende do servidor novo na VM, que a rede da faculdade não deixa subir (porta 22).

## Adendo — extratos (07/10/2026)

O prompt passou à versão 4: além do comprovante único, a IA reconhece o **extrato** e devolve as movimentações em `lines`, cada uma com data, descrição, valor e tipo (despesa, entrada, pagamento de fatura, transferência entre contas próprias). Cada linha passa pelas mesmas conferências de um comprovante — valor inteiro e positivo dentro do teto, data plausível, categoria da lista fechada, descrição pelo filtro da RN-775 — e a que não passa cai sozinha; sem a foto, valor fora do texto continua inventado (RN-774). Extrato com menos de duas linhas aproveitáveis segue como comprovante comum: uma linha só é comprovante lido torto, ou foto querendo esconder uma compra numa lista (INJ-07). A palavra escrita na linha manda no tipo; fatura e transferência que só a IA viu, e linha sem tipo, ficam **em dúvida** (`doubtful`): aparecem, dá para marcar, nunca vêm marcadas. No extrato do vale, toda linha vira vale. O teto da resposta é 2.000 tokens só com texto e 4.000 com foto — paga-se o que a IA escreve, e resposta cortada não se lê —; o servidor espera até 35 segundos com foto, e o app, até 50. Prompt v5.
