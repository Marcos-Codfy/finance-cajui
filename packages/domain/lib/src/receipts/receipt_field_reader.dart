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
  // Entre o rótulo e o número cabe uma quebra de linha: comprovante de banco
  // digital põe "Valor" numa linha e "R$ 6,00" na de baixo. O trecho não
  // aceita dígito, então o primeiro número depois do rótulo é o valor ou nada.
  static final _labelledAmount = RegExp(
    '(?<![a-z])(?:total a pagar|valor pago|valor total|total|valor)'
    r'[^\d]{0,20}(\d{1,3}(?:\.\d{3}){0,3},\d{2}|\d{1,9},\d{2})',
    caseSensitive: false,
  );
  static final _notTheTotal = RegExp(
    'saldo|troco|desconto|subtotal|sub-total',
    caseSensitive: false,
  );
  static final _date = RegExp(r'\b(\d{2})/(\d{2})/(\d{4})\b');
  // "12/set/2026", "12 de setembro de 2026", "12 SET 2026".
  static final _namedDate = RegExp(
    r'\b(\d{1,2})(?:/|\s+de\s+|\s+)'
    '(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)'
    r'[a-zç]{0,6}\.?(?:/|\s+de\s+|\s+)(\d{4})\b',
    caseSensitive: false,
  );
  static const _monthNames = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
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
  static LocalDate? dateIn(String text, {required LocalDate today}) =>
      datesIn(text, today: today).firstOrNull;

  /// Todas as datas do texto que existem no calendário e não estão no
  /// futuro, na ordem em que aparecem. É contra esta lista que se confere a
  /// data devolvida pela IA (RN-774), em qualquer das escritas aceitas.
  static List<LocalDate> datesIn(String text, {required LocalDate today}) {
    final found = [
      for (final match in _date.allMatches(text))
        (match.start, match.group(1)!, int.parse(match.group(2)!), match),
      for (final match in _namedDate.allMatches(text))
        (match.start, match.group(1)!, _monthOf(match.group(2)!), match),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (_, day, month, match) in found)
        if (_realDate(int.parse(match.group(3)!), month, int.parse(day))
            case final date? when !date.isAfter(today))
          date,
    ];
  }

  static int _monthOf(String name) =>
      _monthNames.indexOf(name.toLowerCase()) + 1;

  /// A data, se existir no calendário: "30 de fevereiro" não vira março.
  static LocalDate? _realDate(int year, int month, int day) {
    final real = DateTime.utc(year, month, day);
    if (real.month != month || real.day != day) return null;
    return LocalDate(year, month, day);
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
    final lines = [for (final line in text.split('\n')) line.trim()];
    final block = _merchantBlock(lines);
    if (block != null) return block;
    for (final line in lines) {
      final letters = line.replaceAll(RegExp('[^A-Za-zÀ-ú]'), '').length;
      if (letters >= 4 && !_isNotAName(line)) return line;
    }
    return null;
  }

  /// O recebedor em bloco, como os bancos digitais escrevem: "Para" sozinho
  /// numa linha, o nome quebrado nas linhas de baixo e, depois, o documento.
  static String? _merchantBlock(List<String> lines) {
    final at = lines.indexWhere(_blockLabel.hasMatch);
    if (at < 0) return null;
    final name = lines
        .skip(at + 1)
        .take(_maxNameLines)
        .takeWhile((line) => !_documentLine.hasMatch(line) && line.isNotEmpty)
        .join(' ');
    return name.length < 2 ? null : name;
  }

  static const _maxNameLines = 3;
  static final _blockLabel = RegExp(
    r'^(?:para|destino|recebedor|favorecido|destinat[aá]rio|quem recebeu)$',
    caseSensitive: false,
  );

  /// Linha que traz documento — CNPJ, CPF inteiro ou mascarado, ou o marcador
  /// que o mascaramento deixou no lugar. É onde o nome acaba.
  static final _documentLine = RegExp(
    r'\d{2}\.?\d{3}\.?\d{3}/\d{4}|\d{3}\.\d{3}\.\d{3}|\*{3}\.\d{3}|\[CNPJ\]|\[CPF\]',
  );

  /// Cabeçalho, rótulo solto ou linha com dois-pontos: tem letras, mas não é
  /// nome de estabelecimento.
  static bool _isNotAName(String line) =>
      line.contains(':') || _headerOrLabel.hasMatch(line);

  static final _headerOrLabel = RegExp(
    '^(?:comprovante|recibo|cupom|pix|nota)|'
    '^(?:valor(?: original| pago| total)?|de|para|data|origem|destino|'
    r'identificador|id da transa[cç][aã]o|detalhes da cobran[cç]a)$',
    caseSensitive: false,
  );

  /// O tipo do documento, pelas palavras do texto (RN-756, RN-758 e RN-759).
  static DocumentKind documentKindIn(String text) {
    final lower = text.toLowerCase();
    for (final MapEntry(key: kind, value: words) in _kindWords.entries) {
      if (words.any(lower.contains)) return kind;
    }
    return DocumentKind.purchase;
  }
}
