import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/plan_service.dart';
import 'package:cajui/src/features/budget/presentation/bill_line_choices.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uma linha de "Minhas contas": o que é, quanto por mês, em que grupo, de
/// que tipo de gasto, onde se paga e uma observação — as colunas da planilha.
class BillLinePage extends ConsumerStatefulWidget {
  /// Cria a tela da linha [line] do grupo [group]; `null` cria uma nova.
  const new({required this.group, this.line, super.key});

  /// O grupo em que a linha começa.
  final LineGroup group;

  /// A linha que está sendo mudada, ou `null`.
  final BudgetLine? line;

  /// Abre a tela.
  static Future<void> open(
    BuildContext context,
    LineGroup group, {
    BudgetLine? line,
  }) => Navigator.of(context).push<void>(
    CajuiPageRoute(
      builder: (_) => BillLinePage(group: group, line: line),
    ),
  );

  @override
  ConsumerState<BillLinePage> createState() => _BillLinePageState();
}

class _BillLinePageState extends ConsumerState<BillLinePage> {
  late final _name = TextEditingController(text: widget.line?.name);
  late final _note = TextEditingController(text: widget.line?.note);
  late int _cents = widget.line?.amount.cents ?? 0;
  late LineGroup _group = widget.line?.group ?? widget.group;
  late String? _category = widget.line?.categoryId;
  late String? _method = widget.line?.paymentMethodId;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(BudgetPlan plan, String categoryId) async {
    final line = BudgetLine.create(
      id: widget.line?.id ?? ref.read(newIdProvider)(),
      name: _name.text,
      amount: Money.fromCents(_cents),
      group: _group,
      categoryId: categoryId,
      paymentMethodId: _method,
      note: _note.text,
      dueDay: widget.line?.dueDay,
    ).valueOrNull;
    if (line == null) return;
    final navigator = Navigator.of(context);
    await ref.read(planServiceProvider).define(plan.withLine(line));
    navigator.pop();
  }

  Future<void> _delete(BudgetPlan plan, String id) async {
    final navigator = Navigator.of(context);
    await ref.read(planServiceProvider).define(plan.withoutLine(id));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(financesProvider)?.plan ?? BudgetPlan.empty;
    final book = ref.watch(ledgerProvider).value;
    final choices = BillLineChoices(
      categories: book?.categories ?? const [],
      methods: book?.methods ?? const [],
    );
    final category = choices.categoryFor(_group, _category);
    return CajuiScreen(
      title: widget.line == null ? 'Nova conta' : widget.line!.name,
      onBack: Navigator.of(context).pop,
      footer: _footer(plan, category),
      children: _fields(choices, category),
    );
  }

  List<Widget> _fields(BillLineChoices choices, String? category) => [
    CajuiTextField(
      label: 'O que é',
      controller: _name,
      hint: 'Aluguel, Claude, Uber',
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: CajuiSpacing.lg),
    CajuiAmountField(
      label: 'Quanto por mês',
      initialCents: _cents,
      helper: 'Se varia, use o maior. Zero conta só o que for gasto.',
      onChanged: (cents) => setState(() => _cents = cents),
    ),
    const SizedBox(height: CajuiSpacing.lg),
    ...choices.groups(_group, (group) => setState(() => _group = group)),
    ...choices.categoriesOf(_group, category, (id) {
      setState(() => _category = id);
    }),
    ...choices.payments(_method, (id) => setState(() => _method = id)),
    const SizedBox(height: CajuiSpacing.lg),
    CajuiTextField(label: 'Observação', controller: _note),
  ];

  Widget _footer(BudgetPlan plan, String? category) {
    final line = widget.line;
    final canSave = _name.text.trim().isNotEmpty && category != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiButton(
          label: 'Salvar',
          expand: true,
          onPressed: canSave ? () => _save(plan, category) : null,
        ),
        if (line != null)
          CajuiButton(
            label: 'Tirar esta conta',
            variant: CajuiButtonVariant.ghost,
            expand: true,
            onPressed: () => _delete(plan, line.id),
          ),
      ],
    );
  }
}
