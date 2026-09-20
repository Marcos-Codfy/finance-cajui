# Movimento, toque e som

No Cajui, toda interação responde em três canais ao mesmo tempo — o olho vê, o dedo sente, o ouvido confirma. Os três são desenhados juntos, como um gesto só. Este documento fixa o caráter; a Fase 3 entrega os tokens (duração, curva, amplitude, arquivo) e a "mesa de som" para ouvir e aprovar cada um.

## Caráter

> **Macio, próximo, natural.** Nada bate, nada apita, nada pisca.

| Princípio | Significa |
|---|---|
| Física, não relógio | Elementos se movem com mola e inércia, não em linha reta com tempo fixo |
| Resposta antes de espetáculo | O toque responde em menos de 100 ms; a transição bonita vem depois, e nunca atrasa a leitura |
| Profundidade com propósito | Camadas e paralaxe mostram hierarquia (o que está em cima, o que ficou atrás), não enfeitam |
| Calma em má notícia | Tela de déficit entra devagar e sem som; alarme nenhum |
| Tudo tem versão parada | Cada efeito nasce com seu equivalente sem movimento e sem som |

## Movimento

| Gesto | Comportamento |
|---|---|
| Toque em botão ou cartão | Encolhe a 97% e volta com leve ultrapassagem (mola) |
| Lista entrando | Itens em cascata, 30–40 ms de diferença, subindo 12 px |
| Lista → detalhe | Elemento compartilhado: o cartão tocado cresce e vira a tela |
| Número mudando | Conta do valor antigo ao novo; algarismos tabulares para não tremer |
| Rolagem do painel | Cabeçalho em paralaxe: número-manchete encolhe e sobe mais devagar que a lista |
| Folha inferior | Sobe com mola, fundo escurece e desfoca de leve; arrastar para baixo fecha com inércia |
| Comprovante sendo lido | Linha de varredura sobre a imagem, no ritmo real do OCR — progresso verdadeiro, não animação em laço |
| IA pensando | Três pontos respirando, não girando |
| Conquista | O ícone-herói 3D entra girando e assenta; ramo de capim dourado, uma vez só |

Curva de referência para a mola: equivalente a `cubic-bezier(0.34, 1.56, 0.64, 1)`. Durações entre 180 ms (resposta a toque) e 420 ms (troca de tela). Nada passa de 600 ms.

### Três níveis de qualidade

| Nível | Quando | O que muda |
|---|---|---|
| `full` | Aparelho com folga de frame | Tudo acima, mais fundo com shader sutil |
| `lite` | Medição mostra quadros perdidos | Sem shader, sem desfoque, paralaxe simplificada; molas mantidas |
| `reduced` | `prefers-reduced-motion`, ou escolha manual | Transições viram fusão curta; sem paralaxe, sem cascata, sem contagem de número; heróis mostram o quadro final |

O nível é escolhido por medição no próprio aparelho, não por adivinhação de modelo. O efeito degrada; o app não trava. Meta: 60 quadros por segundo estáveis em `full` e `lite`.

## Toque

Resposta tátil leve e rara o bastante para significar algo.

| Evento | Vibração |
|---|---|
| Toque em controle | Clique leve |
| Alternar chave | Clique leve duplo, muito curto |
| Lançamento salvo | Confirmação média, única |
| Arrastar até o limite (puxar para atualizar, fechar folha) | Clique leve no ponto de engate |
| Aviso | Dois pulsos suaves — nunca o padrão longo de erro do sistema |

Segue a configuração de vibração do sistema e tem chave própria no app. Não existe na web.

## Som

### Paleta sonora

Sons curtos, secos e próximos — o tipo que dá gosto de ouvir de novo. O timbre imita material do Cerrado, não bipe eletrônico:

| Família | Material | Onde |
|---|---|---|
| Madeira | Batida leve em madeira oca, semente em cuia | Toques, alternâncias |
| Semente | Sementes secas rolando, castanha quebrando macio | Lançamento salvo, item adicionado |
| Água | Gota, pequena marola | Atualizar, sincronizar, sobra |
| Papel | Folha virando, papel deslizando | Comprovante recebido, folha abrindo |
| Capim | Palha roçando, trançado | Transições longas, conquista |

### Tokens previstos

`sound.tap` · `sound.toggle` · `sound.sheetOpen` · `sound.sheetClose` · `sound.swipe` · `sound.receiptIn` · `sound.scanLoop` · `sound.thinking` · `sound.entrySaved` · `sound.success` · `sound.notice` · `sound.achievement`

Não existe `sound.error`. O aviso (`sound.notice`) é uma nota grave e macia de madeira: informa sem assustar.

### Regras

1. **Desligado por padrão, com controle visível.** A primeira tela do onboarding oferece ligar, com prévia audível; um toque e está ligado.
2. **Curto e baixo.** Menos de 300 ms, volume bem abaixo de notificação do sistema, sem agudo áspero — passa-baixa em todos. A única exceção é o som de conquista (580 ms), que é raro por natureza.
3. **Nunca igual duas vezes seguidas.** Variação leve de altura a cada disparo; repetição mecânica é o que transforma som gostoso em irritante.
4. **Latência importa mais que fidelidade.** Som atrasado em relação ao toque é pior que nenhum som; tudo pré-carregado em memória.
5. **Nunca é o único sinal.** Toda informação dada por som também está na tela (WCAG 1.3.3).
6. **Silêncio em má notícia.** Tela de mês que não fecha não toca nada.
7. **Respeita o aparelho.** Modo silencioso e não perturbe vencem a preferência do app. Na web o áudio só começa depois de um gesto do usuário.
8. **Controle fino.** Volume próprio e três categorias que ligam e desligam separadas: toques, confirmações, ambiente.

### Origem e licença

Os sons atuais são **sintetizados pelo próprio projeto**: `tool/sound/build_sounds.py` monta cada um com seno e ruído filtrado — batida de madeira, grão de semente, gota d'água —, com semente fixa, de modo que rodar o script reproduz exatamente os mesmos arquivos. Não há amostra de terceiros, então não há licença externa a cumprir.

Se um som gravado vier a substituir um sintetizado, só entra material em domínio público (CC0) ou gravado para o projeto, registrado em `assets/CREDITS.md` com autor, endereço de origem e licença antes de entrar no repositório. O tratamento é o mesmo do script: fade nas pontas, filtro passa-baixa e pico normalizado bem abaixo do volume de uma notificação.
