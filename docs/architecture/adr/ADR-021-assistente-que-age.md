# ADR-021 — O assistente que age: ferramentas no lugar do roteiro

**Estado:** aceita · 07/10/2026 — por pedido do dono ("deixe a IA com mais capacidade de pensar por si, tá muito restrita")
**Substitui em parte:** [ADR-010](ADR-010-ia-por-cima-das-regras.md), no que diz sobre o assistente só redigir; e as regras RN-903, RN-904, RN-920 a RN-925, RN-942 a RN-947 e RN-960 de [assistant-and-privacy.md](../../spec/rules/assistant-and-privacy.md), como anotado lá
**Relacionada:** [ADR-020](ADR-020-chave-da-casa.md) (a chave com que o app fala com ele) · [ADR-019](ADR-019-dois-aparelhos-um-livro.md) (o que ele grava desce aos celulares)

## Contexto

O assistente da Fase 6 era um redator preso: só via agregados, só respondia em JSON fechado, cada número do texto tinha de existir no contexto, cada palavra passava por uma lista proibida, duas reprovações viravam uma frase de formato fixo, e ele **não fazia nada** — no máximo sugeria um botão. Antes dele, um roteador local respondia perguntas comuns com frases prontas. O dono pediu uma IA que pensa por si e resolve.

Com a chave da casa (ADR-020) o que fala com o servidor é sempre o dono. O pior que uma resposta ruim faz é um lançamento errado — que se desfaz em um toque.

## Decisão

1. **Ferramentas, com a lista fechada no servidor**: `lancar_despesa`, `cancelar_lancamento`, `listar_lancamentos`, `registrar_renda`. O modelo pede pelo nome, com argumentos em JSON; quem executa confere cada argumento de novo e recusa com motivo em texto, que volta ao modelo. O que ele grava passa pelo **mesmo caminho das rotas**: regras do domínio, evento no registro, projeção — e desce aos celulares como qualquer fato.
2. **O laço**: até quatro rodadas de ferramenta por pergunta; na última o modelo não recebe ferramentas e responde com o que tem. O que ele fez no caminho vai junto com a resposta (`actions`), e o app mostra **Desfazer** ao lado de cada lançamento.
3. **Texto livre**: a resposta é texto puro, sem esquema, sem conferência de número e sem lista proibida. Vazia vira a frase de formato fixo; longa demais é cortada. O tom continua nas instruções, não no validador.
4. **O modelo vê o mês**: o resumo por categoria e moeda vai nas instruções, como antes; os lançamentos com nome, data e forma vão por `listar_lancamentos`, quando ele pede. A pergunta continua mascarada (CPF, telefone, chave Pix) antes de sair.
5. **Cada aparelho tem a sua conversa**: a janela é por `X-Cajui-Device`.
6. **O app não responde mais nada sozinho**: toda pergunta vai ao servidor. Antes de perguntar, o livro sobe; depois de uma resposta em que o assistente lançou ou cancelou, o livro desce.
7. O que fica da Fase 6: a chave da DeepSeek só no servidor, o orçamento de tokens, o disjuntor, a mascaração, o teto da pergunta, o resumo sem total que some moedas (RN-111).

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Manter o validador de números e só adicionar ferramentas | O validador reprovava toda conta feita pelo modelo — e fazer conta simples é parte de "pensar por si" |
| O app executar as ações sugeridas, com confirmação | É a cerimônia que o dono pediu para tirar; e o servidor é quem tem o livro inteiro e os dois celulares |
| Confirmar cada lançamento antes de gravar | "Lancei R$ 50 em Padaria — Desfazer" custa o mesmo toque que "Confirmar?", e só quando errou |

## Consequências

- **Bom:** "gastei 35 no mercado" vira um lançamento; "desfaz" o cancela; "o que gastei em farmácia" tem resposta com nomes.
- **Custo:** o modelo pode errar categoria ou valor; a resposta diz o que fez, e Desfazer está ao lado. Lançamento do assistente leva origem `manual`, como o do dono.
- **Custo:** cada pergunta pode gastar até cinco chamadas; o orçamento mensal de tokens continua o freio.
- **Risco aceito:** uma descrição de comprovante maliciosa chega ao modelo pela listagem; o pior resultado é um lançamento errado, desfeito em um toque.
- `local_answer.dart` e o roteador de perguntas no app deixaram de existir; `QuestionRouter` fica no domínio sem uso (BL-071).

## Como se confere

- Testes do servidor: "gastei 50 na padaria" vira lançamento real com a ação dita ao app; categoria desconhecida volta como motivo e nada é gravado; "desfaz" cancela; a listagem traz nome, forma e totais por moeda nunca somados; "caiu o salário" registra a renda do mês; modelo que só pede ferramenta perde as ferramentas na última rodada; conversas separadas por aparelho.
- Testes do app: toda pergunta vai ao servidor; a resposta aparece inteira; o que o assistente lançou vem com Desfazer, e desfazer cancela aqui.
