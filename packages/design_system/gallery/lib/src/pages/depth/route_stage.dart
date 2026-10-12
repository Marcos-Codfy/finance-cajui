import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_stage.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';

/// Um celular com navegação própria, para ver a troca de tela do app
/// (`CajuiPageRoute`) acontecer dentro da moldura, e não na gallery inteira.
///
/// O navegador é só deste palco: abrir e voltar aqui não mexe na página da
/// gallery em volta.
class RouteStage extends StatelessWidget {
  /// Cria o palco.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return DepthStage(
      height: 560,
      child: Navigator(
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (_, _, _) => const _Home(),
        ),
      ),
    );
  }
}

/// A tela de partida: as portas do Início que abrem telas.
class _Home extends StatelessWidget {
  const new();

  static void _open(BuildContext context, String title) {
    Navigator.of(context)
        .push(CajuiPageRoute<void>(builder: (_) => _Detail(title: title)));
  }

  @override
  Widget build(BuildContext context) {
    return CajuiScreen(
      title: 'Outubro',
      footer: CajuiButton(
        label: 'Abrir o Meu mês',
        expand: true,
        onPressed: () => _open(context, 'Meu mês'),
      ),
      children: [
        HomeNumbers.closing().first,
        const CajuiSectionTitle('Seu dinheiro'),
        for (final title in const ['Meu mês', 'Dívidas', 'Mês a mês'])
          CajuiListRow(
            title: title,
            trailing: const CajuiIcon(CajuiIconData.chevronRight),
            semanticLabel: title,
            onPressed: () => _open(context, title),
          ),
      ],
    );
  }
}

/// A tela que chega de longe e assenta. Voltar é o mesmo movimento ao
/// contrário: a câmera recua.
class _Detail extends StatelessWidget {
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return CajuiScreen(
      title: title,
      overline: 'Outubro de 2026',
      onBack: () => Navigator.of(context).pop(),
      children: [
        const CajuiStatCard(
          label: 'Sobra de outubro',
          cents: HomeNumbers.leftover,
          tone: CajuiAmountTone.positive,
          large: true,
        ),
        CajuiCard(
          child: Column(
            children: [
              _line('O que entra', HomeNumbers.income),
              _line('O que sai do bolso', HomeNumbers.outOfPocket),
              _line('Vale do mês', HomeNumbers.voucher),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(String label, int cents) =>
      CajuiListRow(title: label, trailing: CajuiAmountText(cents));
}
