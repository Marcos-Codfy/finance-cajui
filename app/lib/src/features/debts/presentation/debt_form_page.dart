import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/debts/presentation/debt_form_state.dart';
import 'package:cajui/src/features/debts/presentation/debt_form_view_model.dart';
import 'package:cajui/src/features/debts/presentation/debt_kind_label.dart';
import 'package:cajui/src/features/ledger/presentation/ledger_coordinator.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cadastrar uma dívida (RN-501, RN-1002).
///
/// A ordem das perguntas é a da conversa: a quem se deve e de que tipo. A
/// parcelada pergunta a parcela, quantas são, quantas já foram e quando
/// vence; a conta atrasada e o rotativo perguntam quanto ainda se deve e
/// quanto se paga por mês — que pode ser nada, ainda.
class DebtFormPage extends ConsumerStatefulWidget {
  /// Cria a tela de cadastro.
  const new({super.key});

  @override
  ConsumerState<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  final _creditor = TextEditingController();
  final _note = TextEditingController();
  DebtKind _kind = DebtKind.loan;
  int _cents = 0;
  int _balance = 0;
  int _total = 12;
  int _paid = 0;
  int _dueDay = 10;
  bool _nextIsThisMonth = true;

  @override
  void dispose() {
    _creditor.dispose();
    _note.dispose();
    super.dispose();
  }

  /// A dívida que se mede pelo saldo, e não em parcelas.
  bool get _byBalance => DebtType.of(_kind) != DebtType.installments;

  bool get _isComplete =>
      _creditor.text.trim().isNotEmpty &&
      (_byBalance ? _balance > 0 : _cents > 0);

  void _closeWhenSaved(DebtFormState? before, DebtFormState now) {
    if (now is! DebtFormSaved) return;
    CajuiFeedbackScope.of(context).saved();
    context.back();
  }

  /// Entrega o que foi preenchido ao ViewModel, que grava.
  void _save() {
    unawaited(
      ref.read(debtFormProvider.notifier).save((
        creditor: _creditor.text,
        kind: _kind,
        byBalance: _byBalance,
        amountCents: _cents,
        balanceCents: _balance,
        totalInstallments: _total,
        paidInstallments: _paid,
        dueDay: _dueDay,
        nextIsThisMonth: _nextIsThisMonth,
        note: _note.text,
      )),
    );
  }

  Future<void> _pick(
    String title,
    Iterable<int> options,
    int selected,
    ValueChanged<int> onPicked,
  ) async {
    final picked = await context
        .coordinator(ledgerCoordinatorProvider)
        .pick<int>(
          title: title,
          options: [...options],
          labelOf: (value) => '$value',
          selected: selected,
        );
    if (picked != null) setState(() => onPicked(picked));
  }

  static const _gap = SizedBox(height: CajuiSpacing.lg);

  @override
  Widget build(BuildContext context) {
    ref.listen(debtFormProvider, _closeWhenSaved);
    return CajuiScreen(
      title: 'Cadastrar dívida',
      onBack: context.back,
      footer: _footer(),
      children: [
        CajuiTextField(
          label: 'A quem você deve',
          controller: _creditor,
          hint: 'Empréstimo Banco X',
          maxLength: DeviceFact.maxText,
          onChanged: (_) => setState(() {}),
        ),
        _gap,
        ..._whichKind(),
        _gap,
        if (_byBalance) ..._balanceFields() else ..._installmentFields(),
        _gap,
        CajuiTextField(
          label: 'Observação',
          controller: _note,
          hint: 'Negociar à vista com desconto',
          maxLength: DeviceFact.maxText,
        ),
      ],
    );
  }

  List<Widget> _installmentFields() => [
    CajuiAmountField(
      label: 'Valor da parcela',
      onChanged: (cents) => setState(() => _cents = cents),
    ),
    _gap,
    ..._counts(),
  ];

  /// Conta atrasada e rotativo: o saldo, e o que se paga por mês.
  List<Widget> _balanceFields() => [
    CajuiAmountField(
      label: 'Quanto ainda devo',
      onChanged: (cents) => setState(() => _balance = cents),
    ),
    _gap,
    CajuiAmountField(
      label: 'Quanto pago por mês',
      helper: 'Zero se ainda não paga nada. O saldo cai sozinho a cada mês.',
      onChanged: (cents) => setState(() => _cents = cents),
    ),
    _gap,
    _dueDayField(),
  ];

  List<Widget> _whichKind() => [
    const CajuiFieldLabel('Que tipo de dívida'),
    Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final kind in DebtKindLabel.choosable)
          CajuiChip(
            label: DebtKindLabel.of(kind),
            selected: _kind == kind,
            onSelected: (_) => setState(() => _kind = kind),
          ),
      ],
    ),
  ];

  /// Total de parcelas. Pagas nunca passa do total novo.
  Widget _totalField() => _number(
    label: 'Quantas parcelas ao todo',
    value: '$_total',
    options: _counted(1, 120),
    selected: _total,
    onPicked: (value) {
      _total = value;
      if (_paid > value) _paid = value;
    },
  );

  List<Widget> _counts() => [
    _totalField(),
    _gap,
    _number(
      label: 'Quantas já foram pagas',
      value: '$_paid',
      helper: 'O que já foi pago fica ao lado do que falta',
      options: _counted(0, _total),
      selected: _paid,
      onPicked: (value) => _paid = value,
    ),
    _gap,
    _dueDayField(),
    _gap,
    ..._whenIsNext(),
  ];

  Widget _dueDayField() => _number(
    label: 'Dia do vencimento',
    value: 'dia $_dueDay',
    options: _counted(1, 28),
    selected: _dueDay,
    onPicked: (value) => _dueDay = value,
  );

  Widget _number({
    required String label,
    required String value,
    required Iterable<int> options,
    required int selected,
    required ValueChanged<int> onPicked,
    String? helper,
  }) => CajuiSelectField(
    label: label,
    value: value,
    helper: helper,
    onPressed: () => _pick(label, options, selected, onPicked),
  );

  static Iterable<int> _counted(int from, int to) => [
    for (var value = from; value <= to; value++) value,
  ];

  /// Quando cai a próxima parcela. É o que situa a dívida no calendário sem
  /// pedir a data da primeira, que quase ninguém lembra de cabeça.
  List<Widget> _whenIsNext() => [
    const CajuiFieldLabel('A próxima parcela vence'),
    Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        CajuiChip(
          label: 'Neste mês',
          selected: _nextIsThisMonth,
          onSelected: (_) => setState(() => _nextIsThisMonth = true),
        ),
        CajuiChip(
          label: 'No mês que vem',
          selected: !_nextIsThisMonth,
          onSelected: (_) => setState(() => _nextIsThisMonth = false),
        ),
      ],
    ),
  ];

  Widget _footer() {
    final form = ref.watch(debtFormProvider);
    final problem = form is DebtFormEditing ? form.problem : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null) ...[
          ErrorNotice(
            error: problem,
            onAction: (_) =>
                ref.read(debtFormProvider.notifier).dismissProblem(),
          ),
          const SizedBox(height: CajuiSpacing.md),
        ],
        CajuiButton(
          label: 'Cadastrar',
          expand: true,
          loading: form is DebtFormSaving,
          onPressed: _isComplete ? _save : null,
        ),
      ],
    );
  }
}
