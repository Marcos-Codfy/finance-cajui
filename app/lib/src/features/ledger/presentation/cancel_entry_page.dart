import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cancelar um lançamento (RN-208).
///
/// Não existe apagar. A tela diz isso antes de a pessoa confirmar: o
/// lançamento sai das contas, e o registro guarda que ele existiu e por que
/// saiu (RN-995).
class CancelEntryPage extends ConsumerStatefulWidget {
  /// Cria a tela para cancelar [entry].
  const new({required this.entry, super.key});

  /// O lançamento a cancelar.
  final Entry entry;

  /// Abre a tela. Devolve `true` quando o lançamento foi cancelado.
  static Future<bool?> open(BuildContext context, Entry entry) {
    return Navigator.of(
      context,
    ).push<bool>(CajuiPageRoute(builder: (_) => CancelEntryPage(entry: entry)));
  }

  @override
  ConsumerState<CancelEntryPage> createState() => _CancelEntryPageState();
}

class _CancelEntryPageState extends ConsumerState<CancelEntryPage> {
  static const _reasons = [
    'Lancei duas vezes',
    'Não era uma despesa',
    'Lancei errado e vou refazer',
  ];

  String _reason = _reasons.first;
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final feedback = CajuiFeedbackScope.of(context);
    await ref
        .read(ledgerProvider.notifier)
        .cancel(widget.entry.id, reason: _reason);
    feedback.saved();
    navigator.pop(true);
  }

  String get _explanation {
    final amount = BrlFormatter.format(widget.entry.amount.cents);
    return '"${widget.entry.description}", de $amount, sai de todas as contas '
        'do mês. O que foi pago no vale volta ao saldo. O registro guarda que '
        'o lançamento existiu e por que foi cancelado.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Cancelar lançamento',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Cancelar lançamento',
        variant: CajuiButtonVariant.destructive,
        expand: true,
        loading: _saving,
        onPressed: _confirm,
      ),
      children: [
        Text(
          _explanation,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const CajuiSectionTitle('Por que cancelar'),
        _whichReason(),
      ],
    );
  }

  Widget _whichReason() => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final reason in _reasons)
        CajuiChip(
          label: reason,
          selected: _reason == reason,
          onSelected: (_) => setState(() => _reason = reason),
        ),
    ],
  );
}
