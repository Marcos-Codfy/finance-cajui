# Iconografia

Dois registros, com papéis que não se misturam:

| Registro | Onde | Função |
|---|---|---|
| **Traço** | Navegação, botões, listas, campos | Reconhecimento rápido; some no fundo |
| **Volume (3D)** | Onboarding, estados vazios, conquistas, tela de abertura | Emoção e identidade; é o que se lembra do app |

Regra: no máximo **um** ícone-herói em 3D por tela. Volume em todo lugar vira ruído — e custa frame.

## Ícones de traço

| Atributo | Valor |
|---|---|
| Grade | 24 × 24, área viva de 20 × 20 |
| Traço | 1,75 px, único, sem preenchimento |
| Terminações e junções | Redondas — o mesmo gesto das pontas da castanha do logo |
| Raio de canto | 3 px em retângulos |
| Cor | Herdada do texto ao redor (`currentColor`) |
| Estado ativo | Mesmo desenho com preenchimento suave a 12% da cor, não uma versão "cheia" diferente |
| Alvo de toque | O ícone tem 24 px; a área tocável, no mínimo 48 × 48 (acima do mínimo de 24 × 24 da WCAG 2.5.8) |

Ponto de partida: uma biblioteca aberta de traço arredondado (Lucide ou Phosphor, ambas com licença permissiva), completada com desenhos próprios no mesmo traço para o que é específico do produto. A escolha da biblioteca e a lista final entram na Fase 3, com a licença registrada em `assets/CREDITS.md`.

Ícones próprios previstos:

| Conceito | Ideia de desenho |
|---|---|
| Vale alimentação | Cartão com um garfo — nunca cifrão, porque vale não é dinheiro |
| Forma de pagamento | Seta saindo de uma carteira: "por onde saiu" |
| Bloco fixo | Âncora simplificada ou cadeado de calendário |
| Bloco variável | Faixa com duas marcas (mínimo e máximo) |
| Bloco dívida | Escada descendo: parcelas que acabam |
| Fatura (visão derivada) | Cartão com olho — é uma lente, não um gasto |
| Compartilhar comprovante | Recibo entrando numa bandeja |
| Confiança da IA | Três pontos empilhados, preenchidos conforme o nível |

Todo ícone que carrega significado vem com rótulo de texto ou nome acessível; ícone decorativo é escondido do leitor de tela.

## Ícones-herói em 3D

### Estilo

| Atributo | Direção |
|---|---|
| Matéria | Macia e fosca — argila, fruta, semente. Nada de vidro, cromo ou plástico brilhante |
| Forma | Volumes simples, cantos generosos, leve exagero de proporção |
| Luz | Uma fonte principal, de cima à esquerda; luz de recorte quente embaixo à direita |
| Sombra | De contato, difusa, em castanha a ~28% — nunca preta |
| Cor | Só a paleta da marca; gradientes internos dentro do mesmo matiz |
| Inclinação | Objetos levemente girados, como o símbolo (−14°) |
| Fundo | Transparente, para viver sobre areia e sobre noite |

O estudo em [`assets/hero-3d-concept.svg`](assets/hero-3d-concept.svg) mostra a direção aplicada ao próprio cajuí.

### Elenco inicial

| Objeto | Onde aparece |
|---|---|
| Cajuí | Abertura, onboarding, "todo mês rebrota" no fechamento |
| Castanha aberta com moeda | Primeira sobra do mês |
| Comprovante enrolado | Estado vazio da lista; leitura de comprovante em andamento |
| Cartão atravessado por uma seta | Explicação "cartão é forma de pagamento" |
| Marmita / garfo | Vale alimentação |
| Broto saindo da terra queimada | Mês que fechou no aperto: o recomeço |
| Ramo de capim dourado | Conquista (semanas seguidas dentro do limite) |
| Buriti com água | Reserva, quando existir |

### Como entra no app

A decisão técnica é da Fase 3 e depende de medição. Ordem de preferência, do mais barato ao mais caro em frame:

1. **Imagem pré-renderizada** (WebP com transparência, em 2 ou 3 densidades) — custo de execução quase zero; é o padrão.
2. **Sequência curta ou Rive/Lottie** para os poucos heróis que se mexem (o broto que nasce, a moeda que cai).
3. **3D em tempo real** — só se a medição mostrar folga em aparelho modesto; caso contrário, fica fora.

Modelagem e render com ferramenta gratuita (Blender), a partir de modelos próprios — nada de pacote de ícones 3D com licença duvidosa. Cada arquivo entra em `assets/CREDITS.md`.

Em `prefers-reduced-motion` ou no modo de movimento reduzido, os heróis animados mostram o quadro final, parados.

## Emoji

Emoji serve só como ícone de categoria em lista (🛒 Mercado, 🚌 Transporte), onde a cor ajuda o olho a varrer. Nunca como pontuação emocional em frase. Na Fase 3 avalia-se trocá-los por um conjunto próprio de traço, para a aparência não mudar de fabricante para fabricante.
