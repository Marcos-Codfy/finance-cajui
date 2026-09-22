"""Procura segredo de verdade antes de ele virar commit.

O Cajui vai a público na Fase 9 com o histórico inteiro. Segredo commitado
não se apaga com um commit novo: ele fica no histórico, e a única saída é
reescrever tudo e trocar a chave. Por isso a barreira é **antes** do commit.

O que é procurado: chave de API (DeepSeek, OpenAI, GitHub, AWS, Google),
chave privada em PEM, senha ou token atribuídos em código, e arquivo que
nunca deveria ser versionado (`.env`, `.pem`, `.jks`).

O que **não** é procurado: nada que dependa de adivinhação. Um número de
16 dígitos pode ser um cartão ou um identificador de nota fiscal; acusar
todos ensinaria a ignorar o aviso.

Uso:
  python tool/security/scan_secrets.py            # o que está no índice
  python tool/security/scan_secrets.py --all      # a árvore inteira
  python tool/security/scan_secrets.py --history  # todo o histórico do git
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Cada regra é (nome, expressão). O comprimento mínimo é o que separa uma
# chave de verdade de um exemplo de teste: "sk-123" não é chave de ninguém.
RULES: list[tuple[str, re.Pattern[str]]] = [
    ("chave da DeepSeek ou da OpenAI", re.compile(r"\bsk-[A-Za-z0-9_-]{24,}")),
    ("token do GitHub", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}")),
    ("chave da AWS", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("chave do Google", re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("chave privada em PEM", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    (
        "senha ou token no código",
        re.compile(
            r"(?i)\b(?:api[_-]?key|secret|token|senha|password|passwd)\b"
            r"\s*[:=]\s*['\"][^'\"\n]{16,}['\"]"
        ),
    ),
]

# Arquivo que não entra no repositório, aconteça o que acontecer.
FORBIDDEN = re.compile(
    r"(^|/)\.env(\.|$)|\.(pem|key|jks|keystore|p12|pfx)$|(^|/)secrets/",
)

# O que o verificador não lê: binário, dependência e o que ele mesmo é.
SKIP = re.compile(
    r"(^|/)(\.git|build|\.dart_tool|node_modules)/"
    r"|\.(png|jpg|jpeg|webp|gif|pdf|ttf|otf|wav|ogg|mp3|apk|jar|zip|lock)$"
    r"|tool/security/scan_secrets\.py$",
)

# Linha marcada assim é exemplo, e o verificador respeita — com o motivo à
# vista de quem revisa o PR.
ALLOW = re.compile(r"scan-secrets:\s*exemplo")


def _git(*args: str) -> str:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    ).stdout


def staged_files() -> list[str]:
    names = _git("diff", "--cached", "--name-only", "--diff-filter=ACM")
    return [name for name in names.splitlines() if name]


def tracked_files() -> list[str]:
    return [name for name in _git("ls-files").splitlines() if name]


def content_of(path: str, *, staged: bool) -> str:
    if staged:
        return _git("show", f":{path}")
    file = ROOT / path
    if not file.is_file():
        return ""
    return file.read_text(encoding="utf-8", errors="replace")


def findings_in(path: str, text: str) -> list[str]:
    found = []
    if FORBIDDEN.search(path):
        found.append(f"{path}: arquivo que nunca deve ser versionado")
    for number, line in enumerate(text.splitlines(), start=1):
        if ALLOW.search(line):
            continue
        for name, rule in RULES:
            if rule.search(line):
                found.append(f"{path}:{number}: {name}")
    return found


def scan(paths: list[str], *, staged: bool) -> list[str]:
    found = []
    for path in paths:
        if SKIP.search(path):
            continue
        found.extend(findings_in(path, content_of(path, staged=staged)))
    return found


def scan_history() -> list[str]:
    """Todo blob que já existiu no histórico. É o que a Fase 9 precisa saber
    antes de o repositório virar público."""
    found = []
    listing = _git("rev-list", "--objects", "--all").splitlines()
    for entry in listing:
        parts = entry.split(" ", 1)
        if len(parts) != 2:
            continue
        sha, path = parts
        if SKIP.search(path) or not path:
            continue
        found.extend(findings_in(f"{path} (histórico)", _git("cat-file", "-p", sha)))
    return found


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "--history":
        found = scan_history()
        where = "no histórico"
    elif mode == "--all":
        found = scan(tracked_files(), staged=False)
        where = "na árvore"
    else:
        found = scan(staged_files(), staged=True)
        where = "no que vai ser commitado"
    if not found:
        print(f"ok  nenhum segredo {where}")
        return
    print(f"SEGREDO ENCONTRADO {where}:", file=sys.stderr)
    for line in found:
        print(f"  {line}", file=sys.stderr)
    print(
        "\nNada foi commitado. Tire o segredo do arquivo, ponha-o numa "
        "variável de ambiente e, se ele já foi usado, troque a chave.",
        file=sys.stderr,
    )
    raise SystemExit(1)


if __name__ == "__main__":
    main()
