import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// A tela enquanto o registro do aparelho abre: o formato do que vem, em
/// vez de branco. Até 16/10/2026 a fatura, o detalhe da dívida e do
/// lançamento e o formulário piscavam vazios na primeira abertura.
class LoadingPage extends StatelessWidget {
  /// Cria a espera com o [title] da tela que vem.
  const new({required this.title, super.key});

  /// O título da tela que vem, já no lugar.
  final String title;

  @override
  Widget build(BuildContext context) => CajuiScreen(
    title: title,
    onBack: context.back,
    children: const [
      CajuiSkeleton(height: 120),
      SizedBox(height: CajuiSpacing.lg),
      CajuiSkeleton(height: 56),
      SizedBox(height: CajuiSpacing.sm),
      CajuiSkeleton(height: 56),
    ],
  );
}
