import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Um painel por cima da página: o menu do celular e os ajustes.
///
/// Fecha pelo X, tocando fora, pelo Esc e pelo Voltar do Android. Enquanto
/// aberto, o leitor de tela só lê o painel, e o foco do teclado fica nele;
/// ao fechar, o foco volta para o botão que o abriu.
class GalleryPanel extends StatefulWidget {
  /// Cria o painel [title] com [child], fechado por [onClose].
  ///
  /// Com [fill], ocupa a altura toda, do alto para baixo (o menu); sem ele,
  /// sobe do pé, só da altura do conteúdo (os ajustes). Com [width], fica
  /// nessa largura, encostado à esquerda — no computador, ao lado do menu.
  const new({
    required this.title,
    required this.child,
    required this.onClose,
    this.fill = false,
    this.width,
    super.key,
  });

  /// O nome do painel, lido pelo leitor de tela ao abrir.
  final String title;

  /// O conteúdo.
  final Widget child;

  /// Fecha o painel.
  final VoidCallback onClose;

  /// Se ocupa a altura toda.
  final bool fill;

  /// Largura fixa; sem ela, a largura da janela.
  final double? width;

  @override
  State<GalleryPanel> createState() => _GalleryPanelState();
}

class _GalleryPanelState extends State<GalleryPanel> {
  final _scope = FocusScopeNode(debugLabel: 'Painel da gallery');

  /// Quem tinha o foco antes de abrir: o botão "Ajustes" ou "Páginas".
  FocusNode? _before;

  /// O foco é pedido de propósito, e não com `autofocus`: o `autofocus` é
  /// ignorado quando já há algo focado — justamente o caso de quem abriu
  /// pelo teclado —, e aí o Esc não fechava e o Tab fugia para trás do véu.
  @override
  void initState() {
    super.initState();
    _before = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scope.requestFocus();
    });
  }

  @override
  void dispose() {
    _scope.dispose();
    final before = _before;
    // No quadro seguinte: neste, a casca ainda mantém o fundo sem foco.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (before != null && before.context != null) before.requestFocus();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onClose();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: widget.onClose,
              child: ColoredBox(color: colors.surface.scrim),
            ),
            Align(
              alignment: _where,
              child: BlockSemantics(child: _sheet(context)),
            ),
          ],
        ),
      ),
    );
  }

  AlignmentGeometry get _where => widget.fill
      ? Alignment.topCenter
      : widget.width == null
      ? Alignment.bottomCenter
      : Alignment.bottomLeft;

  Widget _sheet(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: widget.title,
      child: FocusScope(
        node: _scope,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.fill ? double.infinity : null,
          margin: EdgeInsets.all(widget.width == null ? 0 : CajuiSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colors.surface.elevated,
            borderRadius: const BorderRadius.all(CajuiRadius.xl),
            boxShadow: CajuiShadows.overlay,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(theme),
              Flexible(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(CajuiThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(
      CajuiSpacing.xl,
      CajuiSpacing.md,
      CajuiSpacing.sm,
      CajuiSpacing.sm,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: theme.typography.title.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
        ),
        CajuiIconButton(
          icon: CajuiIconData.close,
          semanticLabel: 'Fechar ${widget.title}',
          onPressed: widget.onClose,
        ),
      ],
    ),
  );
}
