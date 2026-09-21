import 'package:domain/src/ledger/entry.dart';

/// Reconhece um lançamento que **parece** repetido (RN-221): mesmo valor,
/// mesma data e estabelecimento equivalente.
///
/// O resultado é só motivo para um **aviso**. Dois cafés de R$ 8,50 no mesmo
/// dia são legítimos: o app pergunta, e quem decide é a pessoa. Nada é
/// bloqueado nem descartado em silêncio.
abstract final class PossibleDuplicate {
  static const _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'è': 'e',
    'ë': 'e',
    'í': 'i',
    'î': 'i',
    'ì': 'i',
    'ï': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ò': 'o',
    'ö': 'o',
    'ú': 'u',
    'û': 'u',
    'ù': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  /// Sufixos de razão social, que aparecem num comprovante e somem no outro.
  static const _companySuffixes = {'ltda', 'me', 'sa', 'eireli', 'epp'};

  /// [candidate] parece ser o mesmo que [existing].
  static bool matches(Entry candidate, Entry existing) =>
      candidate.id != existing.id &&
      candidate.amount == existing.amount &&
      candidate.occurredOn == existing.occurredOn &&
      normalize(candidate.description) == normalize(existing.description);

  /// O nome do estabelecimento sem o que varia de um comprovante para outro:
  /// caixa, acento, pontuação, espaço sobrando e sufixo de razão social.
  ///
  /// "PADARIA CENTRAL LTDA." e "Padaria  Central" viram a mesma coisa.
  static String normalize(String description) {
    final plain = description
        .toLowerCase()
        .split('')
        .map((char) => _accents[char] ?? char)
        .join()
        .replaceAll(RegExp('[^a-z0-9 ]'), ' ');
    return plain.split(' ').where(_isMeaningful).join(' ');
  }

  /// Fica de fora o que não identifica o lugar: vazio, sufixo de razão social
  /// e palavra só de dígitos, como o número da loja (RN-727).
  static bool _isMeaningful(String word) =>
      word.isNotEmpty &&
      !_companySuffixes.contains(word) &&
      !RegExp(r'^\d+$').hasMatch(word);
}
