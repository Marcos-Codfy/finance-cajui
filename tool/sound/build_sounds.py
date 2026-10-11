"""Sintetiza os sons de interface do Cajui.

Todos os sons nascem aqui, de seno e ruído filtrado, sem amostra de
terceiros: não há licença externa a cumprir e qualquer pessoa reproduz os
arquivos rodando o script. A semente do gerador é fixa, então a saída é
idêntica a cada execução.

O caráter segue docs/brand/motion-and-sound.md: curto, baixo, sem agudo
áspero, com timbre de material do Cerrado — madeira, semente, água, papel.
Não existe som de erro; o aviso é uma nota grave e macia.

Uso: python tool/sound/build_sounds.py
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44_100
# O pico do arquivo. Quem decide o quanto o som aparece é o volume do app
# (`SoundSettings.volume`), e não o arquivo: gravar baixo demais só tira
# alcance — no aparelho, com 0,22 o som sumia fora do volume máximo.
PEAK = 0.95
# Saturação macia antes do pico. Estes sons são quase só ataque: o pico manda
# no arquivo, e o corpo — que é o que o ouvido chama de volume — fica 15 dB
# abaixo. A tangente hiperbólica levanta esse corpo sem passar do pico e sem
# o estalo do corte reto. Acima de 2 começa a endurecer a madeira.
DRIVE = 1.6
OUT_DIR = Path(__file__).resolve().parents[2] / "packages" / "design_system" / "assets" / "sounds"


def silence(seconds: float) -> list[float]:
    return [0.0] * int(RATE * seconds)


def wood(freq: float, seconds: float, decay: float = 28.0) -> list[float]:
    """Batida em madeira oca: fundamental com um parcial inarmônico, decaindo rápido."""
    samples = []
    for n in range(int(RATE * seconds)):
        t = n / RATE
        body = math.sin(2 * math.pi * freq * t)
        overtone = 0.35 * math.sin(2 * math.pi * freq * 2.76 * t)
        samples.append((body + overtone) * math.exp(-decay * t))
    return samples


def grain(rng: random.Random, seconds: float, decay: float, cutoff: float) -> list[float]:
    """Ruído curto e abafado: semente rolando, papel, palha."""
    raw = [rng.uniform(-1, 1) * math.exp(-decay * n / RATE) for n in range(int(RATE * seconds))]
    return low_pass(raw, cutoff)


def drop(start: float, end: float, seconds: float) -> list[float]:
    """Gota d'água: seno que sobe de tom enquanto some."""
    samples, phase = [], 0.0
    total = int(RATE * seconds)
    for n in range(total):
        progress = n / total
        freq = start + (end - start) * progress**0.5
        phase += 2 * math.pi * freq / RATE
        samples.append(math.sin(phase) * math.exp(-9 * progress))
    return samples


def seed_drop(rng: random.Random) -> list[float]:
    """Semente caindo na cuia: um estalo de grão com a madeira respondendo, e
    dois quiques cada vez menores e mais próximos, como a física pede."""
    bounces = [(0.0, 1.0, 560), (0.085, 0.42, 600), (0.14, 0.18, 640)]
    hits = [
        at(offset, gain(mix(grain(rng, 0.018, 260, 5600), gain(wood(freq, 0.12, 34), 0.7)), level))
        for offset, level, freq in bounces
    ]
    return mix(*hits, gain(wood(330, 0.22, 16), 0.3))


def rustle(rng: random.Random, seconds: float, cutoff: float, flutter: float) -> list[float]:
    """Folha roçando: ruído que cresce e some, com o tremor da nervura.

    O envelope sobe e desce, em vez de só decair como o grão: é o que faz o
    ouvido ler um gesto que vai e volta — o desfazer —, e não uma batida."""
    total = int(RATE * seconds)
    raw = []
    for n in range(total):
        swell = math.sin(math.pi * n / total) ** 1.5
        tremor = 0.75 + 0.25 * math.sin(2 * math.pi * flutter * n / RATE)
        raw.append(rng.uniform(-1, 1) * swell * tremor)
    return low_pass(low_pass(raw, cutoff), cutoff)


def low_pass(samples: list[float], cutoff: float) -> list[float]:
    """Passa-baixa de um polo: é o que tira a aspereza do agudo."""
    alpha = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    out, last = [], 0.0
    for sample in samples:
        last += alpha * (sample - last)
        out.append(last)
    return out


def mix(*layers: list[float]) -> list[float]:
    length = max(len(layer) for layer in layers)
    return [sum(layer[n] for layer in layers if n < len(layer)) for n in range(length)]


def at(offset: float, samples: list[float]) -> list[float]:
    return silence(offset) + samples


def gain(samples: list[float], amount: float) -> list[float]:
    return [sample * amount for sample in samples]


def finish(samples: list[float]) -> list[float]:
    """Filtra, aplica fade nas pontas e normaliza para o pico da marca."""
    smooth = low_pass(samples, 5200)
    fade = int(RATE * 0.004)
    for n in range(min(fade, len(smooth))):
        smooth[n] *= n / fade
        smooth[-1 - n] *= n / fade
    loudest = max(abs(sample) for sample in smooth) or 1.0
    warmth = math.tanh(DRIVE)
    return [
        math.tanh(DRIVE * sample / loudest) / warmth * PEAK for sample in smooth
    ]


def build(rng: random.Random) -> dict[str, list[float]]:
    seeds = mix(*[at(0.018 * i + rng.uniform(0, 0.01), gain(grain(rng, 0.03, 160, 6500), 0.7)) for i in range(5)])
    return {
        "tap": mix(wood(720, 0.07, 60), gain(grain(rng, 0.02, 300, 4000), 0.25)),
        "toggle_on": mix(wood(520, 0.09, 42), at(0.055, wood(780, 0.10, 40))),
        "toggle_off": mix(wood(780, 0.09, 42), at(0.055, wood(520, 0.10, 40))),
        "open": gain(grain(rng, 0.18, 14, 2400), 1.0),
        "swipe": gain(grain(rng, 0.14, 22, 3200), 0.8),
        "receipt_in": mix(grain(rng, 0.10, 38, 5200), at(0.05, gain(wood(430, 0.08, 46), 0.4))),
        "saved": mix(seeds, at(0.06, gain(wood(392, 0.16, 20), 0.8))),
        "notice": mix(wood(233, 0.26, 12), gain(wood(349, 0.20, 16), 0.3)),
        "success": mix(drop(520, 880, 0.20), at(0.02, gain(wood(587, 0.12, 30), 0.35))),
        "achievement": mix(
            wood(523, 0.30, 9),
            at(0.11, wood(659, 0.30, 9)),
            at(0.22, wood(784, 0.36, 8)),
            at(0.22, gain(drop(1046, 1568, 0.30), 0.18)),
        ),
        # Os dois últimos ficam no fim de propósito: o gerador é um só, e som
        # novo no meio da lista mudaria o ruído de todos os que vêm depois.
        "entry_saved": seed_drop(rng),
        "undone": mix(rustle(rng, 0.20, 2600, 23), at(0.13, gain(wood(294, 0.08, 45), 0.18))),
    }


def write_wav(path: Path, samples: list[float]) -> None:
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
    with wave.open(str(path), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(frames)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, samples in build(random.Random(2026)).items():
        ready = finish(samples)
        write_wav(OUT_DIR / f"{name}.wav", ready)
        print(f"ok  {name}.wav  {len(ready) / RATE * 1000:.0f} ms")


if __name__ == "__main__":
    main()
