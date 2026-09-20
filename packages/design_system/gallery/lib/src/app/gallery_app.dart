import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_controller.dart';
import 'package:gallery/src/app/gallery_scope.dart';
import 'package:gallery/src/shell/gallery_shell.dart';

/// A raiz da gallery: liga as escolhas de quem olha ao tema e ao som.
///
/// É um `WidgetsApp`, não um `MaterialApp`: a gallery prova que o design
/// system se sustenta sozinho, sem tema de terceiros por baixo.
class GalleryApp extends StatefulWidget {
  /// Cria a gallery. Sem [player], toca pelo tocador de verdade.
  const new({this.player, super.key});

  /// O tocador de som. Existe para o teste trocar o áudio real por um mudo.
  final SoundPlayer? player;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  final _controller = GalleryController();
  late final SoundPlayer _player = widget.player ?? AudioplayersSoundPlayer();
  late final _feedback = SoundAndHapticFeedback(player: _player);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncSound);
  }

  /// Os sons só são baixados quando o som é ligado: ele nasce desligado, e
  /// baixar dez arquivos para não tocar nenhum atrasava a abertura à toa.
  /// Som é reforço: se o áudio não carregar, a gallery segue, só que muda.
  Future<void> _preloadSounds() async {
    try {
      await _player.preload();
    } on Exception catch (error) {
      debugPrint('Sons indisponíveis: $error');
    }
  }

  void _syncSound() {
    _feedback.settings = _controller.sound;
    if (_controller.sound.soundEnabled) unawaited(_preloadSounds());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncSound)
      ..dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Cajui · design system',
      color: const Color(0xFFFBF6EE),
      debugShowCheckedModeBanner: false,
      // O campo de texto usa o do Material por dentro, que pede estes textos.
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => GalleryScope(
        controller: _controller,
        player: _player,
        child: _Themed(feedback: _feedback, child: child!),
      ),
      home: const GalleryShell(),
    );
  }
}

/// Aplica o tema escolhido a tudo o que está abaixo, inclusive ao fundo.
class _Themed extends StatelessWidget {
  const new({required this.feedback, required this.child});

  final CajuiFeedback feedback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GalleryScope.of(context).theme;
    return CajuiTheme(
      data: theme,
      child: CajuiFeedbackScope(
        feedback: feedback,
        child: AnimatedContainer(
          duration: CajuiDurations.base,
          color: theme.colors.surface.base,
          child: DefaultTextStyle(
            style: theme.typography.body.copyWith(
              color: theme.colors.text.primary,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
