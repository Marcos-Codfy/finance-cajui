import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Um painel por cima da página: o menu do celular e os ajustes.
///
/// Fecha pelo X, tocando fora, pelo Esc e pelo Voltar do Android. Enquanto
/// aberto, o leitor de tela só lê o painel: a página atrás fica calada.
class GalleryPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onClose();
      },
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onClose,
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

  AlignmentGeometry get _where => fill
      ? Alignment.topCenter
      : width == null
      ? Alignment.bottomCenter
      : Alignment.bottomLeft;

  Widget _sheet(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Focus(
        autofocus: true,
        child: Container(
          width: width ?? double.infinity,
          height: fill ? double.infinity : null,
          margin: EdgeInsets.all(width == null ? 0 : CajuiSpacing.lg),
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
              Flexible(child: child),
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
            title,
            style: theme.typography.title.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
        ),
        CajuiIconButton(
          icon: CajuiIconData.close,
          semanticLabel: 'Fechar $title',
          onPressed: onClose,
        ),
      ],
    ),
  );
}
