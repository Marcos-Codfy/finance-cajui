import 'package:domain/src/receipts/statement_line_kind.dart';
import 'package:domain/src/statements/line_doubt.dart';
import 'package:domain/src/statements/line_treatment.dart';
import 'package:domain/src/statements/resolved_line.dart';
import 'package:meta/meta.dart';

/// Uma pergunta da Juju sobre uma linha que ficou em dúvida (RN-1114).
///
/// O tipo vem antes da categoria: "Pix para João" pode nem ser gasto, e
/// perguntar a categoria de algo que talvez não entre seria pergunta à toa.
@immutable
sealed class StatementQuestion {
  const new _(this.line);

  /// A linha da pergunta, pelo índice na lista lida.
  final int line;

  /// A pergunta que [resolved], a linha [index], precisa — ou `null` se ela
  /// está certa. [ranked] são as categorias na ordem em que a pessoa mais
  /// usa, para a de categoria oferecer as mais prováveis.
  static StatementQuestion? of(
    int index,
    ResolvedLine resolved, {
    required List<String> ranked,
  }) {
    if (resolved.doubts.contains(LineDoubt.kind)) {
      return KindQuestion._(index, _kindsFor(resolved));
    }
    if (resolved.doubts.contains(LineDoubt.category)) {
      return CategoryQuestion._(index, _likely(resolved.guess, ranked));
    }
    return null;
  }

  /// Uma entrada pode ser renda; uma saída, gasto. As outras saídas valem
  /// para as duas.
  static List<LineTreatment> _kindsFor(ResolvedLine resolved) => [
    if (resolved.line.kind == StatementLineKind.income)
      LineTreatment.income
    else
      LineTreatment.expense,
    LineTreatment.household,
    LineTreatment.ownAccount,
    LineTreatment.ignore,
  ];

  /// O palpite da IA primeiro, depois as mais usadas: quatro, no máximo,
  /// com "Outra" no fim por conta de quem desenha.
  static List<String> _likely(String? guess, List<String> ranked) =>
      {?guess, ...ranked}.take(CategoryQuestion.maxCandidates).toList();
}

/// "O que foi?": gasto (ou entrada), alguém da casa, conta sua, não lançar.
final class KindQuestion extends StatementQuestion {
  const new _(super.line, this.options) : super._();

  /// As respostas possíveis, na ordem em que aparecem.
  final List<LineTreatment> options;
}

/// "Qual é a categoria?": as mais prováveis, e "Outra".
final class CategoryQuestion extends StatementQuestion {
  const new _(super.line, this.candidates) : super._();

  /// Quantas categorias a pergunta oferece antes de "Outra".
  static const maxCandidates = 4;

  /// As categorias oferecidas, pelo id.
  final List<String> candidates;
}
