# Origem dos arquivos do design system

Tudo o que o pacote empacota tem a origem registrada aqui antes de entrar no repositório. Arquivo sem linha nesta página não entra.

## Sons (`sounds/`)

Há duas origens: os sons de toque são **gravações escolhidas pelo dono** (11/10/2026), e o resto é **sintetizado pelo próprio projeto**.

### Gravados — os sons de toque

O dono escolheu um som para cada família de controle: botões de ação, cards, teclas, e chaves e chips. Os quatro vêm do [Pixabay](https://pixabay.com/sound-effects/), sob a [Pixabay Content License](https://pixabay.com/service/license/). Ela permite usar e modificar, inclusive em uso comercial, sem exigir crédito; o crédito vai aqui mesmo assim. O que ela proíbe é distribuir o arquivo **sozinho**, como som avulso. Por isso o repositório não guarda os MP3 originais, só o resultado tratado, como parte do app.

| Arquivo | Token | Origem (autor no Pixabay · código) | Tratamento | Duração |
|---|---|---|---|---|
| `tap.wav` | `CajuiSound.tap` | "Soft App Button Tap Sound 5", vadim_makes_sound · 547873 — trocado em 12/10/2026 a pedido do dono: o "Modern Button Click" (freesoundeffects · 291234), saturado para aparecer no celular, ficou feio | Começo no ataque (o original abre com 23 ms de silêncio), corte em 150 ms com saída de 60 ms | 150 ms |
| `card.wav` | `card` | "Minimal Pop Click UI 2", floraphonic · 198302 | Corte em 70 ms com saída de 25 ms | 70 ms |
| `key.wav` | `key` | "ImmersiveControl Button Click Sound", denielcz · 463065 | Corte do clique, pico em −6 dBFS: a tecla soa a cada letra e fica mais baixa que os outros | 24 ms |
| `toggle_on.wav` | `toggleOn` | "New Notification 040", universfield · 493469 | Começo em 131 ms (o original abre com silêncio), corte em 230 ms com saída de 70 ms; +5,1 dB | 230 ms |
| `toggle_off.wav` | `toggleOff` | O mesmo de `toggle_on.wav`, reamostrado a 0,84: mais grave, para desligar soar diferente de ligar | 274 ms |

O endereço de cada um é `https://pixabay.com/sound-effects/<nome>-<código>/`, com o nome e o código do arquivo baixado.

Tratamento comum aos quatro:
- o silêncio do começo sai, incluindo os ~25 ms que todo MP3 traz do codificador; o som começa em 2 ms, porque atraso no toque se sente;
- entrada de 2 ms e saída em cosseno, sem estalo;
- volume nivelado pelo ataque (o RMS dos primeiros 50 ms) com os sintetizados, a −8,85 dBFS, com o pico limitado em −0,4 dBFS;
- mono, 16 bits, 44,1 kHz, como os outros.

O tratamento foi feito decodificando os MP3 pela Web Audio API do navegador, porque esta máquina não tem ffmpeg. Para refazer, basta seguir os números da tabela.

### Sintetizados — os outros oito

Gerados por `tool/sound/build_sounds.py`, só com a biblioteca padrão do Python (`wave`, `math`, `random`, `struct`). A semente do gerador é fixa (2026), então rodar o script de novo reproduz os mesmos arquivos, byte a byte. O script não sobrescreve os gravados (lista `RECORDED`).

Tratamento comum: filtro passa-baixa em 5,2 kHz (tira a aspereza do agudo), fade de 4 ms nas pontas (sem estalo), saturação macia por tangente hiperbólica e pico normalizado em 0,95. Mono, 16 bits, 44,1 kHz.

| Arquivo | Token | Como foi feito | Duração |
|---|---|---|---|
| `open.wav` | `open` | Ruído filtrado em 2,4 kHz, decaindo devagar: papel deslizando | 180 ms |
| `receipt_in.wav` | `receiptIn` | Ruído de papel e uma madeira baixa, de leve | 130 ms |
| `saved.wav` | `saved` | Cinco grãos em sequência e uma batida macia em 392 Hz | 220 ms |
| `notice.wav` | `notice` | Duas madeiras graves, 233 Hz e 349 Hz, decaindo devagar | 260 ms |
| `success.wav` | `success` | Seno subindo de 520 a 880 Hz enquanto some: gota d'água | 200 ms |
| `achievement.wav` | `achievement` | Três madeiras subindo (523, 659, 784 Hz) e uma gota aguda por cima | 580 ms |
| `entry_saved.wav` | `entrySaved` | **Semente caindo na cuia**: estalo de grão com madeira em 560 Hz e dois quiques cada vez menores e mais próximos (85 ms e 140 ms depois, a 42% e 18% da força), sobre a ressonância grave da cuia em 330 Hz | 260 ms |
| `undone.wav` | `undone` | **Folha roçando**: ruído filtrado duas vezes em 2,6 kHz, com envelope que cresce e some (seno elevado a 1,5) e tremor de 23 Hz, terminando numa madeira de 294 Hz quase sem força | 210 ms |

Até 11/10/2026, `tap`, `toggle_on` e `toggle_off` também eram sintetizados (madeira em 720 Hz; duas madeiras, 520 e 780 Hz). O script ainda os calcula e descarta, porque o ruído é um só: tirá-los da lista mudaria o ruído de todos os que vêm depois.

Som novo só entra com a origem registrada nesta página: sintetizado aqui, gravado para o projeto, ou de banco com licença que permita usar dentro do app — com autor, código e licença.

## Fontes (`fonts/`)

| Arquivo | Família | Licença |
|---|---|---|
| `Fraunces.ttf` | Fraunces (variável) | SIL Open Font License 1.1 — texto em `OFL-Fraunces.txt` |
| `Geist.ttf` | Geist (variável) | SIL Open Font License 1.1 — texto em `OFL-Geist.txt` |

## Masterização para o celular (12/10/2026)

Pedido do dono: "os sons estão muito baixos, tenho que colocar no máximo para ouvir". O volume do app já nasce no máximo e os arquivos já batiam no pico; o problema era onde estava a energia. O alto-falante do celular quase não toca abaixo de 300–400 Hz, e o clique do botão tinha 99% da energia entre 150 e 300 Hz; a nota do aviso, 86%. O card e a tecla gastam a energia em 4 ms.

Todo arquivo desta pasta passa por `tool/sound/level_sounds.py`, depois do tratamento acima:
1. harmônicos dos graves: a parte abaixo de 400 Hz passa por uma saturação macia, e só os harmônicos que ela cria voltam ao som — o ouvido reconstrói a nota grave a partir deles;
2. corte do subgrave abaixo de 120 Hz;
3. saturação macia até o alvo da família, medido como o celular ouve (ponderação K da ITU-R BS.1770 e corte em 400 Hz, no trecho mais alto de 50 ms), com o pico em −0,9 dBFS.

| Família | Alvo | Antes → depois (LUFS no celular) |
|---|---|---|
| Botão, o toque macio | −8,5 | −15,6 → −8,7 (saturação até 2: mais que isso deixa o som feio) |
| Chaves | −7,5 | −10,5/−11,2 → −7,5 |
| Card | −10,0 | −15,1 → −10,0 |
| Tecla, que soa a cada letra | −11,5 | −22,0 → −11,5 |
| Confirmações | −6,5 | de −10,6 a −6,4 → −6,5 |
| Aviso, a nota grave e macia | −9,5 | −13,6 → −9,7 (mais saturação a deixaria áspera) |

O teste `sound_levels_test.dart` reprova o arquivo que voltar a sumir no alto-falante.
