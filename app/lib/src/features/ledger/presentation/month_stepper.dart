import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O mês à vista entre duas setas: a da esquerda volta um mês, a da
/// direita avança.
///
/// A seta sem destino fica apagada, e não some: o mês continua no meio da
/// linha, e quem procura "o próximo" vê que ele ainda não chegou.
class MonthStepper extends StatelessWidget {
  /// Cria a linha do mês [label].
  const new({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  /// O mês por extenso: "setembro de 2026".
  final String label;

  /// Volta um mês. `null` apaga a seta.
  final VoidCallback? onPrevious;

  /// Avança um mês. `null` apaga a seta.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CajuiIconButton(
          icon: CajuiIconData.chevronLeft,
          semanticLabel: 'Mês anterior',
          onPressed: onPrevious,
        ),
        Expanded(child: _month(context)),
        CajuiIconButton(
          icon: CajuiIconData.chevronRight,
          semanticLabel: 'Próximo mês',
          onPressed: onNext,
        ),
      ],
    );
  }

  /// Região viva: quem usa leitor de tela ouve o mês novo ao tocar na seta,
  /// sem ter de voltar o foco para o meio da linha.
  Widget _month(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.typography.title.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
    );
  }
}
