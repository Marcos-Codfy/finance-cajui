# Orçamento de performance do design

Os números que o produto precisa cumprir estão nos [requisitos não-funcionais](../spec/non-functional.md) (RNF-PERF e RNF-WEB). Este documento é a outra ponta: **quanto o design pode gastar** para que aqueles números fechem, e o que cada efeito perde quando o aparelho não aguenta.

Princípio: **o efeito degrada; o app não trava.** Todo efeito nasce com a sua versão mais barata e com a sua versão parada.

## Quadro

Meta: 60 quadros por segundo — 16,6 ms por quadro — nos níveis `full` e `lite` (RNF-PERF-01).

| O design pode | O design não pode |
|---|---|
| Animar opacidade, escala e posição (só composição) | Animar tamanho de layout, sombra ou desfoque quadro a quadro |
| Ter até 3 animações simultâneas numa tela, fora a cascata | Rodar animação em laço fora da área visível |
| Cascata de até 8 itens; do 9º em diante, entram juntos | Cascata em lista longa: custa mais do que mostra |
| Usar sombra estática no tema claro | Sombra no tema escuro (não se vê, e custa) |
| Desenhar ícone e ilustração em vetor (`CustomPainter` com `shouldRepaint` falso) | Imagem bitmap para ícone; repintar ilustração parada |

### Os três níveis

| Efeito | `full` | `lite` | `reduced` |
|---|---|---|---|
| Mola ao tocar | sim | sim | troca de cor, sem escala |
| Cascata de lista | sim | sim | itens prontos |
| Número que conta | sim | — | número pronto |
| Ilustração-herói em movimento | sim | parada | parada |
| Esqueleto pulsando · três pontos | sim | sim | parados |
| Paralaxe do painel · elemento compartilhado | sim | simplificados | fusão de 120 ms |
| Desfoque atrás de folha · shader de fundo | sim | — | — |

Quem escolhe o nível é o `MotionLevelResolver`, nesta ordem: **sistema** (movimento reduzido ligado → `reduced`) · **medição** (mais de 5% dos quadros acima de 16,6 ms numa janela de 120 → cai para `lite` e não volta a subir na sessão, RNF-PERF-02) · **preferência** de quem usa. Nunca pelo modelo do aparelho.

## Tempo

| Momento | Orçamento | De onde vem |
|---|---|---|
| Do toque ao estado pressionado | < 100 ms; alvo de 2 quadros | RNF-PERF-04 — nada no caminho do toque espera rede, disco ou IA |
| Do toque ao início do som | ≤ 80 ms; acima de 100 ms, os sons de toque se desligam naquele aparelho | RNF-PERF-05 — sons pré-carregados, tocador de baixa latência |
| Resposta a toque | 180 ms (`fast`) | Token |
| Troca de tela | 420 ms (`slow`) | Token |
| Qualquer animação | ≤ 600 ms (`slowest`) | Token — o teto |
| Esqueleto antes de virar erro de prazo | 10 s | `E-NET-02` do [catálogo](../spec/error-catalog.md) |

Carregamento com menos de 300 ms não mostra esqueleto: piscar um esqueleto é pior que esperar um instante.

## Tamanho

Medido em 2026-09-20, no pacote e no build web da gallery (`flutter build web`, sem wasm).

| Item | Medido | Teto | Situação |
|---|---|---|---|
| Fraunces (variável, 4 eixos) | 352 KB · 246 KB comprimida | — | |
| Geist (variável, 1 eixo) | 165 KB · 87 KB comprimida | — | |
| **Fontes, comprimidas** | **333 KB** | 200 KB (RNF-WEB-06) | **Acima do teto** → BL-025 |
| Sons: 10 arquivos WAV | 180 KB · 152 KB comprimidos | 200 KB | Dentro, com folga curta → BL-026 |
| Ícones e ilustração | 0 KB de arquivo: são código | — | |
| Código da gallery (`main.dart.js`) | 1,63 MB · 507 KB comprimido | 1,0 MB comprimido para o app (RNF-WEB-06) | Referência: a gallery não é o app |

O que a medição ensinou:

- **As fontes estouram o orçamento da web**, e a culpada é a Fraunces com quatro eixos variáveis. O design usa só dois (`opsz` e `wght`); `SOFT` e `WONK` ficam fixos. Fixar esses eixos e recortar para o alfabeto latino deve trazer o par para perto de 150 KB. Está no BL-025, para o spike da web na Fase 4 — antes disso o número é projeção, não promessa.
- **Não há imagem no design system.** Ícones, logo e ilustração são vetores em código: escalam para qualquer densidade de tela e não pesam no download.
- No Android, fontes e sons somam cerca de 0,7 MB de um teto de 40 MB de APK (RNF-PERF-11): irrelevante.

## Som

| Regra | Número |
|---|---|
| Duração | ≤ 300 ms; a única exceção é `achievement`, com 580 ms |
| Volume padrão | 0,6 de 1, com pico normalizado bem abaixo do de uma notificação |
| Carregamento | Os 10 sons ficam em memória desde a abertura; nada é lido do disco na hora de tocar |
| Simultâneos | Um tocador por som: o toque seguinte não espera o anterior acabar |
| Falha | Som que não carrega não derruba nada: o app segue mudo |

## Como se confere

| O quê | Como | Quando |
|---|---|---|
| Quadros perdidos | `FrameBudgetMonitor` no próprio app, em uso real | Sempre — é o que alimenta o nível de movimento |
| Os cinco percursos da RNF-PERF-01 | Teste de integração com medição de quadros, em aparelho de referência | Fase 6 |
| Latência do som | Medição no spike de áudio (BL-009) | Fase 4 |
| Tamanho do build web | Lighthouse CI e asserção de tamanho | Fase 4 (spike) e Fase 6 (CI) |
| Movimento reduzido | `test/motion/motion_test.dart` | A cada commit |

Quando um número medido contrariar este orçamento, **muda-se o design ou muda-se o orçamento — por escrito, aqui.** O que não pode é o número ficar errado em silêncio.
