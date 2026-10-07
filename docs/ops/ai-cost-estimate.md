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

Tamanhos **medidos**, e não estimados. O servidor grava o consumo de cada
chamada como evento `ai.usage_recorded`; estes são os números lidos do
registro cifrado da VM em 22/09, com `server db cat`:

| Chamada | Entrada | Saída |
|---|---|---|
| 1 | 729 | 123 |
| 2 | 843 | 163 |
| 3 | 999 | 160 |
| 4 | 498 | 110 |
| **média** | **767** | **139** |

| | Custo unitário (pico) | Fora do pico |
|---|---|---|
| Uma chamada, com a média medida | US$ 0,00040 | US$ 0,00020 |

Cenário do plano — 120 lançamentos no mês, **todos** passando pela IA, mais 60 perguntas abertas (as que a camada local não responde):

```
180 chamadas × US$ 0,00040  =  US$ 0,072 por mês  ≈  R$ 0,39   (pico)
180 chamadas × US$ 0,00020  =  US$ 0,036 por mês  ≈  R$ 0,20   (fora do pico)
```

Com os **US$ 2,00** de crédito que já estão na conta, isso dá **mais de dois
anos** de uso. E o número tende a ser menor ainda: quem usa um app de
finanças de dia paga a tarifa de fora do pico, e nem todo lançamento é
comprovante compartilhado.

A primeira versão deste documento estimava 1 800 tokens de entrada por
chamada. A medição deu **767** — menos da metade. Vale como lembrete de que
estimativa de prompt erra para cima com facilidade.

O custo fixo do projeto continua **R$ 0,00**: VM gratuita, TLS gratuito, DNS gratuito, repositório gratuito, Vercel no plano Hobby.

## Com a foto (07/10/2026, ADR-022)

A DeepSeek conta **até 1.024 tokens por imagem**, cobrados como entrada. Uma leitura com foto leva uns 1.650 tokens de entrada (texto lido, categorias e a imagem) e uns 100 a 200 de saída:

| Por comprovante | No pico | Fora do pico |
|---|---|---|
| Só texto, como antes | US$ 0,0004 | US$ 0,0002 |
| Com a foto | US$ 0,0007 | US$ 0,0004 |

O cupom de mercado que as regras leem inteiro não chama a IA: custa zero. Cem fotos no mês dão uns US$ 0,07.

## A ressalva honesta

O plano pedia tokens **medidos**, e estes são **estimados** a partir do tamanho do prompt e do contexto. O contador existe e é real — cada chamada grava o consumo como evento —, mas ler esses eventos exige entrar na VM, e a porta 22 estava fora do ar quando este documento foi escrito.

Como medir, quando ela voltar:

```bash
sudo systemd-run --pipe --quiet \
  --property=LoadCredentialEncrypted=cajui-data-key:/etc/cajui/cajui-data-key.cred \
  /opt/cajui/cajui-server db cat /var/lib/cajui | grep token
```

Até lá, vale o que está escrito aqui: **conta, e não medição**. A ordem de grandeza — centavos por mês — é segura; o número exato não.
