import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:domain/domain.dart';

/// O que a Juju pede agora na conversa do extrato (RN-1113, RN-1114): os
/// blocos primeiro, do maior para o menor; depois as dúvidas, uma a uma; e
/// por fim o convite a lançar.
sealed class StatementStep {
  const new _();

  /// O passo de [talk].
  static StatementStep of(StatementTalkOpen talk) {
    for (final block in talk.digest.blocks) {
      if (!talk.confirmed.contains(block.categoryId)) return BlockStep._(block);
    }
    final ranked = {
      ...talk.digest.rankedCategories,
      ...talk.categoryOrder,
    }.toList();
    for (final index in talk.digest.questions) {
      final question = StatementQuestion.of(
        index,
        talk.lines[index],
        ranked: ranked,
      );
      if (question != null) return QuestionStep._(question);
    }
    return const ReadyStep._();
  }
}

/// "Mercado — 12 compras… Confere?"
final class BlockStep extends StatementStep {
  const new _(this.block) : super._();

  /// O bloco a conferir.
  final StatementBlock block;
}

/// Uma dúvida, com as opções.
final class QuestionStep extends StatementStep {
  const new _(this.question) : super._();

  /// A pergunta.
  final StatementQuestion question;
}

/// Tudo conferido: falta só lançar.
final class ReadyStep extends StatementStep {
  const new _() : super._();
}
