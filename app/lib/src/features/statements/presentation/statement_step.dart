import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:domain/domain.dart';

/// O que a Juju pede agora na conversa do extrato (RN-1111 a RN-1114).
///
/// A ordem: o cartão, quando há mais de um e o extrato tem compra no
/// cartão; as parcelas de outros meses, de uma vez; os blocos, do maior
/// para o menor; as dúvidas, uma a uma; o que já estava no Cajui; e o
/// convite a lançar. O cartão e as parcelas vêm antes dos blocos porque
/// mudam o que os blocos dizem.
sealed class StatementStep {
  const new _();

  /// O passo de [talk].
  static StatementStep of(StatementTalkOpen talk) {
    final digest = talk.digest;
    if (_asksCard(talk)) return CardStep._(talk.cards);
    if (talk.installments == null && digest.installments.isNotEmpty) {
      return const InstallmentStep._();
    }
    for (final block in digest.blocks) {
      if (!talk.confirmed.containsAll(block.lines)) return BlockStep._(block);
    }
    final ranked = {...digest.rankedCategories, ...talk.categoryOrder}.toList();
    for (final index in digest.questions) {
      final question = StatementQuestion.of(
        index,
        talk.lines[index],
        ranked: ranked,
      );
      if (question != null) return QuestionStep._(question);
    }
    if (!talk.alreadySeen && digest.alreadyThere.isNotEmpty) {
      return const AlreadyStep._();
    }
    return const ReadyStep._();
  }

  /// Com mais de um cartão, a compra no cartão precisa dizer qual
  /// (RN-1114): a fatura inteira é de um cartão só, e a pergunta é uma.
  static bool _asksCard(StatementTalkOpen talk) {
    if (talk.cardId != null || talk.cards.length < 2) return false;
    final digest = talk.digest;
    return [...digest.ready, ...digest.questions, ...digest.installments].any(
      (i) => talk.lines[i].line.paymentKind == PaymentMethodKind.creditCard,
    );
  }
}

/// "As compras no cartão deste extrato são de qual cartão?"
final class CardStep extends StatementStep {
  const new _(this.cards) : super._();

  /// Os cartões oferecidos.
  final List<StatementCard> cards;
}

/// "8 parcelas de compras de outros meses… lanço como gasto deste mês?"
final class InstallmentStep extends StatementStep {
  const new _() : super._();
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

/// "10 movimentações já estavam no Cajui… Confere?"
final class AlreadyStep extends StatementStep {
  const new _() : super._();
}

/// Tudo conferido: falta só lançar.
final class ReadyStep extends StatementStep {
  const new _() : super._();
}
