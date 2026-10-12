import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_location.dart';
import 'package:gallery/src/app/gallery_scope.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_masthead.dart';
import 'package:gallery/src/shell/gallery_nav.dart';
import 'package:gallery/src/shell/gallery_panel.dart';
import 'package:gallery/src/shell/gallery_settings.dart';
import 'package:gallery/src/shell/gallery_stage.dart';
import 'package:gallery/src/shell/gallery_top_bar.dart';

/// Os painéis que se abrem por cima da página.
enum _Panel { pages, settings }

/// A casca da gallery: menu, ajustes e a página aberta.
///
/// Em tela larga o menu fica ao lado, com os ajustes no pé. Em tela
/// estreita, o alto diz onde se está e abre o menu e os ajustes em painéis.
/// Nos dois, o mesmo menu agrupado, e qualquer página fica a dois toques.
class GalleryShell extends StatefulWidget {
  /// Cria a casca com a página de [location] aberta.
  const new({required this.location, required this.onOpen, super.key});

  /// A página aberta.
  final GalleryLocation location;

  /// Abre outra página.
  final GalleryOpen onOpen;

  @override
  State<GalleryShell> createState() => _GalleryShellState();
}

class _GalleryShellState extends State<GalleryShell> {
  _Panel? _panel;

  /// A partir desta largura o menu cabe ao lado sem apertar o conteúdo.
  static const double _wideFrom = 840;
  static const double _navWidth = 272;
  static const double _settingsWidth = 360;

  GalleryDestination get _page => widget.location.page;

  void _open(GalleryDestination page) {
    setState(() => _panel = null);
    widget.onOpen(page);
  }

  void _show(_Panel panel) => setState(() => _panel = panel);

  void _close() => setState(() => _panel = null);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideFrom;
    // O nome da aba acompanha a página: com várias abertas, dá para achar.
    return Title(
      title: '${_page.title} · Cajui design system',
      color: CajuiTheme.of(context).colors.action.primary,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (wide) _wideLayout(context) else _narrowLayout(),
            _overlay(context, wide: wide),
          ],
        ),
      ),
    );
  }

  Widget _stage() => GalleryStage(
    location: widget.location,
    onOpen: (page, {state}) {
      setState(() => _panel = null);
      widget.onOpen(page, state: state);
    },
  );

  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _navWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GalleryMasthead(),
              Expanded(
                child: GalleryNav(selected: _page, onSelect: _open),
              ),
              _SettingsButton(onPressed: () => _show(_Panel.settings)),
            ],
          ),
        ),
        const _Rule(vertical: true),
        Expanded(child: _stage()),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GalleryTopBar(
          page: _page,
          onPages: () => _show(_Panel.pages),
          onSettings: () => _show(_Panel.settings),
        ),
        const _Rule(vertical: false),
        Expanded(child: _stage()),
      ],
    );
  }

  Widget _overlay(BuildContext context, {required bool wide}) {
    final reduced = CajuiTheme.of(context).motionLevel == MotionLevel.reduced;
    return AnimatedSwitcher(
      duration: reduced ? CajuiDurations.reducedFade : CajuiDurations.fast,
      child: switch (_panel) {
        null => const SizedBox.shrink(),
        _Panel.pages => GalleryPanel(
          key: const ValueKey(_Panel.pages),
          title: 'Páginas',
          fill: true,
          onClose: _close,
          child: GalleryNav(selected: _page, onSelect: _open),
        ),
        _Panel.settings => _settings(wide: wide),
      },
    );
  }

  Widget _settings({required bool wide}) => GalleryPanel(
    key: const ValueKey(_Panel.settings),
    title: 'Ajustes',
    width: wide ? _settingsWidth : null,
    onClose: _close,
    child: const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        CajuiSpacing.xl,
        0,
        CajuiSpacing.xl,
        CajuiSpacing.xl,
      ),
      child: GallerySettings(),
    ),
  );
}

/// O pé do menu do computador: os ajustes em vigor, numa linha, e o toque
/// que abre o painel.
class _SettingsButton extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  static const _radius = BorderRadius.all(CajuiRadius.md);

  @override
  Widget build(BuildContext context) {
    final summary = GallerySettings.summaryOf(GalleryScope.of(context));
    return Padding(
      padding: const EdgeInsets.all(CajuiSpacing.lg),
      child: CajuiPressable(
        onPressed: onPressed,
        radius: _radius,
        semanticLabel: 'Ajustes: $summary',
        builder: (context, states) => _face(context, states, summary),
      ),
    );
  }

  Widget _face(BuildContext context, Set<WidgetState> states, String summary) {
    final theme = CajuiTheme.of(context);
    final hovered = states.contains(WidgetState.hovered);
    return Container(
      padding: const EdgeInsets.all(CajuiSpacing.md),
      decoration: BoxDecoration(
        color: hovered ? theme.colors.surface.sunken : null,
        borderRadius: _radius,
        border: Border.all(color: theme.colors.border.subtle),
      ),
      child: Row(
        spacing: CajuiSpacing.md,
        children: [
          CajuiIcon(CajuiIconData.sliders, color: theme.colors.text.muted),
          Expanded(child: _words(theme, summary)),
        ],
      ),
    );
  }

  Widget _words(CajuiThemeData theme, String summary) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ajustes',
        style: theme.typography.label.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
      Text(
        summary,
        style: theme.typography.caption.copyWith(
          color: theme.colors.text.faint,
        ),
      ),
    ],
  );
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
