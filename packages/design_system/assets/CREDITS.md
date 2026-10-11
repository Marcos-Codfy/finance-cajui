# Origem dos arquivos do design system

Tudo o que o pacote empacota tem a origem registrada aqui antes de entrar no repositório. Arquivo sem linha nesta página não entra.

## Sons (`sounds/`)

Todos os doze sons são **sintetizados pelo próprio projeto**, sem nenhuma amostra de terceiros: não há licença externa a cumprir. Quem gera é `tool/sound/build_sounds.py`, só com a biblioteca padrão do Python (`wave`, `math`, `random`, `struct`). A semente do gerador é fixa (2026), então rodar o script de novo reproduz os mesmos arquivos, byte a byte.

Tratamento comum a todos: filtro passa-baixa em 5,2 kHz (tira a aspereza do agudo), fade de 4 ms nas pontas (sem estalo), saturação macia por tangente hiperbólica e pico normalizado em 0,95. Mono, 16 bits, 44,1 kHz.

| Arquivo | Token | Como foi feito | Duração |
|---|---|---|---|
| `tap.wav` | `CajuiSound.tap` | Batida de madeira em 720 Hz com um sopro curto de grão | 70 ms |
| `toggle_on.wav` | `toggleOn` | Duas batidas de madeira, 520 Hz e depois 780 Hz | 155 ms |
| `toggle_off.wav` | `toggleOff` | As mesmas duas, em ordem inversa | 155 ms |
| `open.wav` | `open` | Ruído filtrado em 2,4 kHz, decaindo devagar: papel deslizando | 180 ms |
| `swipe.wav` | `swipe` | Ruído filtrado em 3,2 kHz, mais curto: palha | 140 ms |
| `receipt_in.wav` | `receiptIn` | Ruído de papel e uma madeira baixa, de leve | 130 ms |
| `saved.wav` | `saved` | Cinco grãos em sequência e uma batida macia em 392 Hz | 220 ms |
| `notice.wav` | `notice` | Duas madeiras graves, 233 Hz e 349 Hz, decaindo devagar | 260 ms |
| `success.wav` | `success` | Seno subindo de 520 a 880 Hz enquanto some: gota d'água | 200 ms |
| `achievement.wav` | `achievement` | Três madeiras subindo (523, 659, 784 Hz) e uma gota aguda por cima | 580 ms |
| `entry_saved.wav` | `entrySaved` | **Semente caindo na cuia**: estalo de grão com madeira em 560 Hz e dois quiques cada vez menores e mais próximos (85 ms e 140 ms depois, a 42% e 18% da força), sobre a ressonância grave da cuia em 330 Hz | 260 ms |
| `undone.wav` | `undone` | **Folha roçando**: ruído filtrado duas vezes em 2,6 kHz, com envelope que cresce e some (seno elevado a 1,5) e tremor de 23 Hz, terminando numa madeira de 294 Hz quase sem força | 210 ms |

Os dois últimos foram acrescentados no fim da lista do script de propósito: o gerador de ruído é um só, e um som novo no meio mudaria o ruído de todos os que vêm depois. Depois de gerar, os dez arquivos antigos continuaram idênticos.

Se um som gravado vier a substituir um sintetizado, só entra material em domínio público (CC0) ou gravado para o projeto, registrado nesta tabela com autor, endereço de origem e licença.

## Fontes (`fonts/`)

| Arquivo | Família | Licença |
|---|---|---|
| `Fraunces.ttf` | Fraunces (variável) | SIL Open Font License 1.1 — texto em `OFL-Fraunces.txt` |
| `Geist.ttf` | Geist (variável) | SIL Open Font License 1.1 — texto em `OFL-Geist.txt` |
