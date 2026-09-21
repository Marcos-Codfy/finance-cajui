import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Os lançamentos do mês.
class EntriesPage extends StatelessWidget {
  /// Cria a tela de lançamentos.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const CajuiScreen(
      title: 'Lançamentos',
      children: [
        CajuiEmptyState(
          title: 'Nada lançado ainda',
          message:
              'Compartilhe um comprovante de qualquer app, ou lance o '
              'primeiro à mão.',
        ),
      ],
    );
  }
}
