import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/income/income_receipt.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/money/money.dart';

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
      _looksLike(
        existing,
        amount: candidate.amount,
        occurredOn: candidate.occurredOn,
        description: candidate.description,
      );

  /// O lançamento de [entries] que parece ser o mesmo que um de [amount],
  /// [occurredOn] e [description]; `null` quando nenhum parece.
  ///
  /// Existe para o comprovante que ainda **não é** lançamento: na hora de
  /// conferir uma captura não há um `Entry` para comparar, e era por isso
  /// que a RN-221 vivia só no domínio, sem tela que a usasse.
  static Entry? among(
    Iterable<Entry> entries, {
    required Money amount,
    required LocalDate occurredOn,
    required String description,
  }) {
    for (final entry in entries) {
      if (_looksLike(
        entry,
        amount: amount,
        occurredOn: occurredOn,
        description: description,
      )) {
        return entry;
      }
    }
    return null;
  }

  /// O lançamento de [entries] com o mesmo valor e a data a até [days] dias
  /// de [occurredOn]; `null` quando nenhum.
  ///
  /// É a conferência do extrato (RN-707): o banco escreve o nome do lugar do
  /// jeito dele — "PIX ENVIADO PADARIA CENT" —, e a data às vezes é a do
  /// processamento. Valor igual com a data perto basta para **avisar**; a
  /// pessoa decide.
  static Entry? near(
    Iterable<Entry> entries, {
    required Money amount,
    required LocalDate occurredOn,
    int days = 2,
  }) {
    for (final entry in entries) {
      final apart = occurredOn.daysUntil(entry.occurredOn).abs();
      if (entry.amount == amount && apart <= days) return entry;
    }
    return null;
  }

  /// O recebimento de [receipts] com o mesmo valor e a data a até [days]
  /// dias de [receivedOn]: a entrada do extrato que já foi registrada.
  static IncomeReceipt? receivedNear(
    Iterable<IncomeReceipt> receipts, {
    required Money amount,
    required LocalDate receivedOn,
    int days = 2,
  }) {
    for (final receipt in receipts) {
      final apart = receivedOn.daysUntil(receipt.receivedOn).abs();
      if (receipt.amount == amount && apart <= days) return receipt;
    }
    return null;
  }

  static bool _looksLike(
    Entry entry, {
    required Money amount,
    required LocalDate occurredOn,
    required String description,
  }) =>
      entry.amount == amount &&
      entry.occurredOn == occurredOn &&
      normalize(entry.description) == normalize(description);

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
