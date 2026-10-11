# ADR-028 — Rolagem 3D e entrada cinematográfica: perspectiva por matriz, na pintura

**Estado:** proposta · 11/10/2026. Vira aceita quando o dono aprovar no aparelho.

O dono cobrou: "coloque alguma outra coisa em 3d, esqueceu que eu te pedi um 3d scrolling? com animações cinematográficas?". A [ADR-026](ADR-026-ux-viva.md) trouxe 3D em peças — o pote, o cartão —, mas a tela continuava uma folha plana que rola.

**Relacionada:**
- [ADR-026](ADR-026-ux-viva.md): os efeitos moram no design system; o app só liga.
- [ADR-016](ADR-016-motor-de-audio.md): o som é token; o carrossel usa o `swipe`, que já existia sem uso.
- RNF-PERF-01 e RNF-PERF-02 (60 quadros; o nível cai por medição), RNF-A11Y-04, -06, -07, -08 e -10.

## Contexto

Havia três jeitos de pôr profundidade na tela:

| Caminho | O que é | Por que não |
|---|---|---|
| Motor 3D de verdade | Cena com malhas e câmera (`flutter_scene`, ou three.js na web) | Dependência pesada e ainda em prévia. O conteúdo teria de virar textura: o texto deixa de ser texto, o leitor de tela e o toque deixam de funcionar sem trabalho extra, e a web ficaria diferente do Android |
| Sombreador de fragmento | Um `FragmentProgram` que deforma a imagem da tela | Deforma pixels, não blocos: o texto borra na curva, o toque não acompanha a deformação, e o custo é por pixel, em todo quadro |
| **Perspectiva por matriz** | Uma `Matrix4` com o termo de perspectiva, aplicada a cada bloco na hora de pintar | — |

E quatro limites que não se negociam: 60 quadros num celular médio, nada passa de 600 ms, nada depende só do movimento, e tudo tem versão parada.

## Decisão

1. **Perspectiva por matriz, aplicada na pintura.** Cada bloco é pintado com uma `Matrix4` (giro, escala, deslocamento e o termo de perspectiva). O texto continua texto, nítido; o toque e o leitor de tela seguem a mesma matriz (`applyPaintTransform`); e o efeito é o mesmo no Android, na web e no teste, sem dependência nova.
2. **Uma câmera só.** `CajuiDepth.perspective` (0,0012, uns 830 px de distância) vale para o cartão que vira, a rolagem, o carrossel e a entrada. Com lentes diferentes, cada efeito seria bonito sozinho e estranho ao lado do outro.
3. **A conta é função pura.** `SpacePose` descreve um bloco no espaço; `DrumPose` (rolagem), `CarouselPose` (carrossel), `ArrivalPose` (entrada) e `WalletPose` (carteira) dizem a pose de cada situação. Os testes conferem a conta sem montar tela.
4. **Na pintura, e não no layout nem na montagem.** A rolagem e a carteira têm um objeto de pintura próprio (`RenderViewportPose`, `RenderWalletStack`) que lê a posição do bloco **depois** do layout do quadro — sem o atraso de um quadro que ler a posição na montagem teria — e só repinta. Rolar não reconstrói widget nem mede nada de novo; cada seção fica num `RepaintBoundary` e é reaproveitada.
5. **Plano onde se lê.** Na rolagem, só curva o que está cortado pela borda (a faixa é 32% da altura da tela, no máximo a altura do bloco). Bloco inteiro à vista fica plano, com matriz identidade exata e sem camada nenhuma.
6. **Os componentes:**

   | Componente | O que faz |
   |---|---|
   | `CajuiDepthScroll` | A tela como face de um tambor: entra deitado por baixo, assenta, recua por cima e é coberto pelo seguinte. Fundo em paralaxe a 1/3 da velocidade. Física que quica, sempre rolável |
   | `CajuiParallax` | Uma camada que anda em outra velocidade dentro de qualquer rolagem |
   | `CajuiCoverFlow` | Carrossel 3D: encaixe com mola (`CajuiSprings.page`), um gesto passa uma página só, vizinhas tocáveis, pontos que são um controle ajustável, "Página X de Y" em cada página |
   | `CajuiCinematicEntrance` + `CajuiCinematicShot` | O travelling ao abrir a tela: de longe, de baixo e fora de foco para o lugar, com `CajuiCurves.settle`, em cascata de 35 ms, e uma faixa de luz que cruza uma vez. Cabe nos 600 ms |
   | `CajuiWalletStack` | Os cartões saem de um maço ao aparecer, param no alto da tela e se empilham ao rolar, e se abrem em leque ao puxar além do topo |
   | `CajuiScreen(depth:, cinematic:)` | O esqueleto de toda tela liga os dois efeitos sem montagem à mão |

7. **Os três níveis.** O nível vem do tema e, por garantia, também de `MediaQuery.disableAnimations`.

   | Efeito | `full` | `lite` | `reduced` |
   |---|---|---|---|
   | Rolagem | curva, esmaece, fundo em paralaxe | curva, sem esmaecer | lista comum, plana, fundo parado |
   | Carrossel | gira, encolhe, esmaece | igual | lado a lado, plano; trocar é corte com esmaecer de 120 ms |
   | Entrada | viagem, desfoque e luz | viagem, sem desfoque nem luz | os blocos esmaecem juntos, em 120 ms |
   | Carteira | maço, pilha e leque, os de trás escurecem | sem escurecer | coluna parada |

   A forma da árvore de widgets é a mesma nos três: o nível pode cair no meio da sessão (quadros perdidos viram `lite`) sem remontar a tela, e a rolagem não volta ao topo.

8. **O desfoque é uma exceção com nome.** O orçamento de performance proíbe animar desfoque quadro a quadro. A entrada o faz, e só assim: no `full`, por no máximo 600 ms, em até seis blocos com a cascata, e com o filtro **desligado** (sem camada) ao fim. Se o aparelho perder quadros, o monitor baixa para `lite`, e o desfoque some.
9. **O retorno sensorial.** `CajuiFeedback.pageTurned()`: o som `swipe` (família ambiente, que se cala sozinha) e o pulso de tecla. Toca no soltar do dedo, não no fim da mola — a resposta vem antes do espetáculo.
10. **Uma vez, e só à vista.** A entrada roda uma vez por montagem e de novo só quando a chave muda (o mês). Montada atrás de outra aba, espera a tela aparecer (`TickerMode`).

## Custo por quadro

| Efeito | Enquanto se move | Parado |
|---|---|---|
| Rolagem | uma matriz por seção à vista; camada de matriz só nas cortadas (em geral duas), e de opacidade só no `full` | nada além da lista |
| Carrossel | três ou quatro invólucros de matriz e opacidade; as páginas não se reconstroem; a ordem de pintura só muda quando o centro muda | nada |
| Entrada | por bloco: matriz, opacidade e desfoque, por até 600 ms | zero: matriz identidade, opacidade 1, filtro desligado |
| Carteira | uma matriz por cartão | nada além da coluna |

## Consequências

- API pública nova no design system: `CajuiDepthScroll`, `CajuiParallax`, `CajuiCoverFlow`, `CajuiCinematicEntrance`, `CajuiCinematicShot`, `CajuiWalletStack`, `CajuiDepth`, `CajuiCurves.settle`, `CajuiSprings.page` e os parâmetros `depth`, `backdrop`, `cinematic` e `replayKey` do `CajuiScreen`.
- `CajuiFeedback` ganhou um método. Quem implementa a interface — hoje só o próprio design system — precisa dele.
- A rolagem em profundidade quica no Android também. Além do toque de material, isso tira dessas telas o brilho branco de fim de lista que o Android desenha por padrão, e que não é da marca.
- O cartão 3D passou a ler a lente de `CajuiDepth`. O valor não mudou.
- A gallery ganhou o grupo **Profundidade**, com uma página por componente, num palco do tamanho de um celular.

**Não validado:**
- os quadros em `--profile` no Poco, com as três camadas juntas (rolagem, carrossel e entrada);
- o deslize e o pulso do carrossel ouvidos e sentidos no aparelho;
- o TalkBack percorrendo o carrossel: o foco numa página fora do palco deve trazê-la ao centro;
- rolar o carrossel com o trackpad na web: hoje ele vai por arrasto, toque e teclado.

## Complemento de 11/10/2026: a câmera entre telas e o 3D no app

O dono pediu também "movimentação de câmera". A mesma lente (`CajuiDepth`) passou a mover a câmera entre telas, com as poses em funções puras (`CameraMove`):

- **Abrir uma tela** (`CajuiPageRoute`) é a câmera avançando. A tela nova chega de longe, deitada uns 10°, menor e de baixo, e assenta com a curva `settle`; a de trás recua e apaga. Voltar é o mesmo movimento ao contrário.
- **Trocar de aba** (`CajuiOrbitStack`, no lugar do `IndexedStack`) é a câmera orbitando. A aba que chega vem do lado da ida, girada uns 34°, e a que sai vai para o lado oposto. As duas guardam o estado, e só a da frente recebe toque.
- A árvore de widgets tem a mesma forma em movimento e em repouso (`CajuiPosed`). Tirar a transformação no fim faria a tela que acabou de chegar perder a rolagem e o que foi digitado.

No app:
- **Início:** os números do mês num carrossel 3D (sobra ou falta, o que entra, o que sai do bolso e vale), com rolagem em profundidade e entrada cinematográfica, que roda de novo quando o mês vira.
- **Cartões:** carteira 3D.
- **Telas de lista** (Meu mês, Mês a mês, Minhas contas, Vale, Dívidas, Lançamentos, Ajustes): rolagem em profundidade e entrada cinematográfica.
- **Juju:** fica plana, porque o mais novo da conversa nasce na borda de baixo, onde a rolagem curvaria.
- O pote de água saiu do design system junto com o limite semanal.
