"""Gera app/lib/src/core/errors/error_texts.g.dart a partir do catálogo.

O texto que a pessoa lê e as saídas de cada erro nascem de
docs/spec/error-catalog.md, para que trocar uma redação seja editar um lugar
só (ADR-015). Um teste do app confere os dois a cada commit.

Uso, da raiz: python tool/contract/build_error_texts.py
"""

import re
import shutil
import subprocess
from pathlib import Path

CATALOG = Path("docs/spec/error-catalog.md")
OUTPUT = Path("app/lib/src/core/errors/error_texts.g.dart")

ROW = re.compile(
    r"^\| `E-([A-Z]+)-(\d\d)`[^|]*\|[^|]+\|[^|]+\|([^|]+)\|([^|]+)\|"
)


def dart_string(text):
    """O literal Dart de `text`, do jeito que o lint do projeto aceita."""
    quote = '"' if "'" in text else "'"
    if quote == '"':
        text = text.replace('"', '\\"')
    raw = "r" if ("$" in text or "\\" in text) and quote == "'" else ""
    return f"{raw}{quote}{text}{quote}"


def actions_of(cell):
    """As saídas da coluna, sem o que não é botão: "— (campo)", "(aguarda…)"."""
    cell = cell.strip()
    if cell.startswith(("—", "(")):
        return []
    # "— ou —" separa as saídas de duas telas (captura e conversa): cada tela
    # oferece as que fazem sentido nela.
    return [part.strip() for part in re.split(r"·|— ou —", cell)]


def rows():
    for line in CATALOG.read_text(encoding="utf-8").splitlines():
        match = ROW.match(line)
        if match:
            area, number, text, actions = match.groups()
            yield area.lower() + number, text.strip(), actions_of(actions)


def main():
    cases = []
    for name, text, actions in rows():
        listed = ", ".join(dart_string(action) for action in actions)
        tail = f", actions: [{listed}]" if actions else ""
        cases.append(
            f"    ErrorCode.{name} => const ErrorText({dart_string(text)}{tail}),"
        )
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        HEADER + "\n".join(cases) + FOOTER, encoding="utf-8", newline="\n"
    )
    dart = shutil.which("dart")
    if dart:
        subprocess.run([dart, "format", str(OUTPUT)], check=True)
    print(len(cases), "textos")


HEADER = """// Gerado por tool/contract/build_error_texts.py a partir de
// docs/spec/error-catalog.md. Não edite à mão: mude o catálogo e gere de novo.
// ignore_for_file: lines_longer_than_80_chars

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_text.dart';

/// O texto e as saídas de cada erro, como estão no catálogo (ADR-015).
///
/// O `switch` é exaustivo: código novo no contrato sem texto aqui não compila.
abstract final class ErrorTexts {
  /// O texto e as saídas de [code].
  static ErrorText of(ErrorCode code) => switch (code) {
"""

FOOTER = """
  };
}
"""

if __name__ == "__main__":
    main()
