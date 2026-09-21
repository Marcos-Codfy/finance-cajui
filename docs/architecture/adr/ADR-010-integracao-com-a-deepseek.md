# ADR-010 — Integração com a DeepSeek

- **Estado:** proposta · aguarda o checkpoint da Fase 4
- **Data:** 2026-09-20
- **Preço:** nenhum assumido. A leitura da página oficial é o BL-001, na Fase 8

## Contexto

A IA faz duas coisas: **classificar** o texto de um comprovante (o que foi comprado, onde, em que categoria) e **conversar** sobre os números do mês. Nos dois casos ela é um terceiro que recebe dado de uma pessoa, e nos dois a saída dela entra num app de dinheiro. O texto do OCR vem de um papel que qualquer um pode ter escrito — inclusive com a frase "ignore as instruções anteriores".

## Decisão

### Onde a chave mora
Só no backend, como credencial do systemd ([ADR-005](ADR-005-criptografia-em-repouso-e-dbtool.md)). Não existe no app, no pacote da web, no repositório nem em log. O app nunca fala com a DeepSeek.

### O que sai
1. **Só texto, nunca imagem.**
2. **Mascarado antes de sair**, no backend: CPF, nome do pagador, números de conta e agência, chave Pix (e-mail, telefone, aleatória), número de cartão e códigos de autenticação viram marcadores (`[CPF]`). Ficam o estabelecimento — inclusive o CNPJ dele, que é dado de empresa —, o valor e a data: o que a classificação precisa.
3. Para o assistente, **só agregados**: totais por bloco e por categoria, limites, saldos. Nunca o comprovante, nunca a lista crua de lançamentos (RN-9xx).

### Como o pedido é montado
1. **Prefixo fixo**: instruções, esquema de saída e as categorias do usuário, sempre na mesma ordem — é o que permite à API reaproveitar o prefixo entre chamadas.
2. **O texto do OCR entra por último, dentro de um bloco delimitado e nomeado como dado**, com a instrução explícita de que nada ali é comando.
3. Saída em **JSON**, temperatura zero, teto de tokens de resposta, sem ferramentas e sem chamada de função: a IA não executa nada.

### O que volta — e só é aceito se
1. For JSON válido no **esquema** esperado (`E-AI-04` se não for: a resposta é descartada e valem as regras locais).
2. A categoria for **uma das que foram enviadas**. A IA escolhe numa lista; não inventa categoria.
3. **Valor e data não vêm da IA quando o leitor local os achou.** O app mostra o que o OCR leu; divergência entre os dois baixa a confiança e vira pergunta — nunca correção silenciosa.
4. O texto de resposta do assistente passa pela lista de termos proibidos do guia de voz (RN-944).

Nada do que a IA devolve é gravado sem a confirmação do dono.

### Prazos, falhas e orçamento
| Situação | Comportamento |
|---|---|
| Classificação além de 8 s (RNF-PERF-08) | A confirmação abre com as regras locais; a resposta que chegar depois é descartada |
| Erro ou `5xx` | Uma nova tentativa, com recuo; depois, regras locais (`E-AI-01`) |
| `429` | Espera o prazo informado; o app mostra a contagem (`E-AI-02`) |
| Falhas em sequência | Disjuntor: o backend para de chamar por alguns minutos |
| Teto mensal de tokens (RNF-AI-04) | O backend soma o `usage` de cada resposta como evento; no teto, para de chamar (`E-AI-03`). O consumo aparece no app |

### Troca de fornecedor
O domínio conhece duas portas, `ReceiptClassifier` e `Assistant`. A DeepSeek é um adaptador; o classificador por regras é outro — e é ele que garante que **o app funciona inteiro sem IA**.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Chamar a IA direto do app | A chave iria para o APK, de onde qualquer um a extrai |
| Enviar a imagem para um modelo de visão | Contraria a regra central de privacidade, e custa mais |
| Deixar a IA devolver a categoria em texto livre | Abre a porta para categoria inventada e para injeção pela saída |
| Confiar no valor que a IA extraiu | Um comprovante malicioso poderia alterar o valor lançado. O número vem do leitor local |
| Modelo local no aparelho | Desejável para privacidade, inviável hoje em aparelho intermediário com a qualidade necessária. A porta `ReceiptClassifier` deixa o caminho aberto |

## Consequências

- **Bom:** a IA é um acelerador, não uma dependência: sem rede, sem saldo ou fora do ar, o fluxo de captura continua.
- **Bom:** um comprovante hostil consegue, no máximo, uma categoria errada **dentro da lista do usuário**, que ele vê e corrige antes de lançar.
- **Custo:** o mascaramento por padrões tem falso negativo — um dado pessoal em formato inesperado passa. A tela de privacidade diz isso com clareza (RN-989), e a suíte de testes cresce a cada formato novo encontrado.
- **Limite:** o Cajui não controla o que a DeepSeek guarda do que recebe. Por isso sai o mínimo.

## Como se confere

- **Suíte de comprovantes maliciosos** (Fase 5): textos com "ignore as instruções", com JSON embutido, com categoria falsa, com valor adulterado. Critério: a classificação não muda, e nada fora do esquema é aceito.
- Teste do mascaramento com um texto por tipo de dado pessoal, e a garantia de que o marcador saiu no lugar do dado.
- Teste do orçamento: no teto, nenhuma chamada sai.
