"""Nenhuma assinatura de assistente de IA no repositório.

É regra do dono do produto desde o primeiro commit: o Cajui é peça de
portfólio, e um rastro de assistente em mensagem de commit ou em comentário
muda o que o repositório diz sobre quem o escreveu.

A ferramenta que gera commits **oferece** essas linhas por padrão, e basta um
descuido para uma entrar. Aqui a regra deixa de depender de memória: procura
nas mensagens de commit, no conteúdo dos arquivos e nos nomes de autor.

Uso: python tool/quality/check_authorship.py
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# As formas que a assinatura costuma tomar. São literais, e não adivinhação:
# a palavra "Claude" no meio de um texto sobre outra coisa não é assinatura —
# mas como co-autor, como gerador ou em emoji de robô, é.
MARKS = [
    re.compile(r"(?i)co-authored-by:\s*claude"),
    re.compile(r"(?i)co-authored-by:.*\banthropic\b"),
    re.compile(r"(?i)generated with\s*\[?\s*claude"),
    re.compile(r"(?i)\bcreated by claude\b"),
    re.compile(r"🤖\s*generated", re.IGNORECASE),
    re.compile(r"(?i)noreply@anthropic\.com"),
]

SKIP = re.compile(
    r"(^|/)(\.git|build|\.dart_tool|node_modules)/"
    r"|\.(png|jpg|jpeg|webp|gif|pdf|ttf|otf|wav|ogg|mp3|apk|jar|zip|lock)$"
    r"|tool/quality/check_authorship\.py$",
)


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    ).stdout


def in_commits() -> list[str]:
    log = git("log", "--all", "--format=%H%x1f%an <%ae>%x1f%B%x1e")
    found = []
    for entry in log.split("\x1e"):
        parts = entry.strip().split("\x1f")
        if len(parts) != 3:
            continue
        sha, author, body = parts
        for mark in MARKS:
            if mark.search(body) or mark.search(author):
                found.append(f"commit {sha[:8]}: assinatura na mensagem ou no autor")
                break
    return found


def in_files() -> list[str]:
    found = []
    for name in git("ls-files").splitlines():
        if not name or SKIP.search(name):
            continue
        file = ROOT / name
        if not file.is_file():
            continue
        text = file.read_text(encoding="utf-8", errors="replace")
        for number, line in enumerate(text.splitlines(), start=1):
            if any(mark.search(line) for mark in MARKS):
                found.append(f"{name}:{number}")
                break
    return found


def main() -> None:
    found = in_commits() + in_files()
    if not found:
        print("ok  nenhuma assinatura de IA no repositório")
        return
    print("ASSINATURA DE IA ENCONTRADA:", file=sys.stderr)
    for line in found:
        print(f"  {line}", file=sys.stderr)
    print(
        "\nTire a linha. Se ela já está num commit, reescreva a mensagem "
        "antes de abrir o PR.",
        file=sys.stderr,
    )
    raise SystemExit(1)


if __name__ == "__main__":
    main()
