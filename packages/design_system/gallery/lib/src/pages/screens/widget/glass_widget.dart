import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O widget grande da tela inicial (4×2), como o Android o desenha: o vidro
/// sobre a aurora, as duas esferas de luz, o número, as próximas contas a
/// vencer e os três atalhos.
///
/// É a réplica do `home_widget.xml`, feita só com os componentes do design
/// system: a aurora (`CajuiAurora`), o vidro (`CajuiGlassPanel`) e as
/// esferas (`CajuiOrb`). O número é tocável — no aparelho, ele abre o app
/// com a chegada pelo vidro.
class GlassWidget extends StatelessWidget {
  /// Cria o widget com [label], [amount], [caption] e [bills], como o app
  /// publica.
  const new({
    required this.label,
    required this.amount,
    required this.caption,
    this.bills,
    this.onNumber,
    super.key,
  });

  /// "Sobra de outubro".
  final String label;

  /// O valor já escrito: "R$ 1.312,40".
  final String amount;

  /// A frase de baixo.
  final String caption;

  /// As contas a vencer, nome e dia: ("Aluguel", "vence dia 10"). Vazia, o
  /// widget diz que não há conta a vencer; nula, é o widget de mês novo, que
  /// só pede para abrir o app.
  final List<(String, String)>? bills;

  /// O toque no número.
  final VoidCallback? onNumber;

  @override
  Widget build(BuildContext context) {
    // A altura mínima é a de duas células; com as contas, o vidro cresce
    // com o que tem dentro, em vez de cortar a última linha.
    return CajuiAurora(
      child: Stack(
        children: [
          const Positioned(
            left: 18,
            bottom: 4,
            child: CajuiOrb(size: 22, tone: CajuiOrbTone.vereda),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 172),
            child: _glass(context),
          ),
          // No canto de cima do vidro, do lado dos atalhos: entre o
          // número e os botões ela cobria o fim do rótulo.
          const Positioned(top: 2, right: 4, child: CajuiOrb()),
        ],
      ),
    );
  }

  /// O vidro, a uma margem da aurora, com o número e os atalhos.
  /// O conteúdo vem centrado na altura, como o `center_vertical` do layout
  /// do Android: sem isso, a réplica o colava no alto do vidro.
  Widget _glass(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: CajuiGlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [_number(context), ..._bills(context)],
              ),
            ),
            _shortcuts(context),
          ],
        ),
      ),
    ),
  );

  /// O fio e as contas a vencer, uma por linha; sem conta, a frase que diz
  /// isso. O widget de mês novo não tem a seção.
  List<Widget> _bills(BuildContext context) {
    final bills = this.bills;
    if (bills == null) return const [];
    final light = CajuiTheme.of(context).colors.brand.sheen;
    return [
      Padding(
        padding: const EdgeInsets.only(top: CajuiSpacing.sm, bottom: 4),
        child: SizedBox(
          height: 1,
          child: ColoredBox(color: light.withValues(alpha: 0.2)),
        ),
      ),
      if (bills.isEmpty)
        Text('Nenhuma conta a vencer por agora.', style: _muted(context)),
      for (final (name, day) in bills) _bill(context, name, day),
    ];
  }

  /// Uma conta: o nome à esquerda e o dia à direita.
  Widget _bill(BuildContext context, String name, String day) {
    final muted = _muted(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted.copyWith(
              color: CajuiTheme.of(context).colors.brand.sheen,
            ),
          ),
        ),
        const SizedBox(width: CajuiSpacing.sm),
        // O dia tem teto: num widget estreito, o nome encolhe primeiro,
        // como o `layout_weight` do Android, mas o dia não empurra a linha
        // para fora do vidro.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            day,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
      ],
    );
  }

  /// O texto miúdo sobre o vidro: a luz a 80%.
  TextStyle _muted(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return theme.typography.caption.copyWith(
      color: theme.colors.brand.sheen.withValues(alpha: 0.8),
    );
  }

  Widget _number(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final light = theme.colors.brand.sheen;
    final muted = light.withValues(alpha: 0.8);
    final type = theme.typography;
    return CajuiPressable(
      onPressed: onNumber,
      semanticLabel: '$label: $amount. Abrir o Cajui',
      touch: CajuiTouch.card,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: type.overline.copyWith(color: muted),
          ),
          Text(amount, style: type.amountLarge.copyWith(color: light)),
          // Uma linha, como no aparelho: a segunda ficou para as contas.
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.caption.copyWith(color: muted),
          ),
        ],
      ),
    );
  }

  /// Na ordem do rodapé de Lançamentos: câmera e galeria lado a lado, e o
  /// lançar à mão embaixo, na largura das duas.
  Widget _shortcuts(BuildContext context) {
    final light = CajuiTheme.of(context).colors.brand.sheen;
    Widget button(CajuiIconData icon, String name) => Semantics(
      button: true,
      label: name,
      child: SizedBox.square(
        dimension: 44,
        child: CajuiGlassPanel(
          round: true,
          padding: const EdgeInsets.all(10),
          child: CajuiIcon(icon, color: light),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(CajuiIconData.camera, 'Fotografar comprovante'),
            const SizedBox(width: CajuiSpacing.sm),
            button(CajuiIconData.image, 'Escolher da galeria'),
          ],
        ),
        const SizedBox(height: CajuiSpacing.sm),
        _newEntry(context),
      ],
    );
  }

  /// O "+": a ação principal, cheia na cor de ação, como o "Lançar" do app,
  /// com a borda de luz dos botões de vidro.
  Widget _newEntry(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return Semantics(
      button: true,
      label: 'Novo lançamento',
      child: Container(
        width: 96,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.action.primary,
          borderRadius: const BorderRadius.all(CajuiRadius.pill),
          border: Border.all(color: colors.brand.sheen.withValues(alpha: 0.45)),
        ),
        child: CajuiIcon(CajuiIconData.plus, color: colors.text.onAction),
      ),
    );
  }
}
