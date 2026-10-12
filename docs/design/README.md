# Design system do Cajui

O design system é um pacote Dart — [`packages/design_system`](../../packages/design_system) — e a sua documentação viva é a **gallery**, um app Flutter que importa o pacote e mostra tudo o que ele tem. Estes documentos explicam as decisões; a gallery mostra o resultado.

| Documento | Responde |
|---|---|
| [tokens.md](tokens.md) | Como os tokens se organizam, e onde mexer para mudar o quê |
| [components.md](components.md) | Quais componentes existem, os estados de cada um e as regras de uso |
| [performance-budget.md](performance-budget.md) | Quanto o design pode custar em quadro, em tamanho e em tempo |
| [../brand/](../brand/) | Por que a marca é como é: voz, cor, tipo, movimento e som |
| [../spec/error-catalog.md](../spec/error-catalog.md) | O texto e a saída de cada erro |

## A regra que sustenta o resto

**O app nunca define aparência.** Cor, tipo, espaço, raio, sombra, duração, curva e som saem do pacote, por nome de papel. Fora de `packages/design_system` não existe `Color(0x…)`, `TextStyle(` nem `Duration(milliseconds:` de interface.

A consequência prática: trocar a cor de todos os botões de ação do app é editar **uma linha** — `action.primary` em `lib/src/tokens/semantic/action_colors.dart`. O teste de contraste roda em seguida e diz se a cor nova ainda passa na WCAG.

## Como ver a gallery

```bash
cd packages/design_system/gallery
flutter run -d chrome
```

Publicada em <https://cajui-teal.vercel.app/gallery/>. Cada página tem endereço próprio (`#/estados-das-telas`, `#/inicio?estado=sem-rede`), e o menu tem cinco grupos, na ordem de quem chega frio:

| Grupo | O que mostra |
|---|---|
| Comece aqui | A visão geral: o que é o Cajui, o widget de vidro de verdade, os atalhos para o que o projeto tem de diferente e os números contados do código |
| O app | Estados das telas (as 7 telas nos 69 estados da [matriz de telas](../spec/use-cases.md#telas-e-seus-estados), lado a lado, em miniaturas que abrem a tela grande) e cada tela: Início, Juju, Comprovante, Fatura do cartão, Fechamento do mês, Dívidas e Widget da tela inicial |
| Movimento e som | Rolagem em profundidade, carrossel 3D, entrada cinematográfica, pilha de cartões e troca de tela, cada um num aparelho; as microinterações; a mesa de movimento (curvas, durações e os três níveis) e a mesa de som |
| Componentes | Botões e controles, valores e cartões, campos, aviso/vazio/carregando e conversa — cada componente em todos os estados, com o nome do estado em português e o da API ao lado |
| Fundamentos | Faça e evite (as regras do Cajui em pares), cores por papel, a cor da falta (barro, a escolhida, ao lado do vermelho), contraste calculado ao vivo, tipografia, espaço, raio e sombra, e ícones |

Tema, som, nível de movimento e cor da falta ficam em **Ajustes** (no pé do menu, ou no botão do alto no celular) e valem para a gallery inteira: qualquer estado pode ser conferido nos dois temas em dois toques.

## Como se garante que continua certo

| Garantia | Onde |
|---|---|
| Todo par de cor usado passa na WCAG 2.2 AA, nos dois temas | `test/accessibility/contrast_audit_test.dart` — a mesma lista de pares alimenta a página Contraste |
| Todo controle tem alvo de 48, foco visível, nome para leitor de tela e funciona por teclado | `test/components/*_test.dart`, sobre a base `CajuiPressable` |
| Rótulo longo e fonte ampliada não estouram a tela | Teste do chip e teste de fumaça da gallery em 390 × 844 |
| Movimento reduzido é respeitado | `test/motion/motion_test.dart`, `test/motion/number_motion_test.dart` e o teste de cada efeito vivo |
| Nada se move em laço: a física assenta sozinha | `test/motion/spring_physics_test.dart` |
| No 3D, o que se lê fica plano, tudo cai para plano no reduzido, e o carrossel se usa sem arrastar | `test/components/depth_scroll_test.dart`, `cover_flow_test.dart`, `wallet_stack_test.dart`, `screen_depth_test.dart` e `test/motion/cinematic_entrance_test.dart` |
| O som nasce desligado, e não existe som de erro | `test/sound/sound_feedback_test.dart` |
| Toda página e todo estado de tela abrem sem erro | `gallery/test/gallery_smoke_test.dart` |
| Arquivo ≤ 300 linhas, função ≤ 30, aninhamento ≤ 3 | `tool/` (verificador próprio) |

## Como acrescentar

- **Um token**: no arquivo do grupo em `lib/src/tokens/`. Se for cor, incluir os pares em `ContrastAudit` — cor sem par medido não entra.
- **Um componente**: pasta em `lib/src/components/`, sobre `CajuiPressable` se for tocável; export em `lib/design_system.dart`; teste; exemplares na página do grupo na gallery, com todos os estados.
- **Uma página da gallery**: um valor em `GalleryDestination` (nome, grupo e endereço) e uma entrada no mapa de `gallery_pages.dart`. Um teste confere que todo destino tem página.
- **Uma tela de estado**: pasta em `gallery/lib/src/pages/screens/`, devolvendo um `ScreenStatePage`, com os estados num `variants()` estático e a tela no `ScreenCatalog`. O teste de fumaça passa a percorrer os estados dela sozinho, e a vitrine Estados das telas a mostra. A nota de cada estado começa pela regra ("RN-441: …"); a página mostra a frase limpa e a regra à parte.
