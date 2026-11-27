import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/assistant/entry_rules.dart';
import 'package:server/src/assistant/payment_choice.dart';
import 'package:server/src/assistant/tool_args.dart';
import 'package:server/src/assistant/tool_outcome.dart';
import 'package:server/src/assistant/tool_refusal.dart';
import 'package:server/src/ledger/fingerprint.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// As correções que a conversa faz num lançamento que já existe (RN-208):
/// trocar a categoria, o valor, a data, a descrição ou a forma de pagamento.
///
/// Corrigir **substitui**: grava a versão nova do mesmo lançamento, com o
/// mesmo id, e o original fica guardado no registro. Antes não havia como
/// corrigir o valor pela conversa, e o modelo lançava outro — o "pedi para
/// corrigir e ele somou" (27/11/2026).
final class EntryRevisions {
  /// Cria as correções sobre o estado [state], o registro [store] e o
  /// relógio.
  const new({required this.state, required this.store, required this.clock});

  /// A projeção do livro.
  final LedgerState state;

  /// O registro de eventos.
  final EventStore store;

  /// De onde vem o dia de hoje e o carimbo da correção.
  final Clock clock;

  /// O teto da descrição, o mesmo do lançamento (RN-775).
  static const maxDescription = 60;

  /// Troca a categoria do lançamento de [args].
  Future<ToolOutcome> recategorize(Map<String, Object?> args) async {
    final entry = _entry(args);
    final category = _category(args);
    final revised = _revised(entry, categoryId: category.id);
    await _save(revised);
    return ToolOutcome.done({
      'ok': true,
      'id': entry.id,
      'descricao': entry.description,
      'categoria': category.name,
    });
  }

  /// Corrige valor, data, descrição ou forma de pagamento do lançamento de
  /// [args]. O que não veio fica como estava.
  Future<ToolOutcome> correct(Map<String, Object?> args) async {
    final entry = _entry(args);
    final cents = ToolArgs.integer(args, 'valor_centavos');
    final choice = _choice(args);
    if (cents != null && cents <= 0) {
      throw const ToolRefusal('"valor_centavos" precisa ser maior que zero');
    }
    if ((cents != null || choice != null) && entry.paymentLines.length > 1) {
      throw const ToolRefusal(
        'este lançamento foi pago em duas formas; valor e forma se corrigem '
        'no app, em Lançamentos',
      );
    }
    final revised = _revised(
      entry,
      amountCents: cents,
      occurredOn: ToolArgs.date(args, 'data'),
      description: ToolArgs.text(args, 'descricao', maxLength: maxDescription),
      choice: choice,
    );
    await _save(revised);
    return ToolOutcome.done({
      'ok': true,
      'id': entry.id,
      'descricao': revised.description,
      'valor_centavos': revised.amountCents,
      'data': revised.occurredOn,
    });
  }

  Entry _entry(Map<String, Object?> args) {
    final id = ToolArgs.required(args, 'id');
    return state.entryOf(id) ??
        (throw const ToolRefusal(
          'não há lançamento vivo com esse id; liste os lançamentos',
        ));
  }

  Category _category(Map<String, Object?> args) {
    final id = ToolArgs.required(args, 'categoria_id');
    return state.categories[id] ??
        (throw ToolRefusal(
          'categoria desconhecida: "$id"; use um destes ids: '
          '${state.categories.keys.join(', ')}',
        ));
  }

  PaymentChoice? _choice(Map<String, Object?> args) {
    final raw = ToolArgs.text(args, 'forma');
    if (raw == null) return null;
    return PaymentChoice.parse(raw, cards: state.cards) ??
        (throw ToolRefusal(
          'forma de pagamento desconhecida: "$raw"; use '
          '${PaymentChoice.options} ou o id de um cartão do cadastro',
        ));
  }

  /// O mesmo lançamento com o que mudou, carimbado agora: a correção mais
  /// nova vence (BL-062).
  CreateEntryRequest _revised(
    Entry entry, {
    String? categoryId,
    int? amountCents,
    LocalDate? occurredOn,
    String? description,
    PaymentChoice? choice,
  }) {
    final before = EntryCodec.fromEntry(entry);
    final cents = amountCents ?? before.amountCents;
    return CreateEntryRequest(
      id: before.id,
      description: description ?? before.description,
      amountCents: cents,
      occurredOn: occurredOn == null ? before.occurredOn : '$occurredOn',
      categoryId: categoryId ?? before.categoryId,
      paymentLines: _lines(before, amountCents, choice),
      isExceptional: before.isExceptional,
      installments: before.installments,
      // O valor da parcela é o do total antigo: com total novo, o app
      // recalcula a parcela, em vez de guardar uma que não fecha.
      installmentAmountCents: amountCents == null
          ? before.installmentAmountCents
          : null,
      origin: before.origin,
      revisedAt: clock.now(),
    );
  }

  /// As linhas de pagamento: as mesmas, ou uma só com o valor e a forma
  /// novos. Lançamento dividido não chega aqui com valor ou forma.
  static List<PaymentLineDto> _lines(
    CreateEntryRequest before,
    int? amountCents,
    PaymentChoice? choice,
  ) {
    if (amountCents == null && choice == null) return before.paymentLines;
    final line = before.paymentLines.first;
    return [
      PaymentLineDto(
        paymentMethodId: choice?.id ?? line.paymentMethodId,
        kind: choice?.kind.name ?? line.kind,
        amountCents: amountCents ?? before.amountCents,
      ),
    ];
  }

  /// As regras de qualquer correção (o vale paga só comida, a data não vai
  /// para o futuro), e só então o fato.
  Future<void> _save(CreateEntryRequest revised) async {
    EntryRules.check(revised, state, today: clock.today());
    final payload = revised.toJson();
    final event = await store.append(
      id: 'entry-revised-${revised.id}-${Fingerprint.of(payload)}',
      type: LedgerState.entryRevised,
      payload: payload,
    );
    state.apply(event);
  }
}
