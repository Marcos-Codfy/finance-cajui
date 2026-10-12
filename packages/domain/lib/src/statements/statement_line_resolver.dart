import 'package:domain/src/household/household_names.dart';
import 'package:domain/src/household/person_name.dart';
import 'package:domain/src/receipts/confidence.dart';
import 'package:domain/src/receipts/merchant_kind.dart';
import 'package:domain/src/receipts/merchant_name.dart';
import 'package:domain/src/receipts/statement_line.dart';
import 'package:domain/src/receipts/statement_line_kind.dart';
import 'package:domain/src/statements/learned_answer.dart';
import 'package:domain/src/statements/learned_answers.dart';
import 'package:domain/src/statements/line_doubt.dart';
import 'package:domain/src/statements/line_treatment.dart';
import 'package:domain/src/statements/merchant_brand.dart';
import 'package:domain/src/statements/resolved_line.dart';
import 'package:domain/src/statements/transfer_line.dart';

/// Decide, no celular, o que cada linha lida de um extrato é (RN-1109,
/// RN-1110; ADR-030).
///
/// Roda aqui, e não no servidor, porque é aqui que estão o texto original
/// sem máscara e a memória das respostas. A precedência da categoria é:
/// resposta lembrada, marca conhecida, IA com confiança alta. A do tipo:
/// resposta lembrada, lista da casa, palavra escrita na linha; o que só a
/// IA disse — e todo Pix para alguém que ninguém ensinou — vira pergunta.
abstract final class StatementLineResolver {
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
    final brand =
        MerchantBrand.of(written) ?? MerchantBrand.of(raw.description);
    final key = person != null
        ? personKey(person)
        : MerchantBrand.keyOf(brand?.name ?? raw.description);
    final known = memory.forKey(key);
    final treatment = known?.treatment ?? _household(person, household);
    final kindDoubt = treatment == null && (raw.doubtful || person != null);
    final category = _category(raw, known, brand, categoryOfKind);
    final resolved = ResolvedLine(
      line: _line(raw, person, brand?.name, category, kindDoubt),
      merchantKey: key,
      person: person,
      treatment: treatment,
      guess: raw.categoryId,
      doubts: {if (kindDoubt) LineDoubt.kind},
    );
    return _withCategoryDoubt(resolved, known);
  }

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

  /// A chave da memória para um Pix ou transferência com pessoa: o nome
  /// sem caixa, acento e partículas (RN-1071), com prefixo próprio para não
  /// cruzar com um estabelecimento de mesmo nome.
  static String personKey(String person) =>
      '$personPrefix${PersonName.of(person).words.join(' ')}';

  /// O começo de toda chave de pessoa. Exemplo com ele nunca vai à IA
  /// (RN-1107): o servidor confere de novo, sem confiar no celular.
  static const personPrefix = 'pessoa:';

  static LineTreatment? _household(String? person, HouseholdNames household) =>
      household.whoIs(person) == null ? null : LineTreatment.household;

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
      person: resolved.person,
      treatment: resolved.treatment,
      guess: resolved.guess,
      doubts: {...resolved.doubts, LineDoubt.category},
    );
  }
}
