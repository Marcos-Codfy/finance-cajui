import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/assistant/assistant_action.dart';
import 'package:server/src/assistant/payment_choice.dart';
import 'package:server/src/assistant/tool_args.dart';
import 'package:server/src/assistant/tool_outcome.dart';
import 'package:server/src/assistant/tool_refusal.dart';
import 'package:server/src/auth/secure_random.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// O que o assistente **escreve** no livro a pedido da pessoa (ADR-021):
/// lançar uma despesa, cancelar um lançamento, registrar uma renda.
///
/// O caminho é o mesmo das rotas: aplicar as regras do domínio, gravar o
/// evento e só então atualizar a projeção. O que nasce aqui é um fato comum
/// do registro, e desce aos celulares na próxima sincronização como se um
/// deles o tivesse feito.
final class AssistantActions {
  /// Cria as ações sobre o estado [state], o registro [store] e o relógio.
  const new({required this.state, required this.store, required this.clock});

  /// A projeção do livro.
  final LedgerState state;

  /// O registro de eventos.
  final EventStore store;

  /// De onde vem o dia de hoje.
  final Clock clock;

  /// O teto da descrição de um lançamento, o mesmo da tela (RN-775).
  static const maxDescription = 60;

  /// Lança a despesa descrita em [args].
  Future<ToolOutcome> record(Map<String, Object?> args) async {
    final category = _category(args);
    final choice = _choice(args);
    final request = _requestFor(args, category, choice);
    _checked(request);
    await _append(
      id: 'entry-${request.id}',
      type: LedgerState.entryCreated,
      payload: request.toJson(),
    );
    return ToolOutcome.done(
      {
        'ok': true,
        'id': request.id,
        'descricao': request.description,
        'valor_centavos': request.amountCents,
        'categoria': category.name,
        'forma': choice.label,
        'data': request.occurredOn,
      },
      action: AssistantAction.recorded(
        id: request.id,
        label: request.description,
        amountCents: request.amountCents,
      ),
    );
  }

  /// Cancela o lançamento de [args]. Cancelar não apaga (RN-208).
  Future<ToolOutcome> cancel(Map<String, Object?> args) async {
    final id = ToolArgs.required(args, 'id');
    final entry = state.entryOf(id);
    if (entry == null) {
      throw const ToolRefusal(
        'não há lançamento vivo com esse id; liste os lançamentos',
      );
    }
    await _append(
      id: 'entry-cancelled-$id',
      type: LedgerState.entryCancelled,
      payload: {'id': id},
    );
    return ToolOutcome.done(
      {'ok': true, 'id': id, 'descricao': entry.description},
      action: AssistantAction.cancelled(
        id: id,
        label: entry.description,
        amountCents: entry.amount.cents,
      ),
    );
  }

  /// Registra a renda de [args]. Salário em dinheiro é a renda do mês, e
  /// substitui a esperada no plano (RN-131); o resto é entrada avulsa.
  Future<ToolOutcome> income(Map<String, Object?> args) async {
    final receipt = _receiptOf(args);
    await _append(
      id: 'income-${receipt.id}',
      type: LedgerState.incomeReceived,
      payload: IncomeCodec.encode(receipt),
    );
    final label = _incomeLabel(receipt);
    return ToolOutcome.done(
      {
        'ok': true,
        'id': receipt.id,
        'valor_centavos': receipt.amount.cents,
        'o_que': label,
      },
      action: AssistantAction.income(
        id: receipt.id,
        label: label,
        amountCents: receipt.amount.cents,
      ),
    );
  }

  IncomeReceipt _receiptOf(Map<String, Object?> args) {
    final tender = ToolArgs.text(args, 'moeda') == 'vale'
        ? Tender.mealVoucher
        : Tender.cash;
    final salary = (ToolArgs.text(args, 'tipo') ?? 'salario') == 'salario';
    return IncomeReceipt(
      id: _newId('renda'),
      sourceId: salary && tender == Tender.cash ? 'cash-income' : null,
      tender: tender,
      amount: Money.fromCents(ToolArgs.positiveCents(args, 'valor_centavos')),
      receivedOn: ToolArgs.date(args, 'data') ?? clock.today(),
    );
  }

  static String _incomeLabel(IncomeReceipt receipt) {
    if (receipt.tender == Tender.mealVoucher) return 'Crédito do vale';
    return receipt.sourceId == null ? 'Entrada avulsa' : 'Salário';
  }

  CreateEntryRequest _requestFor(
    Map<String, Object?> args,
    Category category,
    PaymentChoice choice,
  ) {
    final cents = ToolArgs.positiveCents(args, 'valor_centavos');
    return CreateEntryRequest(
      id: _newId('despesa'),
      description: _description(args, category),
      amountCents: cents,
      occurredOn: '${ToolArgs.date(args, 'data') ?? clock.today()}',
      categoryId: category.id,
      paymentLines: [
        PaymentLineDto(
          paymentMethodId: choice.id,
          kind: choice.kind.name,
          amountCents: cents,
        ),
      ],
      installments: _installments(args, choice),
    );
  }

  /// Grava o evento e só então muda a projeção, como toda rota faz.
  Future<void> _append({
    required String id,
    required String type,
    required Map<String, Object?> payload,
  }) async {
    final event = await store.append(id: id, type: type, payload: payload);
    state.apply(event);
  }

  Category _category(Map<String, Object?> args) {
    final id = ToolArgs.required(args, 'categoria_id');
    return state.categories[id] ??
        (throw ToolRefusal(
          'categoria desconhecida: "$id"; use um destes ids: '
          '${state.categories.keys.join(', ')}',
        ));
  }

  PaymentChoice _choice(Map<String, Object?> args) {
    final raw = ToolArgs.text(args, 'forma') ?? 'pix';
    return PaymentChoice.parse(raw, cards: state.cards) ??
        (throw ToolRefusal(
          'forma de pagamento desconhecida: "$raw"; use '
          '${PaymentChoice.options} ou o id de um cartão do cadastro',
        ));
  }

  /// Sem descrição, vale o nome da categoria: "Mercado" diz o bastante.
  String _description(Map<String, Object?> args, Category category) =>
      ToolArgs.text(args, 'descricao', maxLength: maxDescription) ??
      category.name;

  static int? _installments(Map<String, Object?> args, PaymentChoice choice) {
    final count = ToolArgs.integer(args, 'parcelas');
    if (count == null || count < 2) return null;
    if (!choice.kind.isCreditCard) {
      throw const ToolRefusal('parcelar só em cartão de crédito');
    }
    return count;
  }

  /// As regras do domínio, as mesmas de qualquer lançamento (T-05). O que
  /// recusa volta ao modelo com o motivo, para ele pedir o que falta.
  void _checked(CreateEntryRequest request) {
    final Result<Entry> result;
    try {
      result = state.tryCreate(request, today: clock.today());
    } on FormatException {
      throw const ToolRefusal(
        'pedido fora do formato: confira data e parcelas',
      );
    }
    if (result.failureOrNull case final failure?) {
      throw ToolRefusal(_reason(failure));
    }
  }

  static String _reason(Failure failure) => switch (failure) {
    PurchaseDateInFuture() => 'a data da compra não pode estar no futuro',
    CategoryNotVoucherEligible() =>
      'o vale alimentação só paga categoria de alimentação',
    _ => 'recusado pela regra ${FailureMapper.map(failure).$1.code}',
  };

  /// Hora em base 36 e quatro letras ao acaso: ordena por criação e não
  /// repete, no mesmo molde dos identificadores do app.
  String _newId(String prefix) {
    final moment = clock.now().millisecondsSinceEpoch.toRadixString(36);
    return 'ia-$prefix-$moment-${SecureRandom.code(4).toLowerCase()}';
  }
}
