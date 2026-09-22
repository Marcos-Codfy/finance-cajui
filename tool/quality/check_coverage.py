"""Confere se a cobertura de testes de um pacote continua de pé.

O piso de cada pacote é **um pouco abaixo do que ele tem hoje**, de
propósito: o portão existe para avisar quando um passo derruba a cobertura,
e não para obrigar quem escreve um `if` a caçar mais um teste. Cobertura
alta demais como meta vira teste que existe só para a barra subir.

Cada piso está justificado em `docs/spec/quality-gates.md`.

Uso: python tool/quality/check_coverage.py <pacote> <piso em %>
Espera o `coverage/lcov.info` do pacote já gerado.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def measured(lcov: Path) -> tuple[int, int]:
    total = covered = 0
    for line in lcov.read_text(encoding="utf-8").splitlines():
        if line.startswith("LF:"):
            total += int(line[3:])
        elif line.startswith("LH:"):
            covered += int(line[3:])
    return covered, total


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("uso: check_coverage.py <pacote> <piso em %>")
    package, floor = sys.argv[1], float(sys.argv[2])
    lcov = ROOT / package / "coverage" / "lcov.info"
    if not lcov.is_file():
        raise SystemExit(f"não achei {lcov}: os testes rodaram com --coverage?")

    covered, total = measured(lcov)
    if total == 0:
        raise SystemExit(f"{package}: nenhuma linha medida")
    percent = 100 * covered / total
    verdict = "ok " if percent >= floor else "ABAIXO DO PISO"
    print(
        f"{verdict} {package}: {percent:.1f}% "
        f"({covered}/{total} linhas) · piso {floor:.0f}%"
    )
    if percent < floor:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
