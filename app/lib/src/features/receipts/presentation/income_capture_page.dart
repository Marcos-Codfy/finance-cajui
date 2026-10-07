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
/// Vem preenchido com o que foi lido; se a leitura errou e era uma compra,
/// "É uma despesa" leva à conferência de sempre.
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
  bool _ofPlan = false;
  bool _saving = false;

  EntryProposal get _proposal => widget.capture.proposal;

  CaptureViewModel get _capture => ref.read(captureProvider.notifier);

  Future<void> _record() async {
    final on = _on;
    if (on == null) return;
    setState(() => _saving = true);
    final feedback = CajuiFeedbackScope.of(context);
    await ref
        .read(incomeServiceProvider)
        .receiveIncome(
          tender: _tender,
          amount: Money.fromCents(_cents),
          receivedOn: on,
          fromPlan: _ofPlan,
        );
    feedback.saved();
    await _capture.closed(widget.capture);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Dinheiro que entrou',
      onBack: () => _capture.defer(widget.capture),
      footer: _footer(),
      children: [
        Text(
          'Li um comprovante de dinheiro recebido. Ele entra na renda do mês, '
          'e não nos gastos.',
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
        CajuiChip(
          label: 'É a renda do mês',
          selected: _ofPlan,
          onSelected: (_) => setState(() => _ofPlan = !_ofPlan),
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
        onPressed: _capture.treatAsExpense,
      ),
      CajuiButton(
        label: 'Descartar',
        variant: CajuiButtonVariant.ghost,
        expand: true,
        onPressed: () => _capture.discard(widget.capture),
      ),
    ],
  );
}
