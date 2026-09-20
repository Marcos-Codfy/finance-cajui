import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/components/action_page.dart';
import 'package:gallery/src/pages/components/content_page.dart';
import 'package:gallery/src/pages/components/field_page.dart';
import 'package:gallery/src/pages/components/state_page.dart';
import 'package:gallery/src/pages/screens/capture/capture_page.dart';
import 'package:gallery/src/pages/screens/dashboard/dashboard_page.dart';
import 'package:gallery/src/pages/tokens/colors_page.dart';
import 'package:gallery/src/pages/tokens/contrast_page.dart';
import 'package:gallery/src/pages/tokens/layout_page.dart';
import 'package:gallery/src/pages/tokens/typography_page.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_nav.dart';
import 'package:gallery/src/shell/gallery_toolbar.dart';

/// A casca da gallery: menu, controles e a página aberta.
///
/// Em tela larga o menu fica ao lado; em tela estreita vira uma fileira de
/// chips no topo. A gallery roda no navegador e no aparelho, e nos dois
/// precisa dar para chegar a qualquer página com um toque.
class GalleryShell extends StatefulWidget {
  /// Cria a casca.
  const new({super.key});

  @override
  State<GalleryShell> createState() => _GalleryShellState();
}

class _GalleryShellState extends State<GalleryShell> {
  GalleryDestination _selected = GalleryDestination.values.first;

  /// A partir desta largura o menu cabe ao lado sem apertar o conteúdo.
  static const double _wideFrom = 840;
  static const double _navWidth = 272;

  void _select(GalleryDestination destination) =>
      setState(() => _selected = destination);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideFrom;
    return SafeArea(child: wide ? _wideLayout(context) : _narrowLayout(context));
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _navWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Masthead(),
              Expanded(child: GalleryNav(selected: _selected, onSelect: _select)),
              const Padding(
                padding: EdgeInsets.all(CajuiSpacing.xxl),
                child: GalleryToolbar(),
              ),
            ],
          ),
        ),
        const _Rule(vertical: true),
        Expanded(child: _page(context)),
      ],
    );
  }

  Widget _narrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Masthead(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: CajuiSpacing.xxl),
          child: GalleryToolbar(),
        ),
        _chips(),
        const _Rule(vertical: false),
        Expanded(child: _page(context)),
      ],
    );
  }

  Widget _chips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: CajuiSpacing.xxl,
        vertical: CajuiSpacing.md,
      ),
      child: Row(
        spacing: CajuiSpacing.sm,
        children: [
          for (final destination in GalleryDestination.values)
            CajuiChip(
              label: destination.title,
              selected: destination == _selected,
              onSelected: (_) => _select(destination),
            ),
        ],
      ),
    );
  }

  /// A troca de página é uma fusão curta; com movimento reduzido, mais curta.
  Widget _page(BuildContext context) {
    final reduced = CajuiTheme.of(context).motionLevel == MotionLevel.reduced;
    return AnimatedSwitcher(
      duration: reduced ? CajuiDurations.reducedFade : CajuiDurations.fast,
      child: KeyedSubtree(
        key: ValueKey(_selected),
        child: switch (_selected) {
          GalleryDestination.colors => const ColorsPage(),
          GalleryDestination.contrast => const ContrastPage(),
          GalleryDestination.typography => const TypographyPage(),
          GalleryDestination.layout => const LayoutPage(),
          GalleryDestination.action => const ActionPage(),
          GalleryDestination.content => const ContentPage(),
          GalleryDestination.fields => const FieldPage(),
          GalleryDestination.states => const StatePage(),
          GalleryDestination.dashboard => const DashboardPage(),
          GalleryDestination.capture => const CapturePage(),
        },
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CajuiSpacing.xxl,
        CajuiSpacing.xxl,
        CajuiSpacing.xxl,
        CajuiSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cajui',
            style: theme.typography.headline.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
          Text(
            'Design system · sample navegável',
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const new({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: vertical ? 1 : null,
      height: vertical ? null : 1,
      color: CajuiTheme.of(context).colors.border.subtle,
    );
  }
}
