# Quanto custa a IA do Cajui

Preços **lidos na fonte** em 22/09/2026, em <https://api-docs.deepseek.com/quick_start/pricing>. O projeto usa `deepseek-flash`.

| Por 1 M de tokens | Fora do pico | No pico |
|---|---|---|
| Entrada, com cache | US$ 0,003 | US$ 0,006 |
| Entrada, sem cache | US$ 0,15 | US$ 0,30 |
| Saída | US$ 0,60 | US$ 1,20 |

O pico é 01:00–04:00 e 06:00–10:00 UTC, de segunda a sexta — ou seja, **22h–01h e 03h–07h em Brasília**. Quem usa um app de finanças de dia paga, quase sempre, a tarifa de fora do pico. As contas abaixo usam a **do pico**, que é o pior caso.

## O que faz o gasto ser pequeno

Três decisões, em ordem de efeito:

1. **A maior parte das perguntas não chega à IA** (RN-960). Limite da semana, como o mês fecha, para onde foi o dinheiro, saldo do vale, fatura, dívidas, resumo de hoje, cumprimento e "o que você faz" — onze intenções — são respondidas **no aparelho, de graça e sem internet**, pelo mesmo domínio que calcula o painel. São as perguntas que mais se repetem.
2. **O pedido é curto e estável.** O contexto leva só agregados por categoria, nunca a lista de lançamentos, e a ordem vai do que menos muda para o que mais muda (RN-916) — que é o que deixa o provedor reaproveitar o prefixo e cobrar a tarifa de cache.
3. **Teto e disjuntor.** Há um orçamento mensal de tokens gravado como evento, compartilhado entre a conversa e a classificação de comprovante (RN-960), e um disjuntor que para de tentar depois de falhas seguidas.

## A conta, para 120 lançamentos por mês

Tamanhos **estimados a partir do prompt**, não medidos — ver a ressalva no fim.

| | Entrada | Saída | Custo unitário (pico) |
|---|---|---|---|
| Pergunta ao assistente | ~1 800 tokens | ~200 tokens | US$ 0,00078 |
| Classificação de comprovante | ~1 200 tokens | ~150 tokens | US$ 0,00054 |

Cenário do plano — 120 lançamentos no mês, **todos** passando pela IA, mais 60 perguntas abertas (as que a camada local não responde):

```
120 × US$ 0,00054  = US$ 0,065
 60 × US$ 0,00078  = US$ 0,047
                     ---------
                     US$ 0,11  por mês  ≈  R$ 0,60
```

Com os **US$ 2,00** de crédito que já estão na conta, isso dá **mais de um ano** de uso — e o número real tende a ser menor, porque a tarifa de fora do pico é metade e porque nem todo lançamento é comprovante compartilhado.

O custo fixo do projeto continua **R$ 0,00**: VM gratuita, TLS gratuito, DNS gratuito, repositório gratuito, Vercel no plano Hobby.

## A ressalva honesta

O plano pedia tokens **medidos**, e estes são **estimados** a partir do tamanho do prompt e do contexto. O contador existe e é real — cada chamada grava o consumo como evento —, mas ler esses eventos exige entrar na VM, e a porta 22 estava fora do ar quando este documento foi escrito.

Como medir, quando ela voltar:

```bash
sudo systemd-run --pipe --quiet \
  --property=LoadCredentialEncrypted=cajui-data-key:/etc/cajui/cajui-data-key.cred \
  /opt/cajui/cajui-server db cat /var/lib/cajui | grep token
```

Até lá, vale o que está escrito aqui: **conta, e não medição**. A ordem de grandeza — centavos por mês — é segura; o número exato não.
