"""Nivela o volume dos sons de interface do Cajui.

Pedido do dono em 12/10/2026: "os sons estão muito baixos, tenho que colocar
no máximo para ouvir". O volume do app já nasce no máximo
(`SoundSettings.volume`), então quem manda é o arquivo. Medidos com a
ponderação K da ITU-R BS.1770 (a que aproxima o ouvido), em janela curta,
os sons de toque gravados estavam de 3 a 15 dB abaixo dos sintetizados: a
tecla a −21,9 LUFS, o card a −15,1.

Cada som sobe até o alvo da família com ganho e um limitador de pico com
antecipação: o ganho é reduzido 1,5 ms antes de cada pico e volta devagar
(40 ms), então nada passa do teto e nada é cortado seco. O corpo do som,
que é o que o ouvido chama de volume, sobe; o ataque fica no teto.

Roda depois de `build_sounds.py`, que escreve os sintetizados no pico, e é
idempotente: som que já está a meio decibel do alvo não é tocado.

Uso: python tool/sound/level_sounds.py
"""

from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

SOUNDS = Path(__file__).resolve().parents[2] / "packages" / "design_system" / "assets" / "sounds"

# O teto do pico, abaixo de 0 dBFS: a reamostragem do aparelho cria picos
# entre as amostras, e um arquivo colado no teto estala nela.
CEILING = 10 ** (-0.9 / 20)

# O alvo de cada som, em LUFS de janela curta. As confirmações ficam um
# pouco à frente dos toques, que se repetem o dia inteiro; a tecla, que soa
# a cada letra, fica atrás dos outros toques.
CONFIRMATION = -4.5
TOUCH = -5.5
TARGETS = {
    "tap": TOUCH,
    "card": TOUCH,
    "toggle_on": TOUCH,
    "toggle_off": TOUCH,
    "key": -8.5,
    "open": CONFIRMATION,
    "receipt_in": CONFIRMATION,
    "saved": CONFIRMATION,
    "notice": CONFIRMATION,
    "success": CONFIRMATION,
    "achievement": CONFIRMATION,
    "entry_saved": CONFIRMATION,
    "undone": CONFIRMATION,
}

LOOKAHEAD = 0.0015
RELEASE = 0.040
WINDOW = 0.050
TOLERANCE = 0.5


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


def loudness(samples: np.ndarray, rate: int) -> float:
    """O trecho mais alto do som, em LUFS, numa janela de 50 ms."""
    weighted = k_weighted(samples, rate)
    size = min(len(weighted), int(rate * WINDOW))
    power = np.convolve(weighted * weighted, np.ones(size) / size, mode="valid")
    return -0.691 + 10 * math.log10(power.max())


def limited(samples: np.ndarray, rate: int, gain_db: float) -> np.ndarray:
    """[samples] com o ganho, e nenhum pico acima do teto.

    O ganho de cada amostra é o menor exigido nos próximos 1,5 ms, alisado
    na mesma janela: a média de mínimos que cobrem a amostra nunca passa do
    que ela exige, e a descida vira rampa, sem estalo. A volta é lenta, para
    o ganho não oscilar dentro de um ciclo do som.
    """
    loud = samples * 10 ** (gain_db / 20)
    needed = np.minimum(1.0, CEILING / np.maximum(np.abs(loud), 1e-12))
    size = max(1, int(rate * LOOKAHEAD))
    padded = np.concatenate([needed, np.ones(size)])
    ahead = np.array([padded[n:n + size].min() for n in range(len(needed))])
    ramp = np.convolve(np.concatenate([np.ones(size - 1), ahead]), np.ones(size) / size, mode="valid")
    back = 1 - math.exp(-1 / (RELEASE * rate))
    gain = np.empty_like(ramp)
    level = 1.0
    for n, wanted in enumerate(ramp):
        level = wanted if wanted < level else level + (wanted - level) * back
        gain[n] = level
    return np.clip(loud * gain, -CEILING, CEILING)


def leveled(samples: np.ndarray, rate: int, target: float) -> np.ndarray:
    """O ganho que leva o som ao alvo, achado por bissecção: o limitador
    come parte do ganho, e a conta direta erraria para baixo."""
    low, high = 0.0, 30.0
    for _ in range(24):
        middle = (low + high) / 2
        if loudness(limited(samples, rate, middle), rate) < target:
            low = middle
        else:
            high = middle
    return limited(samples, rate, (low + high) / 2)


def main() -> None:
    for name, target in TARGETS.items():
        path = SOUNDS / f"{name}.wav"
        samples, rate = read(path)
        before = loudness(samples, rate)
        if abs(before - target) <= TOLERANCE:
            print(f"ok  {name}.wav já está em {before:.1f} LUFS")
            continue
        ready = leveled(samples, rate, target)
        write(path, ready, rate)
        peak = 20 * math.log10(np.abs(ready).max())
        print(f"ok  {name}.wav  {before:.1f} → {loudness(ready, rate):.1f} LUFS, pico {peak:.1f} dBFS")


if __name__ == "__main__":
    main()
