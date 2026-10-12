"""Masteriza os sons de interface do Cajui para o alto-falante do celular.

Pedido do dono em 12/10/2026: "os sons estão muito baixos, tenho que colocar
no máximo para ouvir". O volume do app já nasce no máximo
(`SoundSettings.volume`), e os arquivos já batiam no pico. O problema era
onde a energia estava: o alto-falante de um celular quase não toca abaixo de
300–400 Hz, e o clique do botão tinha 99% da energia entre 150 e 300 Hz; o
aviso, 86%. O card e a tecla gastam a energia em 4 ms. No fone soavam bem;
no celular, sumiam.

Cada som passa por três etapas:
1. **Harmônicos dos graves.** A parte abaixo de 400 Hz passa por uma
   saturação macia, e só os harmônicos que ela cria (acima de 400 Hz) voltam
   para o som. O ouvido reconstrói a nota grave a partir deles — é o mesmo
   truque dos fones pequenos —, e o timbre continua o mesmo.
2. **Corte do subgrave** abaixo de 120 Hz, que só gastava margem de pico.
3. **Nível.** Uma saturação macia (tangente hiperbólica), a mesma que o
   `build_sounds.py` usa nos sintetizados: engorda o corpo do som sem passar
   do teto e sem o estalo do corte reto. A força é achada por bissecção até o
   som chegar ao alvo da família, com um limite por família para o toque
   não ficar áspero. O alvo é medido como o celular ouve: ponderação K
   (ITU-R BS.1770) e um corte em 400 Hz, no trecho mais alto de 50 ms.

Roda depois de `build_sounds.py`, que escreve os sintetizados, sobre os
arquivos de `assets/sounds`. Partir sempre do som de origem: rodar duas
vezes sobre o mesmo arquivo empilharia os harmônicos. Por isso o script lê
de `--source` (os arquivos antes da masterização) e escreve em
`assets/sounds`.

Uso: python tool/sound/level_sounds.py --source <pasta com os sons de origem>
"""

from __future__ import annotations

import argparse
import math
import wave
from pathlib import Path

import numpy as np

SOUNDS = Path(__file__).resolve().parents[2] / "packages" / "design_system" / "assets" / "sounds"

# O teto do pico, abaixo de 0 dBFS: a reamostragem do aparelho cria picos
# entre as amostras, e um arquivo colado no teto estala nela.
CEILING = 10 ** (-0.9 / 20)

# O alvo de cada som, em LUFS "de celular" (ver `phone_loudness`), e a
# saturação máxima. Os sintetizados já estavam perto do máximo limpo e
# saturam pouco; os toques gravados — graves ou de 4 ms — precisam de mais.
# A tecla, que soa a cada letra, fica atrás dos outros toques.
CONFIRMATION = (-6.5, 3.0)
TOUCH = (-7.5, 5.0)
TARGETS = {
    "tap": TOUCH,
    "toggle_on": TOUCH,
    "toggle_off": TOUCH,
    "card": (-10.0, 5.0),
    "key": (-11.5, 5.0),
    "open": CONFIRMATION,
    "receipt_in": CONFIRMATION,
    "saved": CONFIRMATION,
    # O aviso é a nota grave e macia: no celular ele é quase só harmônico,
    # e saturar mais o deixaria áspero. Fica um pouco atrás das outras.
    "notice": (-9.5, 5.0),
    "success": CONFIRMATION,
    "achievement": CONFIRMATION,
    "entry_saved": CONFIRMATION,
    "undone": CONFIRMATION,
}

SPEAKER_LOW = 400.0
SUB_CUT = 120.0
HARMONICS = 0.9
WINDOW = 0.050


def read(path: Path) -> tuple[np.ndarray, int]:
    with wave.open(str(path)) as file:
        rate = file.getframerate()
        frames = file.readframes(file.getnframes())
    return np.frombuffer(frames, dtype="<i2").astype(np.float64) / 32768, rate


def write(path: Path, samples: np.ndarray, rate: int) -> None:
    pcm = np.round(np.clip(samples, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(rate)
        file.writeframes(pcm.tobytes())


def biquad(samples: np.ndarray, b: list[float], a: list[float]) -> np.ndarray:
    out = np.zeros_like(samples)
    x1 = x2 = y1 = y2 = 0.0
    for n, x in enumerate(samples):
        y = b[0] * x + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2
        x2, x1, y2, y1 = x1, x, y1, y
        out[n] = y
    return out


def butterworth(samples: np.ndarray, rate: int, cutoff: float, kind: str) -> np.ndarray:
    """Filtro de segunda ordem (RBJ), passa-baixa ou passa-alta."""
    w0 = 2 * math.pi * cutoff / rate
    alpha = math.sin(w0) / math.sqrt(2)
    cos = math.cos(w0)
    a0 = 1 + alpha
    a = [1, -2 * cos / a0, (1 - alpha) / a0]
    if kind == "low":
        b = [(1 - cos) / 2 / a0, (1 - cos) / a0, (1 - cos) / 2 / a0]
    else:
        b = [(1 + cos) / 2 / a0, -(1 + cos) / a0, (1 + cos) / 2 / a0]
    return biquad(samples, b, a)


def k_weighted(samples: np.ndarray, rate: int) -> np.ndarray:
    """Os dois filtros da ponderação K (ITU-R BS.1770-4), para qualquer taxa."""
    f0, gain_db, q = 1681.974450955533, 3.999843853973347, 0.7071752369554196
    k = math.tan(math.pi * f0 / rate)
    vh = 10 ** (gain_db / 20)
    vb = vh ** 0.4996667741545416
    a0 = 1 + k / q + k * k
    shelf = biquad(
        samples,
        [(vh + vb * k / q + k * k) / a0, 2 * (k * k - vh) / a0, (vh - vb * k / q + k * k) / a0],
        [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0],
    )
    f0, q = 38.13547087602444, 0.5003270373238773
    k = math.tan(math.pi * f0 / rate)
    a0 = 1 + k / q + k * k
    return biquad(shelf, [1, -2, 1], [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0])


def phone_loudness(samples: np.ndarray, rate: int) -> float:
    """O trecho mais alto de 50 ms, em LUFS, como o alto-falante o toca:
    ponderação K e nada abaixo de 400 Hz."""
    heard = k_weighted(butterworth(samples, rate, SPEAKER_LOW, "high"), rate)
    size = min(len(heard), int(rate * WINDOW))
    power = np.convolve(heard * heard, np.ones(size) / size, mode="valid")
    return -0.691 + 10 * math.log10(max(power.max(), 1e-12))


def with_harmonics(samples: np.ndarray, rate: int) -> np.ndarray:
    """[samples] com os harmônicos dos graves, e sem o subgrave."""
    low = butterworth(samples, rate, SPEAKER_LOW, "low")
    level = np.abs(low).max()
    if level > 1e-4:
        saturated = np.tanh(4 * low / level) * level
        samples = samples + HARMONICS * butterworth(saturated, rate, SPEAKER_LOW, "high")
    return butterworth(samples, rate, SUB_CUT, "high")


def saturated(samples: np.ndarray, drive: float, level: float = 1.0) -> np.ndarray:
    """[samples] pela tangente hiperbólica, com o pico em [level] do teto."""
    peak = np.abs(samples).max() or 1.0
    return np.tanh(drive * samples / peak) / math.tanh(drive) * CEILING * level


def mastered(samples: np.ndarray, rate: int, target: float, most: float) -> np.ndarray:
    """O som pronto: harmônicos, corte e a saturação que o leva ao alvo.

    Som que nem com a saturação máxima chega fica nela; som que já passa do
    alvo quase sem saturar desce de nível, em vez de subir.
    """
    shaped = with_harmonics(samples, rate)
    if phone_loudness(saturated(shaped, 0.5), rate) >= target:
        return saturated(shaped, 0.5, _bisect(lambda v: saturated(shaped, 0.5, v), rate, target, 0.1, 1.0))
    return saturated(shaped, _bisect(lambda d: saturated(shaped, d), rate, target, 0.5, most))


def _bisect(make, rate: int, target: float, low: float, high: float) -> float:
    """O valor entre [low] e [high] que leva o som ao alvo; a altura cresce
    com o valor."""
    if phone_loudness(make(high), rate) <= target:
        return high
    for _ in range(20):
        middle = (low + high) / 2
        if phone_loudness(make(middle), rate) < target:
            low = middle
        else:
            high = middle
    return (low + high) / 2


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--source", type=Path, required=True)
    source = parser.parse_args().source
    for name, (target, most) in TARGETS.items():
        samples, rate = read(source / f"{name}.wav")
        before = phone_loudness(samples, rate)
        ready = mastered(samples, rate, target, most)
        write(SOUNDS / f"{name}.wav", ready, rate)
        peak = 20 * math.log10(np.abs(ready).max())
        after = phone_loudness(ready, rate)
        print(f"ok  {name}.wav  {before:6.1f} → {after:6.1f} LUFS no celular (alvo {target}), pico {peak:.1f} dBFS")


if __name__ == "__main__":
    main()
