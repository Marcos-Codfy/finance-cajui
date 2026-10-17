import 'dart:math' as math;

import 'package:design_system/src/components/streaming/money_words.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// Um texto que aparece palavra por palavra, como quem escreve: a resposta
/// do assistente chegando.
///
/// As palavras que ainda não chegaram já ocupam o lugar delas, invisíveis:
/// o balão nasce do tamanho final e nada pula de linha enquanto o texto
/// aparece. Cada palavra surge num esmaecer curto, duas a duas.
///
/// Um toque mostra tudo de uma vez. A resposta inteira nunca leva mais que
/// `CajuiDurations.streamCap`, e no movimento reduzido ela já nasce pronta.
/// O leitor de tela recebe sempre o texto inteiro, desde o começo — nunca
/// pedaços.
///
/// Se [text] crescer pelo fim — a resposta chegando aos poucos da rede —, o
/// que já apareceu fica, e só o novo entra.
class CajuiStreamingText extends StatefulWidget {
  /// Mostra [text] palavra por palavra.
  const new(this.text, {this.style, this.onDone, super.key});

  /// O texto inteiro.
  final String text;

  /// O estilo. Por padrão, o corpo de texto na cor principal.
  final TextStyle? style;

  /// Avisa quando a última palavra apareceu — ou quando o toque pulou.
  final VoidCallback? onDone;

  @override
  State<CajuiStreamingText> createState() => _CajuiStreamingTextState();
}

class _CajuiStreamingTextState extends State<CajuiStreamingText>
    with SingleTickerProviderStateMixin {
  /// Quantas palavras dura o esmaecer de cada uma: a seguinte começa antes
  /// de a anterior terminar, e o texto escorre em vez de piscar.
  static const double _fade = 2;

  late final AnimationController _reveal = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);
  List<String> _words = const [];
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play(from: 0);
  }

  @override
  void didUpdateWidget(CajuiStreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    final kept = widget.text.startsWith(oldWidget.text) ? _shownWords : 0.0;
    _play(from: kept);
  }

  /// Quantas palavras já apareceram por inteiro.
  double get _shownWords =>
      math.max(0, _reveal.value * (_words.length + _fade) - _fade);

  void _play({required double from}) {
    _words = MoneyWords.split(widget.text);
    final total = _words.length + _fade;
    final animate = CajuiTheme.of(context).motionLevel.allowsSpring;
    if (!animate || _words.isEmpty) {
      _reveal.value = 1;
      return;
    }
    // Quem continua de onde parou começa com as palavras já vistas inteiras,
    // e não a meio esmaecer: senão elas piscariam a cada pedaço novo. A
    // primeira palavra nova já começa a meio caminho, emendada nas outras.
    final front = from > 0 ? from + _fade - 1 : 0.0;
    final pace = CajuiDurations.wordStep * math.max(0, _words.length - from);
    _reveal
      ..duration = pace > CajuiDurations.streamCap
          ? CajuiDurations.streamCap
          : pace
      ..forward(from: math.min(front / total, 1));
  }

  /// O aviso de fim sai depois do quadro, nunca no meio dele: no movimento
  /// reduzido o texto termina enquanto ainda está sendo montado, e quem
  /// ouve o aviso costuma mudar o próprio estado — o que, no meio da
  /// montagem, o Flutter recusa.
  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDone?.call();
    });
  }

  void _skip() {
    if (_reveal.isAnimating) _reveal.value = 1;
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final style =
        widget.style ??
        theme.typography.body.copyWith(color: theme.colors.text.primary);
    return GestureDetector(
      onTap: _skip,
      excludeFromSemantics: true,
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) => Text.rich(
          TextSpan(
            children: _spans(style, style.color ?? theme.colors.text.primary),
          ),
          semanticsLabel: widget.text,
        ),
      ),
    );
  }

  /// Cada palavra com a própria opacidade: as que chegaram, inteiras; a que
  /// está chegando, a meio caminho; as que faltam, transparentes no lugar.
  List<TextSpan> _spans(TextStyle style, Color color) {
    final front = _reveal.value * (_words.length + _fade);
    return [
      for (final (index, word) in _words.indexed)
        TextSpan(
          text: word,
          style: style.copyWith(
            fontVariations: MoneyWords.isMoney(_words, index)
                ? MoneyWords.weight
                : null,
            color: color.withValues(
              alpha: color.a * ((front - index) / _fade).clamp(0, 1),
            ),
          ),
        ),
    ];
  }
}
