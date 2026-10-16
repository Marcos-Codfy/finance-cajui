import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/assistant/assistant_actions.dart';
import 'package:server/src/assistant/server_finances.dart';
import 'package:server/src/assistant/tool_args.dart';
import 'package:server/src/assistant/tool_outcome.dart';
import 'package:server/src/assistant/tool_refusal.dart';
import 'package:server/src/auth/secure_random.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// Abater uma dívida pela Juju (BL-117): "pagou R$ 800 do empréstimo".
///
/// São os dois passos que a pessoa faria no celular, na mesma ordem: o
/// dinheiro que saiu vira um lançamento do bloco de dívidas — pelo mesmo
/// caminho do `lancar_despesa`, com as mesmas regras e o mesmo Desfazer —, e
/// a dívida ganha uma versão nova com o saldo de agora menos o valor, como o
/// "atualizar saldo" do app faz. Os dois descem aos celulares como fatos de
/// qualquer aparelho.
final class DebtPaydown {
  /// Cria o abatimento sobre [state] e [store], lançando por [actions].
  const new({
    required this.state,
    required this.store,
    required this.clock,
    required this.actions,
  });

  /// A projeção do livro.
  final LedgerState state;

  /// O registro de eventos.
  final EventStore store;

  /// De onde vêm o dia e a hora.
  final Clock clock;

  /// Quem grava o lançamento.
  final AssistantActions actions;

  /// A categoria das parcelas de dívida, a mesma do celular.
  static const categoryId = 'debt-installment';

  /// Abate o valor de [args] da dívida de [args].
  Future<ToolOutcome> pay(Map<String, Object?> args) async {
    final debt = _debtOf(args);
    final on = ToolArgs.date(args, 'data') ?? clock.today();
    final amount = Money.fromCents(
      ToolArgs.positiveCents(args, 'valor_centavos'),
    );
    final owed = DebtCalendar.outstandingOn(debt, on);
    if (amount > owed) {
      throw ToolRefusal(
        'o valor passa do que ainda se deve de ${debt.creditor}: '
        '${owed.cents} centavos',
      );
    }
    final recorded = await actions.record({
      'categoria_id': categoryId,
      'descricao': '${debt.creditor} · abatimento',
      'valor_centavos': amount.cents,
      'forma': ?args['forma'],
      'data': '$on',
    });
    final left = owed - amount;
    await _keep(_lowered(debt, left, on));
    return ToolOutcome.done({
      ...recorded.result,
      'divida': debt.creditor,
      'ainda_deve_centavos': left.cents,
    }, action: recorded.action);
  }

  /// A dívida de [args], na versão que vale hoje. Parcela no cartão não se
  /// abate aqui: ela é cobrada na fatura, e lançar de novo contaria duas
  /// vezes (RN-521).
  Debt _debtOf(Map<String, Object?> args) {
    final id = ToolArgs.required(args, 'divida_id');
    final debt = ServerFinances.of(state).debts
        .where((each) => each.id == id)
        .firstOrNull;
    if (debt == null) {
      throw const ToolRefusal('dívida não encontrada: use um id de "dividas"');
    }
    if (debt.kind == DebtKind.cardInstallment) {
      throw const ToolRefusal(
        'parcela no cartão se paga pela fatura, não se abate à parte',
      );
    }
    return debt;
  }

  /// A versão nova: o saldo que sobrou, informado no dia do pagamento, com
  /// o resto da dívida como estava.
  Debt _lowered(Debt debt, Money left, LocalDate on) {
    final updated = Debt.withBalance(
      id: debt.id,
      creditor: debt.creditor,
      kind: debt.kind,
      balance: left,
      monthlyPayment: debt.installmentAmount,
      dueDay: debt.dueDay,
      informedOn: on,
      note: debt.note,
    ).valueOrNull!;
    return updated.keepingFrom(debt).stamped(clock.now());
  }

  /// Grava a versão como o celular grava a dele: um fato de dívida.
  Future<void> _keep(Debt debt) async {
    final moment = clock.now().millisecondsSinceEpoch.toRadixString(36);
    final id = 'debt-fact-ia-$moment-${SecureRandom.code(4).toLowerCase()}';
    final event = await store.append(
      id: 'fact-$id',
      type: DeviceFact.debtDefined,
      payload: {'id': id, 'payload': DebtCodec.encodeDebt(debt)},
    );
    state.apply(event);
  }
}
