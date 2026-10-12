import 'package:api_contract/src/entry_codec.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Uma movimentação lida numa página de extrato, já conferida pelo
/// servidor, como vai na resposta de `POST /v1/statements/read-part`
/// (ADR-030).
///
/// Ainda não é a linha do Cajui: a data vem como o extrato escreve — dia e
/// mês, e o ano só quando a linha o traz —, porque o ano certo depende do
/// período do extrato inteiro, e o período pode aparecer só numa página
/// depois desta (RN-1105). Quem junta as páginas resolve a data com
/// [lineOn].
@immutable
final class StatementMovement {
  /// Cria a movimentação.
  const new({
    required this.day,
    required this.month,
    required this.description,
    required this.amount,
    this.sourceLine,
    this.year,
    this.kind = StatementLineKind.expense,
    this.doubtful = false,
    this.categoryId,
    this.confidence = Confidence.low,
    this.paymentKind,
  });

  /// A movimentação em [json]; qualquer campo fora do formato lança, e
  /// [tryParse] a deixa de fora.
  factory _parse(Map<String, Object?> json, bool Function(String id) knows) {
    final category = json['categoryId'] as String?;
    final payment = json['paymentKind'] as String?;
    final cents = _within(json['amountCents']! as int, 1, maxCents)!;
    return StatementMovement(
      sourceLine: _within(json['line'] as int?, 1, 100000),
      day: _within(json['day']! as int, 1, 31)!,
      month: _within(json['month']! as int, 1, 12)!,
      year: _within(json['year'] as int?, 2000, 2100),
      description: _description(json['description']! as String),
      amount: Money.fromCents(cents),
      kind: EntryCodec.named(StatementLineKind.values, json['kind']! as String),
      doubtful: json['doubtful'] as bool? ?? false,
      categoryId: category != null && knows(category) ? category : null,
      confidence: EntryCodec.named(
        Confidence.values,
        json['confidence']! as String,
      ),
      paymentKind: payment == null
          ? null
          : EntryCodec.named(PaymentMethodKind.values, payment),
    );
  }

  /// O maior nome aceito na volta; o servidor já o filtrou com a política
  /// da descrição (RN-775), e isto só barra o que veio fora do formato.
  static const maxDescriptionLength = 80;

  /// O maior valor aceito: R$ 1.000.000,00, o mesmo teto do comprovante.
  static const maxCents = 100000000;

  /// O número da linha, na página, de onde a movimentação saiu, a partir
  /// de 1. É por ele que o celular volta ao texto sem máscara (RN-1106);
  /// `null` quando só a imagem a mostrava.
  final int? sourceLine;

  /// O dia, como o extrato escreve.
  final int day;

  /// O mês, como o extrato escreve.
  final int month;

  /// O ano, só quando a linha o trouxe.
  final int? year;

  /// O nome curto e legível: a marca conhecida, ou o que a IA escreveu e
  /// passou pelo filtro.
  final String description;

  /// O valor, sempre positivo; o sentido está em [kind].
  final Money amount;

  /// O que a movimentação é.
  final StatementLineKind kind;

  /// Se o tipo é só palavra da IA, sem nada escrito na linha que o
  /// confirme (RN-1110).
  final bool doubtful;

  /// O palpite de categoria, da lista enviada.
  final String? categoryId;

  /// O quanto a IA confia na categoria (RN-1109).
  final Confidence confidence;

  /// Por onde saiu, quando a linha diz.
  final PaymentMethodKind? paymentKind;

  /// A linha do Cajui, na página [page] de um extrato de [period]; `null`
  /// quando o dia não existe ou cai depois de [today] (RN-1105).
  StatementLine? lineOn({
    required int page,
    required BudgetMonth period,
    required LocalDate today,
  }) {
    final date = StatementDates.resolve(
      day: day,
      month: month,
      year: year,
      period: period,
      today: today,
    );
    if (date == null) return null;
    return StatementLine(
      occurredOn: date,
      description: description,
      amount: amount,
      kind: kind,
      categoryId: categoryId,
      paymentKind: paymentKind,
      doubtful: doubtful,
      confidence: confidence,
      page: page,
      sourceLine: sourceLine,
    );
  }

  /// A movimentação como vai na resposta.
  Map<String, Object?> toJson() => {
    'line': sourceLine,
    'day': day,
    'month': month,
    'year': ?year,
    'description': description,
    'amountCents': amount.cents,
    'kind': kind.name,
    if (doubtful) 'doubtful': true,
    'categoryId': categoryId,
    'confidence': confidence.name,
    'paymentKind': paymentKind?.name,
  };

  /// A movimentação de [json], ou `null` quando ela não se lê: uma que cai
  /// fora não leva as outras junto. Categoria que [knowsCategory] não
  /// conhece fica de fora, e a movimentação continua (RN-742).
  static StatementMovement? tryParse(
    Object? json, {
    required bool Function(String id) knowsCategory,
  }) {
    if (json is! Map<String, Object?>) return null;
    try {
      return StatementMovement._parse(json, knowsCategory);
    } on Object {
      return null;
    }
  }

  /// [value] entre [min] e [max]; fora disso, a movimentação não se lê.
  static int? _within(int? value, int min, int max) {
    if (value == null) return null;
    if (value < min || value > max) throw FormatException('fora: $value');
    return value;
  }

  static String _description(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.length > maxDescriptionLength) {
      throw const FormatException('descrição');
    }
    return text;
  }
}
