import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma tela para informar um valor só — a renda do mês, as parcelas de
/// dívida —, com a explicação do que ele é e de como o app o usa.
///
/// Fecha devolvendo o valor em centavos; voltar sem guardar devolve `null`.
class AmountPage extends StatefulWidget {
  /// Cria a tela [title].
  const new({
    required this.title,
    required this.label,
    required this.explanation,
    this.initialCents = 0,
    super.key,
  });

  /// O título da tela.
  final String title;

  /// O rótulo do campo.
  final String label;

  /// O que este valor é, e o que o app faz com ele.
  final String explanation;

  /// O valor que já estava cadastrado.
  final int initialCents;

  /// Abre a tela e espera o valor.
  static Future<int?> open(
    BuildContext context, {
    required String title,
    required String label,
    required String explanation,
    int initialCents = 0,
  }) {
    return Navigator.of(context).push<int>(
      CajuiPageRoute(
        builder: (_) => AmountPage(
          title: title,
          label: label,
          explanation: explanation,
          initialCents: initialCents,
        ),
      ),
    );
  }

  @override
  State<AmountPage> createState() => _AmountPageState();
}

class _AmountPageState extends State<AmountPage> {
  late int _cents = widget.initialCents;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final navigator = Navigator.of(context);
    return CajuiScreen(
      title: widget.title,
      onBack: navigator.pop,
      footer: CajuiButton(
        label: 'Guardar',
        expand: true,
        onPressed: () => navigator.pop(_cents),
      ),
      children: [
        Text(
          widget.explanation,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        CajuiAmountField(
          label: widget.label,
          initialCents: widget.initialCents,
          onChanged: (cents) => _cents = cents,
        ),
      ],
    );
  }
}
