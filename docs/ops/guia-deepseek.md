# Guia — DeepSeek para o Cajui, do zero

Para quem nunca comprou uso de API. Cada passo diz **o que fazer** e **por quê**. Decisão de arquitetura por trás deste guia: [ADR-010](../architecture/adr/ADR-010-integracao-com-a-deepseek.md).

## O que é isto, em três ideias

**API.** É um jeito de um programa pedir um serviço a outro pela internet. O servidor do Cajui manda um texto para a DeepSeek ("o que foi comprado aqui?") e recebe a resposta. Não existe tela: é programa falando com programa.

**Token.** É a unidade de cobrança — um pedaço de palavra. Uma frase curta tem uns 20 tokens. Paga-se pelo que entra (o texto enviado) e pelo que sai (a resposta).

**Chave de API.** Uma senha longa que identifica **quem paga a conta**. Quem tem a sua chave gasta o seu crédito. Por isso ela é o segredo mais sensível do projeto depois dos seus dados.

**O que a IA faz no Cajui:** sugere a categoria de um comprovante e conversa sobre os números do mês. **O app funciona inteiro sem ela** — com regras locais. Se o crédito acabar, nada quebra.

## Quanto custa

Preços lidos na [página oficial](https://api-docs.deepseek.com/quick_start/pricing) em **2026-09-20**, em dólares por **1 milhão** de tokens, para o modelo `deepseek-flash` — o que o Cajui usa:

| | Fora do pico | No pico |
|---|---|---|
| Entrada, já vista antes (*cache hit*) | US$ 0,003 | US$ 0,006 |
| Entrada nova (*cache miss*) | US$ 0,15 | US$ 0,30 |
| Saída | US$ 0,60 | US$ 1,20 |

O pico é de 01:00 a 04:00 e de 06:00 a 10:00 UTC, em dias úteis — no horário de Brasília, **22:00–01:00 e 03:00–07:00**. Quase todo o seu uso cai fora do pico.

**Ordem de grandeza:** 120 comprovantes por mês, com uns 1.500 tokens de entrada e 150 de saída cada, mais uma centena de perguntas ao assistente, somam menos de meio milhão de tokens. Isso dá **alguns centavos de dólar por mês**. A conta precisa, com tokens medidos de verdade, é feita na Fase 8 (`docs/ops/ai-cost-estimate.md`). Preço muda: confira a página antes de recarregar.

## 1. Criar a conta

1. Abra `https://platform.deepseek.com` e crie a conta com o seu e-mail.
2. Senha forte, guardada num gerenciador de senhas. Se houver autenticação em dois fatores, ligue.

**Por que uma conta só para isso?** Para o gasto da IA ficar isolado, visível e com teto — separado de qualquer outra coisa.

## 2. Colocar crédito — pouco

Em **Top up** (ou *Billing*), escolha o **menor valor oferecido**.

**Por quê:** o serviço é **pré-pago**. Não existe fatura-surpresa: quando o crédito acaba, a API para de responder e o Cajui passa a usar as regras locais. Pelo consumo estimado, o menor valor dura muitos meses. Recarregar pouco é o seu primeiro teto de gasto.

## 3. Gerar a chave de API

1. Em **API keys** → **Create new API key**. Dê um nome que diga onde ela será usada: `cajui-servidor`.
2. A chave aparece **uma única vez**. Copie e guarde **no gerenciador de senhas**, como uma nota segura.
3. Feche a janela. Se perder a chave, não há como ver de novo: apaga-se e cria-se outra.

**Por que um nome por uso?** Se um dia a chave vazar, você sabe qual apagar sem derrubar mais nada.

## 4. Onde a chave vai morar — e onde nunca

| Lugar | Pode? | Por quê |
|---|---|---|
| Servidor do Cajui, como **credencial cifrada do systemd** | **Sim — o único lugar** | Só o processo do servidor a recebe, em memória ([ADR-005](../architecture/adr/ADR-005-criptografia-em-repouso-e-dbtool.md)) |
| Gerenciador de senhas | Sim | É a sua cópia de segurança |
| Dentro do app Android ou da web | **Nunca** | Qualquer pessoa extrai uma chave de dentro de um APK em minutos |
| No repositório, mesmo privado | **Nunca** | O histórico do Git guarda para sempre, e o repositório vai ficar público |
| Arquivo `.env` versionado, captura de tela, conversa, e-mail | **Nunca** | Tudo isso vaza |

Na Fase 7, o roteiro de deploy pede a chave **uma vez**, no terminal da VM, e a transforma em credencial cifrada. Você cola direto lá; ela não passa por nenhum outro lugar.

## 5. Acompanhar o gasto

- Em **Usage**, na plataforma, aparece o consumo por dia. Olhe uma vez por semana no primeiro mês, para calibrar a expectativa.
- O Cajui tem o seu próprio teto: um **limite mensal de tokens**, definido por você nos ajustes. Ao bater o teto, o servidor para de chamar a IA até o mês virar, e o app avisa (`E-AI-03` do [catálogo de erros](../spec/error-catalog.md)). O consumo aparece dentro do app.

São dois tetos independentes — o crédito pré-pago e o limite do Cajui. Se um falhar, o outro segura.

## 6. Se a chave vazar

1. Na plataforma, **apague a chave** na hora. Ela para de funcionar imediatamente.
2. Crie outra, com outro nome (`cajui-servidor-2`).
3. Troque a credencial no servidor e reinicie o serviço (está no runbook).
4. Confira o **Usage** para ver se houve gasto estranho.

**Sinais de vazamento:** consumo em horário em que você não usou o app; consumo muito acima do normal.

## O que sai do seu aparelho para a DeepSeek

Vale saber, porque é um terceiro: **só texto, nunca a imagem** do comprovante; com CPF, contas, chave Pix e número de cartão **mascarados** antes de sair. Para o assistente, só **totais** — nunca a lista de lançamentos. O Cajui não controla o que a DeepSeek guarda do que recebe; por isso manda o mínimo.

## Glossário

| Termo | Em português claro |
|---|---|
| API | Programa pedindo serviço a outro programa pela internet |
| Token | Pedaço de palavra; a unidade de cobrança |
| Entrada · saída | O texto que você envia · a resposta que volta |
| Cache hit | Trecho de entrada que a DeepSeek já viu há pouco, cobrado muito mais barato |
| Pré-pago (*top up*) | Você recarrega antes e gasta do saldo |
| Chave de API | A senha que diz quem paga |
| Revogar | Apagar a chave para ela parar de funcionar |
