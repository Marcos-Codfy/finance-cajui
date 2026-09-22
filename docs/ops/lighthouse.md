# Lighthouse da web de consulta

Medido em **22/09/2026**, no build de produção servido localmente, preset **desktop** — o preset oficial, porque a web é modo consulta em computador (ADR-013).

```bash
npx lighthouse@12 http://localhost:5182 --preset=desktop
```

| Categoria | Nota | Meta do plano |
|---|---|---|
| Desempenho | **60** | ≥ 90 |
| Acessibilidade | **100** | ≥ 90 |
| Boas práticas | **81** | ≥ 90 |
| SEO | **60** | — (ver abaixo) |

| Métrica | Valor |
|---|---|
| Primeira tinta com conteúdo (FCP) | 0,2 s |
| Maior elemento pintado (LCP) | 0,3 s |
| Tempo total bloqueado (TBT) | **2 650 ms** |

## O que os números dizem

**Acessibilidade 100.** É a nota que mais custou e a que mais importa: a árvore de semântica do Flutter nasce ligada (`ensureSemantics` na raiz, ADR-013), a casca HTML tem idioma e a abertura é `role="status"`. Leitor de tela lê a página desde o primeiro instante.

**FCP e LCP abaixo de meio segundo.** É a casca HTML própria fazendo efeito: a página pinta na cor do tema e escreve "Abrindo o Cajui…" antes de o motor existir. Sem ela, o navegador mostraria branco até o Flutter subir.

**Desempenho 60, e a culpa é do TBT.** Os 2,65 s de bloqueio são o motor do Flutter compilando e inicializando na linha principal. Não é código do Cajui: é o custo de renderizar em canvas. Era **o risco número 1 registrado no plano**, e o plano dizia o que fazer se não batesse 90: *"você decide com número na mão"*. O número está aqui.

Os caminhos conhecidos, em ordem de proveito:
1. **`--wasm`** em vez de JavaScript compilado. O plano já previa; o build atual avisa que o modo seco de WASM tem pendências a resolver.
2. **Emagrecer as fontes** (BL-025): 333 KB comprimidos contra um teto de 200 KB.
3. Carregamento adiado das partes que a consulta não usa.

Nenhum deles muda a natureza da coisa: Flutter Web carrega um motor. Um site de consulta escrito em HTML puro ganharia essa categoria com folga — e perderia a vantagem de compartilhar tela por tela com o app, que é o motivo de a web existir assim (ADR-013).

**SEO 60 é escolha, não defeito.** A página declara `noindex, nofollow`: são os dados financeiros de uma pessoa, e não há motivo nenhum para eles entrarem em busca. O Lighthouse desconta por isso, e está certo do ponto de vista dele. Do nosso, subir essa nota seria piorar o produto.

**Boas práticas 81** ainda não foi destrinchado — entra no mesmo lote do desempenho.

## Decisão

A meta de ≥ 90 **não foi atingida em Desempenho**, e fica registrada como não atingida, com o motivo medido. Não há conserto barato: o que existe são três caminhos, todos no backlog, e nenhum deles é obrigatório para a web cumprir o que ela promete hoje — consultar e conversar.

O que **não** se faz é mexer no `noindex` para subir uma nota.
