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
   - valor: o rótulo das regras manda; se a IA diverge, a tela mostra os dois, o da regra primeiro. A IA desempata quando as regras ficaram entre vários números, e lê sozinha quando o texto não trouxe nenhum;
   - data e forma de pagamento: as do texto, quando as regras acharam; as da IA, quando não;
   - categoria: o que a pessoa ensinou manda (RN-765); depois o palpite da IA, com o ramo do lugar lido no celular ao lado;
   - tipo do documento: "compra" é o que as regras dizem quando nenhuma palavra apareceu, e aí vale a IA (é o que reconhece um Pix recebido); quando as regras acharam "pagamento de fatura", divergir vira pergunta (RN-757);
   - descrição: a da IA, que lê o nome do lugar como gente.
6. **Sem foto, nada muda**: valor e data da IA continuam valendo só se estão no texto (RN-774). Com foto, valem se não estiverem no futuro, não forem velhos demais e couberem em R$ 1 milhão.
7. A conferência continua: a pessoa bate o olho e confirma com um toque.

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
- **Custo:** a leitura com foto espera a IA, até 15 segundos; o cupom de mercado continua instantâneo.
- **Custo:** a rota de classificação aceita até 12 MB por pedido — três imagens de até 4 MB, conferidas pelos primeiros bytes.

## Como se confere

- Testes do servidor: a foto vai na mesma mensagem que o texto, e a resposta é pedida em JSON; o valor que o celular não leu vem da IA; a IA desempata entre os números lidos; o rótulo TOTAL manda e a divergência mostra os dois; sem foto, valor fora do texto é descartado; só a imagem basta para a IA ler tudo; Pix recebido vira entrada; data futura ou velha não vale; a mesma foto não paga duas vezes; a rota aceita foto acima de 64 KB e recusa o que não é imagem.
- Testes do app: cupom de mercado lido inteiro não sai do celular; Pix para uma pessoa leva a foto em base64; foto não lida vai sozinha; a IA leu o valor e a conferência abre; ninguém leu e a saída é a de sempre.
- Em produção: depende do servidor novo na VM, que a rede da faculdade não deixa subir (porta 22).
