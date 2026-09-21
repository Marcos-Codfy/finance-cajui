"""Gera packages/api_contract/lib/src/error_code.dart a partir do catálogo.

O enum nasce de docs/spec/error-catalog.md para que documento e código não
possam divergir (ADR-015). Um teste do pacote confere os dois a cada commit.

Uso, da raiz: python tool/contract/build_error_codes.py
"""

import re
from pathlib import Path

CATALOG = Path("docs/spec/error-catalog.md")
OUTPUT = Path("packages/api_contract/lib/src/error_code.dart")

FIELD_ERRORS = {"E-ENTRY-02", "E-ENTRY-03", "E-CARD-01", "E-BUDG-01", "E-DEBT-01"}
CLASS_BY_AREA = {
    "ENTRY": "rule", "VOUCHER": "rule", "CARD": "rule", "BUDG": "rule",
    "DEBT": "rule", "CAPT": "capture", "NET": "network", "SYNC": "sync",
    "AI": "ai", "AUTH": "security", "RATE": "limit", "DATA": "data",
    "STORAGE": "device", "REQ": "server", "SRV": "server", "WEB": "app",
    "APP": "app",
}


def rows():
    pattern = re.compile(r"^\| `(E-([A-Z]+)-(\d\d))`[^|]*\| ([^|]+)\| ([^|]+)\|")
    for line in CATALOG.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if match:
            code, area, number, when, origin = match.groups()
            status = re.search(r"api (\d{3})", origin)
            yield code, area, number, when.strip(), status and status.group(1)


def main():
    entries = []
    for code, area, number, when, status in rows():
        kind = "validation" if code in FIELD_ERRORS else CLASS_BY_AREA[area]
        name = area.lower() + number
        entries.append(
            f"  /// {when}.\n"
            f"  {name}('{code}', ErrorClass.{kind}, {status or 'null'}),"
        )
    body = "\n\n".join(entries)[:-1] + ";"
    OUTPUT.write_text(HEADER + body + FOOTER, encoding="utf-8", newline="\n")
    print(len(entries), "códigos")


HEADER = """// Gerado por tool/contract/build_error_codes.py a partir de
// docs/spec/error-catalog.md. Não edite à mão: mude o catálogo e gere de novo.

import 'package:api_contract/src/error_class.dart';

/// Os códigos de erro do Cajui: um valor por linha do catálogo.
///
/// App e servidor compartilham este enum, então código que não está no
/// catálogo **não existe**. O texto de cada erro não mora aqui nem na API: o
/// app monta a frase a partir do código e dos valores (ADR-015).
enum ErrorCode {
"""

FOOTER = """

  new(this.code, this.errorClass, this.httpStatus);

  /// O código como aparece no catálogo e na API: `E-VOUCHER-01`.
  final String code;

  /// A classe do erro, que decide onde e como ele aparece.
  final ErrorClass errorClass;

  /// O status HTTP com que a API devolve este erro; nulo quando o erro só
  /// nasce no aparelho.
  final int? httpStatus;

  /// O código correspondente a [code], ou nulo se ele não for conhecido —
  /// caso em que o app trata a resposta como `E-SRV-01`.
  static ErrorCode? tryParse(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
"""

if __name__ == "__main__":
    main()
