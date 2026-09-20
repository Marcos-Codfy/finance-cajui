# Cor

Paleta semente da marca. A Fase 3 transforma estas cores em tokens semânticos (`surface.elevated`, `text.muted`, `intent.notice`…) e estende cada uma em escala; nenhuma cor nova entra no produto sem passar por aqui.

## Direção

Superfícies quentes e calmas, **um único acento vivo**, ouro reservado para conquista. O requinte vem da contenção: a tela típica usa areia, castanha e um toque de cajuí — o resto da paleta aparece só quando tem algo a dizer.

Os dois temas são desenhados separadamente. O escuro não é o claro invertido: o fundo é um azul-petróleo profundo (o céu do Jalapão à noite), não preto, e os acentos são versões mais claras e menos saturadas, próprias para brilhar sobre ele.

## Paleta

### Tema claro

| Nome | Hex | De onde vem | Papel |
|---|---|---|---|
| Areia | `#FBF6EE` | Dunas do Jalapão | Fundo do app |
| Areia funda | `#F3EADC` | — | Fundo de seção, campo, chip |
| Papel | `#FFFFFF` | — | Cartão e folha elevada |
| Castanha | `#2A1D17` | A castanha do cajuí | Texto principal |
| Castanha suave | `#5F4E44` | — | Texto secundário |
| Castanha tênue | `#726157` | — | Legenda, rótulo, texto de apoio. Era `#7A685D`; escurecida para passar de 4,5:1 também sobre a areia funda |
| Contorno de campo | `#8F8073` | — | Contorno de campo: 3:1 contra areia, areia funda e papel. A areia funda sozinha (1,11:1 contra a areia) não delimita um campo |
| **Cajuí** | `#E4572E` | O fruto maduro | Acento de marca: só áreas grandes, gráficos, ilustração |
| **Cajuí forte** | `#B93D17` | — | Botão primário, link, número em destaque |
| Capim dourado | `#D9A441` | Capim dourado do Jalapão | Conquista e deleite; nunca cor de texto |
| Capim forte | `#8A6210` | — | Texto sobre fundo claro quando o ouro precisa falar |
| Vereda | `#2E6F57` | Buritizal | Sobra, progresso, confirmação |
| Barro | `#8C4A2F` | Terra vermelha | Atenção sem alarme (candidata a cor de déficit) |
| Céu | `#2F6F8F` | Céu de seca | Informação, foco de teclado |

### Tema escuro

| Nome | Hex | Papel |
|---|---|---|
| Noite | `#0F1A1E` | Fundo do app |
| Noite elevada | `#17262C` | Cartão |
| Noite alta | `#203239` | Folha, menu, campo |
| Luar | `#F4ECE0` | Texto principal |
| Luar suave | `#B9AFA3` | Texto secundário |
| Luar tênue | `#A3988D` | Legenda, rótulo. Era `#94897E`; clareado para passar de 4,5:1 também sobre a noite alta |
| Contorno de campo | `#6E7F84` | Contorno de campo: 3:1 contra as três superfícies escuras |
| Noite funda | `#0B1417` | Área rebaixada |
| Vermelho claro | `#FF8A80` | Só erro de sistema e ação destrutiva |
| Cajuí claro | `#FF8A5C` | Acento, botão primário (texto em noite) |
| Capim claro | `#F0C26A` | Conquista |
| Vereda clara | `#6FCBA6` | Sobra, progresso |
| Barro claro | `#E0A07F` | Atenção sem alarme |
| Céu claro | `#7FC1E0` | Informação, foco |

## Contraste medido

Razão de contraste pela fórmula de luminância relativa da WCAG 2.2. Metas: **4,5:1** para texto normal, **3:1** para texto grande (≥ 24 px, ou ≥ 18,66 px em negrito) e para componentes de interface.

### Tema claro

| Frente | Fundo | Razão | Resultado |
|---|---|---|---|
| Castanha | Areia | 15,17 | AAA |
| Castanha | Areia funda | 13,69 | AAA |
| Castanha suave | Areia | 7,34 | AAA |
| Castanha suave | Areia funda | 6,62 | AA |
| Castanha tênue | Areia | 4,92 | AA |
| Cajuí | Areia | 3,42 | **Só texto grande e componentes** |
| Cajuí forte | Areia | 5,22 | AA |
| Branco | Cajuí | 3,68 | **Só texto grande** — por isso o botão usa o forte |
| Branco | Cajuí forte | 5,61 | AA |
| Capim dourado | Areia | 2,09 | **Reprovado** — decorativo, nunca carrega informação sozinho |
| Capim forte | Areia | 5,09 | AA |
| Castanha | Capim dourado | 7,26 | AAA |
| Vereda | Areia | 5,53 | AA |
| Branco | Vereda | 5,95 | AA |
| Barro | Areia | 6,22 | AA |
| Céu | Areia | 5,15 | AA |

### Tema escuro

| Frente | Fundo | Razão | Resultado |
|---|---|---|---|
| Luar | Noite | 15,10 | AAA |
| Luar | Noite elevada | 13,27 | AAA |
| Luar suave | Noite | 8,19 | AAA |
| Luar suave | Noite elevada | 7,20 | AAA |
| Luar suave | Noite alta | 6,17 | AA |
| Luar tênue | Noite | 5,17 | AA |
| Luar tênue | Noite elevada | 4,55 | AA (no limite: não usar sobre noite alta) |
| Cajuí claro | Noite | 7,62 | AAA |
| Cajuí claro | Noite elevada | 6,70 | AA |
| Noite | Cajuí claro | 7,62 | AAA — texto do botão primário |
| Capim claro | Noite | 10,64 | AAA |
| Vereda clara | Noite | 9,07 | AAA |
| Vereda clara | Noite elevada | 7,98 | AAA |
| Barro claro | Noite | 8,01 | AAA |
| Barro claro | Noite elevada | 7,04 | AAA |
| Céu claro | Noite | 8,94 | AAA |

Desde a Fase 3 esta tabela **não é mais a fonte da verdade**: o que vale é o teste automatizado `packages/design_system/test/accessibility/contrast_audit_test.dart`, que percorre todos os pares de token usados juntos — lista em `ContrastAudit` —, nos dois temas e nas duas versões da falta do mês, e quebra o build se algum cair abaixo da meta. A gallery exibe a mesma lista, calculada ao vivo.

### O que o teste corrigiu

| Par | Antes | Depois | Correção |
|---|---|---|---|
| Castanha tênue sobre areia funda | 4,44 | 4,94 | Tinta de `#7A685D` para `#726157` |
| Luar tênue sobre noite alta | 3,89 | 4,71 | Tinta de `#94897E` para `#A3988D` |
| Areia funda sobre areia (limite de campo) | 1,11 | 3,55 | Campo ganha contorno próprio, `#8F8073` |
| Anel de foco "céu" contra botão "cajuí forte" | 1,01 | 5,22 e 5,15 | O anel é desenhado afastado, com folga na cor da superfície: folga × botão 5,22; anel × folga 5,15 |
| Cajuí do medidor contra o trilho | 2,79 | 3,09 | Trilho passa a areia funda |
| Vereda contra barro | 1,12 | — | Não se corrige na cor: os dois precisam de 4,5:1 sobre o mesmo fundo, então têm luminância parecida. Nunca aparecem como preenchimentos vizinhos, e sobra e falta sempre levam sinal, rótulo e ícone |

## Regras de uso

1. **Cor nunca é o único sinal.** Sobra e falta diferem também por texto, ícone e posição — requisito da WCAG 1.4.1 e proteção para quem não distingue verde de vermelho-terra.
2. **Cajuí puro não carrega texto pequeno.** Para texto e botão, é sempre o forte.
3. **Capim dourado é tempero.** Aparece em conquista, selo, detalhe de ilustração. Se a tela está dourada, tem dourado demais.
4. **O acento é um por tela.** Um botão primário, um número em destaque. Dois acentos competindo anulam os dois.

## Déficit: a decisão que fica para a Fase 3

O padrão de mercado é pintar de vermelho o mês que não fecha. A hipótese da marca — a ser confrontada com a literatura de ansiedade financeira na Fase 1 — é que o alarme cromático é justamente o que faz a pessoa parar de abrir o app.

A proposta alternativa já aparece na prancha: número em **barro** (terra, não sangue), barra de progresso em tons frios e calmos, e o peso visual da tela deslocado para a lista de ajustes possíveis. A versão em vermelho convencional será montada lado a lado na Fase 3 para a escolha ser feita olhando as duas.
