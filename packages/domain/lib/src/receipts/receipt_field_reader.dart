import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/payment_method_kind.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/receipts/document_kind.dart';

/// As regras fixas que leem um comprovante **sem IA e sem rede** (RN-752):
/// valor, data, forma de pagamento, parcelas, estabelecimento e o tipo do
/// documento.
///
/// O valor e a data que o app mostra vêm daqui. A IA nunca os decide
/// sozinha: o que ela devolver só vale se também existir no texto (RN-774).
abstract final class ReceiptFieldReader {
  static final _amount = RegExp(r'\d{1,3}(?:\.\d{3}){0,3},\d{2}|\d{1,9},\d{2}');
  static final _labelledAmount = RegExp(
    '(?<![a-z])(?:total a pagar|valor pago|valor total|total|valor)'
    r'[^\n\d]{0,20}(\d{1,3}(?:\.\d{3}){0,3},\d{2}|\d{1,9},\d{2})',
    caseSensitive: false,
  );
  static final _notTheTotal = RegExp(
    'saldo|troco|desconto|subtotal|sub-total',
    caseSensitive: false,
  );
  static final _date = RegExp(r'\b(\d{2})/(\d{2})/(\d{4})\b');
  static final _installments = RegExp(
    r'\b(\d{1,2})\s?x\b|parc(?:ela)?\.?\s*\d{1,2}/(\d{1,2})|parcelado em (\d{1,2})',
    caseSensitive: false,
  );
  static final _merchantLabel = RegExp(
    r'^\s*(?:destinat[aá]rio|favorecido|recebedor|benefici[aá]rio|'
    r'estabelecimento|raz[aã]o social)\s*:\s*([^\n]{2,80})$',
    caseSensitive: false,
    multiLine: true,
  );

  static const Map<String, PaymentMethodKind> _paymentWords = {
    'pix': PaymentMethodKind.pix,
    'credito': PaymentMethodKind.creditCard,
    'crédito': PaymentMethodKind.creditCard,
    'debito': PaymentMethodKind.debit,
    'débito': PaymentMethodKind.debit,
    'boleto': PaymentMethodKind.bankSlip,
    'linha digitável': PaymentMethodKind.bankSlip,
    'código de barras': PaymentMethodKind.bankSlip,
    'dinheiro': PaymentMethodKind.physicalCash,
    'espécie': PaymentMethodKind.physicalCash,
  };

  static const Map<DocumentKind, List<String>> _kindWords = {
    DocumentKind.statementPayment: [
      'pagamento de fatura',
      'pgto fatura',
      'fatura do cartão',
      'pagamento cartão de crédito',
    ],
    DocumentKind.incomeReceipt: [
      'pix recebido',
      'transferência recebida',
      'você recebeu',
      'crédito em conta',
      'crédito de salário',
      'depósito',
    ],
    DocumentKind.ownTransfer: ['saque', 'transferência entre contas'],
  };

  /// Todos os valores em dinheiro que aparecem em [text], em centavos. É
  /// contra esta lista que se confere o valor devolvido pela IA.
  static Set<Money> amountsIn(String text) => {
    for (final match in _amount.allMatches(text)) _money(match.group(0)!),
  };

  /// Os candidatos a valor do comprovante (RN-753). Um só, quando há rótulo
  /// ("TOTAL"); senão, todos os números, do maior para o menor. Número de
  /// saldo, troco, desconto ou subtotal nunca é candidato.
  static List<Money> amountCandidates(String text) {
    final lines = text.split('\n').where((l) => !_notTheTotal.hasMatch(l));
    final usable = lines.join('\n');
    final labelled = _labelledAmount.firstMatch(usable);
    if (labelled != null) return [_money(labelled.group(1)!)];
    return amountsIn(usable).toList()..sort((a, b) => b.compareTo(a));
  }

  static Money _money(String text) =>
      Money.fromCents(int.parse(text.replaceAll('.', '').replaceAll(',', '')));

  /// A primeira data do texto que existe no calendário e não está no futuro
  /// (RN-746): data futura deixa o campo vazio, em vez de propor um erro.
  static LocalDate? dateIn(String text, {required LocalDate today}) {
    for (final match in _date.allMatches(text)) {
      final [day, month, year] = [
        for (var i = 1; i <= 3; i++) int.parse(match.group(i)!),
      ];
      final real = DateTime.utc(year, month, day);
      if (real.month != month || real.day != day) continue;
      final date = LocalDate(year, month, day);
      if (!date.isAfter(today)) return date;
    }
    return null;
  }

  /// A forma de pagamento, pelas palavras do texto (RN-754).
  static PaymentMethodKind? paymentKindIn(String text) {
    final lower = text.toLowerCase();
    for (final MapEntry(key: word, value: kind) in _paymentWords.entries) {
      if (lower.contains(word)) return kind;
    }
    return null;
  }

  /// Em quantas vezes, quando o texto fala em parcelas (RN-755).
  static int? installmentsIn(String text) {
    final match = _installments.firstMatch(text);
    if (match == null) return null;
    final count = int.parse(
      match.group(1) ?? match.group(2) ?? match.group(3)!,
    );
    return count >= 2 ? count : null;
  }

  /// O estabelecimento: o que vem depois de "Destinatário:" e afins; sem
  /// rótulo, a primeira linha com cara de nome.
  static String? merchantIn(String text) {
    final labelled = _merchantLabel.firstMatch(text);
    if (labelled != null) return labelled.group(1)!.trim();
    for (final line in text.split('\n').map((l) => l.trim())) {
      final letters = line.replaceAll(RegExp('[^A-Za-zÀ-ú]'), '').length;
      final header = RegExp(
        '^(comprovante|recibo|cupom|pix|nota)',
        caseSensitive: false,
      ).hasMatch(line);
      if (letters >= 4 && !header && !line.contains(':')) return line;
    }
    return null;
  }

  /// O tipo do documento, pelas palavras do texto (RN-756, RN-758 e RN-759).
  static DocumentKind documentKindIn(String text) {
    final lower = text.toLowerCase();
    for (final MapEntry(key: kind, value: words) in _kindWords.entries) {
      if (words.any(lower.contains)) return kind;
    }
    return DocumentKind.purchase;
  }
}
