import 'package:cajui/src/features/budget/presentation/income_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Lançar o que saiu e, ao lado, à vista, registrar o que entrou: a renda
/// avulsa e o saldo moravam escondidos em Minhas contas (16/10/2026).
///
/// Os rótulos são curtos de propósito, e de mesma largura: "Novo lançamento" e
/// "Entrou dinheiro" não cabiam lado a lado na largura do celular e saíam
/// cortados ("Novo lançame…", "Entrou di…", 24/10/2026). "Gastei" e "Recebi"
/// seguem a voz da conversa com a Juju.
class HomeActions extends StatelessWidget {
  /// Cria os dois botões.
  const new({super.key});

  /// Acima disto a fonte do sistema está grande demais para os dois rótulos
  /// lado a lado: eles empilham, cada um com a largura toda.
  static const double _stackFrom = 1.15;

  @override
  Widget build(BuildContext context) {
    final spent = CajuiButton(
      label: 'Gastei',
      icon: CajuiIconData.plus,
      expand: true,
      onPressed: () => EntryFormPage.open(context),
    );
    final received = CajuiButton(
      label: 'Recebi',
      variant: CajuiButtonVariant.secondary,
      expand: true,
      onPressed: () => IncomePage.open(context),
    );
    if (MediaQuery.textScalerOf(context).scale(1) > _stackFrom) {
      return Column(spacing: CajuiSpacing.sm, children: [spent, received]);
    }
    return Row(
      spacing: CajuiSpacing.sm,
      children: [
        Expanded(child: spent),
        Expanded(child: received),
      ],
    );
  }
}
