import 'package:domain/src/household/household_names.dart';
import 'package:domain/src/household/person_name.dart';
import 'package:domain/src/receipts/confidence.dart';
import 'package:domain/src/receipts/merchant_kind.dart';
import 'package:domain/src/receipts/merchant_name.dart';
import 'package:domain/src/receipts/statement_line.dart';
import 'package:domain/src/receipts/statement_line_kind.dart';
import 'package:domain/src/statements/income_line.dart';
import 'package:domain/src/statements/installment_mark.dart';
import 'package:domain/src/statements/learned_answer.dart';
import 'package:domain/src/statements/learned_answers.dart';
import 'package:domain/src/statements/line_doubt.dart';
import 'package:domain/src/statements/line_treatment.dart';
import 'package:domain/src/statements/merchant_brand.dart';
import 'package:domain/src/statements/resolved_line.dart';
import 'package:domain/src/statements/statement_line_keys.dart';
import 'package:domain/src/statements/transfer_line.dart';

/// Decide, no celular, o que cada linha lida de um extrato é (RN-1109,
/// RN-1110, RN-1111; ADR-030).
///
/// Roda aqui, e não no servidor, porque é aqui que estão o texto original
/// sem máscara e a memória das respostas. A precedência da categoria é:
/// resposta lembrada, marca conhecida, IA com confiança alta. A do tipo:
/// palavra escrita de fatura ou de conta sua, resposta lembrada que combine
/// com o sentido da linha, lista da casa. O que só a IA disse — todo Pix
/// para alguém que ninguém ensinou, e toda entrada sem palavra clara de
/// dinheiro chegando — vira pergunta.
abstract final class StatementLineResolver {
  /// O prefixo da chave de uma pessoa, para não cruzar com um
  /// estabelecimento de mesmo nome.
  static const String personPrefix = StatementLineKeys.personPrefix;

  /// Resolve [raw]. [original] é a linha como estava no texto do celular,
  /// antes da máscara; [categoryOfKind] traduz o ramo de uma marca na
  /// categoria do cadastro.
  static ResolvedLine resolve(
    StatementLine raw, {
    String? original,
    LearnedAnswers memory = LearnedAnswers.empty,
    HouseholdNames household = HouseholdNames.empty,
    String? Function(MerchantKind kind)? categoryOfKind,
  }) {
    final written = original ?? raw.description;
    final person = TransferLine.personIn(written);
    final brand = _brand(written, raw);
    final keys = StatementLineKeys.of(raw, original, person, brand);
    final known = keys.memory.isEmpty ? null : memory.forKey(keys.memory);
    final treatment =
        _compatible(known?.treatment, raw) ?? _household(person, household);
    final mark = _installment(raw, written);
    final kindDoubt =
        treatment == null && _kindInDoubt(raw, original, person, brand);
    final category = _category(raw, known, brand, categoryOfKind);
    final resolved = ResolvedLine(
      line: _line(raw, person, brand?.name, category, kindDoubt),
      merchantKey: keys.memory,
      contentKey: keys.content,
      person: person,
      treatment: treatment,
      installment: mark,
      guess: raw.categoryId,
      doubts: _doubts(kindDoubt: kindDoubt, mark: mark),
    );
    return _withCategoryDoubt(resolved, known);
  }

  /// A marca, pela linha escrita ou, se a máscara a escondeu, pelo que a IA
  /// devolveu.
  static MerchantBrand? _brand(String written, StatementLine raw) =>
      MerchantBrand.of(written) ?? MerchantBrand.of(raw.description);

  /// A parcela só interessa em saída: entrada com "3/10" é outra coisa.
  static InstallmentMark? _installment(StatementLine raw, String written) =>
      raw.kind == StatementLineKind.expense
      ? InstallmentMark.of(written)
      : null;

  /// A primeira parcela é compra deste mês; a partir da segunda, é compra de
  /// outro mês, e pergunta (RN-1111).
  static Set<LineDoubt> _doubts({
    required bool kindDoubt,
    InstallmentMark? mark,
  }) => {
    if (kindDoubt) LineDoubt.kind,
    if (mark != null && mark.number > 1) LineDoubt.installment,
  };

  /// A chave da memória para um Pix ou transferência com pessoa: o nome
  /// sem caixa, acento e partículas (RN-1071).
  static String personKey(String person) =>
      '$personPrefix${PersonName.of(person).words.join(' ')}';

  /// A resposta lembrada só vale quando combina com a linha (RN-1110):
  /// "é um gasto" não faz um Pix recebido virar despesa, nem "é dinheiro
  /// que entrou" faz um Pix enviado virar renda. Fatura e conta sua escritas
  /// na linha vencem a memória. Casa, conta sua e "não lançar" valem nos
  /// dois sentidos: dizem quem é, e não para onde foi o dinheiro.
  static LineTreatment? _compatible(
    LineTreatment? treatment,
    StatementLine raw,
  ) {
    final written =
        !raw.doubtful &&
        (raw.kind == StatementLineKind.cardPayment ||
            raw.kind == StatementLineKind.ownTransfer);
    if (treatment == null || written) return null;
    final income = raw.kind == StatementLineKind.income;
    return switch (treatment) {
      LineTreatment.expense => income ? null : treatment,
      LineTreatment.income => income ? treatment : null,
      _ => treatment,
    };
  }

  /// O tipo é dúvida quando só a IA disse, quando é Pix para alguém,
  /// quando é Pix ou transferência sem ninguém reconhecido e sem certeza da
  /// IA — o banco corta o nome, e "PIX ENVIADO JOAO" pode ser de tudo —, e
  /// quando é entrada sem palavra clara de dinheiro chegando.
  static bool _kindInDoubt(
    StatementLine raw,
    String? original,
    String? person,
    MerchantBrand? brand,
  ) {
    if (raw.doubtful || person != null) return true;
    final written = original ?? raw.description;
    return switch (raw.kind) {
      StatementLineKind.income =>
        original != null && !IncomeLine.isClear(original),
      StatementLineKind.expense =>
        TransferLine.isTransfer(written) &&
            brand == null &&
            raw.confidence != Confidence.high,
      _ => false,
    };
  }

  static LineTreatment? _household(String? person, HouseholdNames household) =>
      household.whoIs(person) == null ? null : LineTreatment.household;

  /// Resposta lembrada, marca conhecida, IA com confiança alta (RN-1109).
  static String? _category(
    StatementLine raw,
    LearnedAnswer? known,
    MerchantBrand? brand,
    String? Function(MerchantKind kind)? categoryOfKind,
  ) =>
      known?.categoryId ??
      (brand == null ? null : categoryOfKind?.call(brand.kind)) ??
      (raw.confidence == Confidence.high ? raw.categoryId : null);

  /// O nome que a pessoa reconhece: a marca, "Pix para" quem foi, ou o que
  /// a IA escreveu.
  static StatementLine _line(
    StatementLine raw,
    String? person,
    String? brand,
    String? category,
    bool doubtful,
  ) => StatementLine(
    occurredOn: raw.occurredOn,
    description: brand ?? _transfer(raw, person) ?? raw.description,
    amount: raw.amount,
    kind: raw.kind,
    categoryId: category,
    paymentKind: raw.paymentKind,
    doubtful: doubtful,
    confidence: category == null ? raw.confidence : Confidence.high,
    page: raw.page,
    sourceLine: raw.sourceLine,
  );

  static String? _transfer(StatementLine raw, String? person) {
    if (person == null) return null;
    final name = MerchantName.pretty(person) ?? person;
    return raw.kind == StatementLineKind.income
        ? 'Pix de $name'
        : 'Pix para $name';
  }

  /// A categoria só é dúvida em linha que vira gasto: fatura, conta sua e
  /// alguém da casa não têm categoria.
  static ResolvedLine _withCategoryDoubt(
    ResolvedLine resolved,
    LearnedAnswer? known,
  ) {
    final needs =
        resolved.isExpense &&
        resolved.line.categoryId == null &&
        known?.categoryId == null;
    if (!needs) return resolved;
    return ResolvedLine(
      line: resolved.line,
      merchantKey: resolved.merchantKey,
      contentKey: resolved.contentKey,
      person: resolved.person,
      treatment: resolved.treatment,
      installment: resolved.installment,
      guess: resolved.guess,
      doubts: {...resolved.doubts, LineDoubt.category},
    );
  }
}
