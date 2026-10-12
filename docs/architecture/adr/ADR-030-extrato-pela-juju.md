# ADR-030 — Extrato pela Juju: a IA lê por página, o app conversa

**Estado:** aceita · 11/10/2026.

O dono pediu para mandar os extratos mensais dos bancos para a Juju e conferir com ela antes de gravar: "ela deve deduzir e ser inteligente em saber o que é mercado, pix, cartão de crédito, padaria, ifood… o que fica na dúvida ela me pergunte". Aprovou a proposta de resumo, blocos de categoria, dúvidas uma a uma, memória das respostas e gravação em lote com desfazer (RN-1100 a RN-1120).

**Relacionadas:**
- [ADR-021](ADR-021-assistente-que-age.md): a Juju que age pelo servidor. Esta ADR **não** passa o extrato por ali.
- [ADR-022](ADR-022-a-ia-le-a-foto.md): a imagem pode ir à IA.
- [ADR-020](ADR-020-chave-da-casa.md): os fatos do aparelho e o servidor que os guarda.

## Contexto

A leitura de extrato que existia (RN-707) não comporta um mês inteiro, e corta em silêncio:
- 8.000 caracteres de texto, 30 linhas, 10 páginas e 3 imagens;
- uma resposta da IA cortada no meio derruba o extrato todo (BL-078).

Além disso:
- **O id da linha vinha da posição.** Ler de novo, ou noutra ordem, lançava em dobro.
- **Lançar de novo depois de desfazer era ignorado em silêncio**, porque o id era o mesmo.
- **A memória de classificação** guardava só "estabelecimento → categoria", não sincronizava entre celulares e não aprendia com o extrato.
- **Uma entrada de dinheiro não tinha como ser desfeita.**

## Decisão

1. **A IA só lê, uma página por pedido.** Rota nova, `POST /v1/statements/read-part`:
   - **Pedido:** o texto de uma página, já mascarado e com as linhas numeradas; a imagem da página só quando o OCR dela vier fraco; o mês do extrato; o número da página e o total; e os exemplos de memória que não falam de pessoa (RN-1107).
   - **Resposta:** as movimentações, cada uma com o número da linha de onde saiu, dia e mês, descrição, valor, tipo, categoria e confiança.
   - **Teto:** o servidor lê `finish_reason`. Se a resposta foi cortada, divide a página em duas metades e tenta uma vez; se cortar de novo, aproveita as linhas completas (RN-1103).
   - **Quem faz o laço é o celular,** página a página, com "Lendo a página 3 de 7". Várias chamadas de 35 s numa requisição só estourariam o prazo do celular.
2. **O celular resolve cada linha** (`StatementLineResolver`, domínio). O número da linha leva de volta ao texto original, sem máscara, que nunca saiu do celular. Sobre esse texto se aplicam:
   - a marca conhecida (`MerchantBrand`, RN-1108);
   - a resposta lembrada (RN-1109, RN-1116);
   - a data com o ano do período (`StatementDates`, RN-1105);
   - a chave pelo conteúdo (`StatementLineKey`, RN-1117).
   O resultado diz se a linha está certa ou por que é dúvida.
3. **A conversa é do app, determinística.**
   - O domínio monta o resumo, os blocos e as perguntas, com totais por moeda (RN-111), e as frases com o guia de voz.
   - O app tem um `Notifier` com estado selado na feature da Juju.
   - O design system ganha a bolha com ações (`CajuiChatPrompt`). A bolha de texto esconde do leitor de tela o que estiver dentro dela, então não serve para botões.
   - Nenhuma frase do extrato passa pelo modelo da conversa.
4. **Memória como fato sincronizado:** `merchant.learned`, com a chave do estabelecimento, a categoria e/ou o tratamento (gasto, alguém da casa, conta minha, não lançar), se fala de pessoa, e quando foi definida.
   - A mais nova vence, como nos nomes da casa.
   - Os eventos antigos `capture.rule-learned` migram para ele.
5. **Entrada desfeita** é um fato novo, `income.cancelled`, de ponta a ponta: o livro do celular, o contrato e o servidor, que o desconta nos números da Juju (RN-1120).
6. **O id da linha gravada** é a chave pelo conteúdo mais o carimbo daquele lançamento (`chave~carimbo`):
   - se algum id ativo no livro começa pela chave, a linha "já estava" e não entra de novo;
   - a desfeita sai do livro, e o próximo lançamento a grava com outro carimbo — um id que nunca foi desfeito em lugar nenhum.
   Ler de novo é idempotente, e lançar de novo depois de desfazer funciona (RN-1119). A chave sai do texto que o banco escreveu, e não da descrição da IA, que muda entre leituras.
7. **O extrato se reconhece no celular** (`StatementShape`, domínio), pelo texto lido: várias linhas que começam com a data e trazem valor. Ele vai direto para a conversa, sem passar pela leitura de comprovante, que o cortava em 8.000 caracteres e o mandava à IA sem a máscara. A tela de lista da RN-707 saiu: nenhum caminho chegava mais a ela.
8. **"Já está no Cajui" é casamento um a um** (`StatementMatches`, app): valor igual, até dois dias de diferença e uma palavra do lugar em comum quando os dois lados têm nome. A parcela de uma compra parcelada já lançada casa pelo plano do cartão (mesmo número de vezes, parcela do mesmo valor). Fica no app porque precisa do livro; a conta de cada linha continua no domínio.

## Alternativas descartadas

- **Passar o extrato pelo assistente do servidor (`/assistant/ask`):** a resposta tem teto de 600 tokens, e frases livres da IA dariam números que podem não bater com a tela. A conversa guiada diz exatamente o que o domínio contou.
- **Um pedido só com o extrato inteiro:** estoura o tempo e o teto de resposta, e uma falha perde tudo. Por página, uma falha perde uma página.
- **Extrair a camada de texto do PDF:** daria números exatos e menos tokens, mas o `PdfRenderer` só tem essa API no Android 15, e uma biblioteca de PDF pesaria no APK. O OCR das páginas renderizadas lê bem o PDF dos bancos, que é texto nítido. Fica no backlog.
- **Deixar a memória só no celular:** reinstalar perderia tudo, e o outro celular perguntaria de novo.
