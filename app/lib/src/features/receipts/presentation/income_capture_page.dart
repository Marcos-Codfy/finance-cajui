import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/presentation/date_section.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um comprovante de dinheiro que **entrou**: Pix recebido, transferência
/// para a pessoa. Vira recebimento, nunca despesa (RN-758).
///
/// Vem preenchido com o que foi lido, e já diz se parece a renda do mês: o
/// salário que entra como avulso conta por cima do esperado, e a renda do
/// mês dobra. Se a leitura errou e era uma compra, "É uma despesa" leva à
/// conferência de sempre.
class IncomeCapturePage extends ConsumerStatefulWidget {
  /// Cria a tela de [capture].
  const new({required this.capture, super.key});

  /// O comprovante lido.
  final Capture capture;

  @override
  ConsumerState<IncomeCapturePage> createState() => _IncomeCapturePageState();
}

class _IncomeCapturePageState extends ConsumerState<IncomeCapturePage> {
  late int _cents = _proposal.amount.value?.cents ?? 0;
  late LocalDate? _on =
      _proposal.occurredOn.value ?? widget.capture.source.receivedOn;
  late Tender _tender = _proposal.paymentKind.value?.tender ?? Tender.cash;
  // O salário que o valor e o dia parecem ser (RN-758); nulo é avulsa.
  late String? _salaryId = _looksLike()?.id;
  bool _saving = false;

  EntryProposal get _proposal => widget.capture.proposal;

  bool get _inDoubt => _proposal.documentKind.value == null;

  CaptureViewModel get _vm => ref.read(captureProvider.notifier);

  String get _intro => _inDoubt
      ? 'Parece um comprovante de dinheiro recebido, mas não tenho certeza. '
            'Se for, ele entra na renda do mês, e não nos gastos.'
      : 'Li um comprovante de dinheiro recebido. Ele entra na renda do mês, '
            'e não nos gastos.';

  IncomeSource? _looksLike() {
    final on = _on;
    final finances = ref.read(financesProvider);
    if (on == null || finances == null || _cents == 0) return null;
    return finances.salaryLike(Money.fromCents(_cents), on);
  }

  List<IncomeSource> get _salaries =>
      ref.read(financesProvider)?.plan.salaries ?? const [];

  Future<void> _record() async {
    final on = _on;
    if (on == null) return;
    // Lidos antes de esperar: a tela pode sair enquanto grava.
    final capture = _vm;
    final income = ref.read(incomeServiceProvider);
    final feedback = CajuiFeedbackScope.of(context);
    setState(() => _saving = true);
    try {
      await income.receiveIncome(
        tender: _tender,
        amount: Money.fromCents(_cents),
        receivedOn: on,
        salaryId: _salaryId,
        id: widget.capture.source.id,
      );
      feedback.saved();
      await capture.closed(widget.capture);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: _inDoubt ? 'Dinheiro que entrou?' : 'Dinheiro que entrou',
      onBack: _saving ? null : () => _vm.defer(widget.capture),
      footer: _footer(),
      children: [
        Text(
          _intro,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        CajuiAmountField(
          label: 'Valor',
          initialCents: _cents,
          onChanged: (cents) => setState(() => _cents = cents),
        ),
        const SizedBox(height: CajuiSpacing.lg),
        DateSection(
          selected: _on,
          today: ref.watch(clockProvider).today(),
          onChanged: (day) => setState(() => _on = day),
        ),
        const SizedBox(height: CajuiSpacing.lg),
        _choices(),
      ],
    );
  }

  /// Em que moeda entrou, e se é a renda do mês ou uma entrada avulsa.
  Widget _choices() => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final (tender, label) in const [
        (Tender.cash, 'Na conta'),
        (Tender.mealVoucher, 'No vale'),
      ])
        CajuiChip(
          label: label,
          selected: _tender == tender,
          onSelected: (_) => setState(() => _tender = tender),
        ),
      if (_tender == Tender.cash)
        for (final salary in _salaries)
          CajuiChip(
            label: 'Salário · ${salary.name}',
            selected: _salaryId == salary.id,
            // Tocar de novo desmarca: vira dinheiro extra do mês.
            onSelected: (_) => setState(
              () => _salaryId = _salaryId == salary.id ? null : salary.id,
            ),
          ),
    ],
  );

  Widget _footer() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CajuiButton(
        label: 'Registrar entrada',
        expand: true,
        loading: _saving,
        onPressed: _cents > 0 && _on != null && !_saving ? _record : null,
      ),
      const SizedBox(height: CajuiSpacing.sm),
      CajuiButton(
        label: 'É uma despesa',
        variant: CajuiButtonVariant.secondary,
        expand: true,
        onPressed: _saving ? null : _vm.treatAsExpense,
      ),
      CajuiButton(
        label: 'Descartar',
        variant: CajuiButtonVariant.ghost,
        expand: true,
        onPressed: _saving ? null : () => _vm.discard(widget.capture),
      ),
    ],
  );
}
