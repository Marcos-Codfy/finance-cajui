import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_stage.dart';

/// Um celular com três abas na barra do pé, que trocam orbitando
/// (`CajuiOrbitStack`). Cada aba tem um contador: conte numa, troque de aba
/// e volte — o número continua lá, porque nenhuma aba é desmontada.
class OrbitStage extends StatefulWidget {
  /// Cria o palco.
  const new({super.key});

  @override
  State<OrbitStage> createState() => _OrbitStageState();
}

class _OrbitStageState extends State<OrbitStage> {
  /// As abas: o nome, o ícone e o que guardariam. O app tem as duas
  /// primeiras; a terceira está aqui para a órbita girar para os dois lados.
  static const List<(String, CajuiIconData, String)> _tabs = [
    ('Conversar', CajuiIconData.chat, 'a conversa pela metade'),
    ('Início', CajuiIconData.wallet, 'a rolagem e a página do carrossel'),
    ('Cartões', CajuiIconData.card, 'o cartão aberto na carteira'),
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return DepthStage(
      height: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CajuiOrbitStack(
              index: _tab,
              children: [
                for (final (title, _, keeps) in _tabs)
                  _CounterTab(title: title, keeps: keeps),
              ],
            ),
          ),
          CajuiNavBar(
            destinations: [
              for (final (title, icon, _) in _tabs)
                CajuiNavDestination(icon: icon, label: title),
            ],
            selectedIndex: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
        ],
      ),
    );
  }
}

/// Uma aba com estado próprio: o contador só sobrevive à troca se a aba
/// continuar montada.
class _CounterTab extends StatefulWidget {
  const new({required this.title, required this.keeps});

  final String title;
  final String keeps;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: widget.title,
      children: [
        Text(
          'Numa aba de verdade, o que fica guardado: ${widget.keeps}.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        CajuiCard(
          child: Text(
            '$_count ${_count == 1 ? 'toque' : 'toques'} nesta aba',
            style: theme.typography.title.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
        ),
        const SizedBox(height: CajuiSpacing.lg),
        CajuiButton(
          label: 'Contar mais um',
          variant: CajuiButtonVariant.secondary,
          onPressed: () => setState(() => _count++),
        ),
      ],
    );
  }
}
