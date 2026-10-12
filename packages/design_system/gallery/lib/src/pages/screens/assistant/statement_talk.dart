import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/assistant/chat_bubble.dart';
import 'package:gallery/src/pages/screens/assistant/juju_composer.dart';
import 'package:gallery/src/pages/screens/assistant/juju_screen.dart';
import 'package:gallery/src/pages/screens/assistant/statement_sample.dart';

/// Como a conversa do extrato termina.
enum _End { open, later, launched, undone }

/// O extrato conferido com a Juju, de verdade: os botões respondem, a
/// conversa anda e o "Pode lançar" conta o que entra (RN-1112 a RN-1119).
///
/// É interativa de propósito. Numa tela parada, cada fala já respondida
/// apareceria com os botões ainda à vista, o que no app nunca acontece: a
/// fala respondida perde os botões, e a resposta vira uma fala de quem usa.
class StatementTalk extends StatefulWidget {
  /// Cria a conversa; com [launched], ela já abre no fim, com tudo
  /// respondido e lançado.
  const new({this.launched = false, super.key});

  /// Se a conversa abre no fim, depois do "Pode lançar".
  final bool launched;

  @override
  State<StatementTalk> createState() => _StatementTalkState();
}

class _StatementTalkState extends State<StatementTalk> {
  late bool _checked = widget.launched;
  bool _linesOpen = false;
  late String? _kind = widget.launched ? 'Alguém da casa' : null;
  late String? _category = widget.launched ? 'Padaria' : null;
  late _End _end = widget.launched ? _End.launched : _End.open;

  bool get _open => _end == _End.open;

  /// O que entra no lote: os gastos certos e as entradas, mais a linha cuja
  /// categoria foi respondida e o Pix, se ele virou gasto.
  int get _count =>
      StatementSample.sureCount +
      (_category == null ? 0 : 1) +
      (_kind == StatementSample.expense ? 1 : 0);

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // A conversa que abre no fim já nasce lá, sem deslizar até ele: é o fim
    // que a variante mostra.
    if (widget.launched) _followLatest(glide: false);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Cada resposta muda a conversa e a leva até a fala mais nova, como no
  /// app: a pergunta seguinte nasce embaixo, fora da tela.
  void _update(VoidCallback change) {
    setState(change);
    _followLatest();
  }

  void _followLatest({bool glide = true}) => WidgetsBinding.instance
      .addPostFrameCallback((_) => unawaited(_toEnd(glide: glide)));

  Future<void> _toEnd({required bool glide}) async {
    if (!mounted || !_scroll.hasClients) return;
    // No movimento reduzido, a conversa salta para o fim, sem deslizar.
    final reduced = CajuiTheme.of(context).motionLevel == MotionLevel.reduced;
    if (glide && !reduced) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: CajuiDurations.base,
        curve: CajuiCurves.enter,
      );
    }
    // A lista monta só o que está perto da tela: ao chegar no fim que ela
    // conhecia, monta mais um pedaço, e o fim de verdade fica um pouco
    // abaixo. Dois saltos, um por quadro, alcançam o fim de verdade.
    for (var jump = 0; jump < 2; jump++) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  Widget build(BuildContext context) {
    return JujuScreen(
      controller: _scroll,
      footer: _open ? _launch() : const JujuComposer(),
      children: [
        const ChatBubble(StatementSample.file, fromUser: true),
        ChatBubble(StatementSample.summary, speaker: JujuScreen.speaker),
        _market(),
        ..._questions(),
        ..._ending(),
      ],
    );
  }

  /// O bloco Mercado. "Ver as linhas" e "Corrigir" abrem as compras na
  /// própria fala; "Confere" passa para as dúvidas.
  Widget _market() => CajuiChatPrompt(
    StatementSample.market,
    speaker: JujuScreen.speaker,
    rows: _linesOpen ? StatementSample.marketRows : const [],
    actions: _open && !_checked ? _marketActions : const [],
  );

  /// Corrigir também abre as linhas: é nelas que se troca a categoria ou se
  /// tira uma compra do lote. Abertas, "Ver as linhas" sai de cena.
  List<CajuiPromptAction> get _marketActions => [
    (
      label: 'Confere',
      onPressed: () => _update(() => _checked = true),
      primary: true,
    ),
    if (!_linesOpen)
      (label: 'Ver as linhas', onPressed: _openLines, primary: false),
    (label: 'Corrigir', onPressed: _openLines, primary: false),
  ];

  void _openLines() => _update(() => _linesOpen = true);

  /// As dúvidas, uma de cada vez, depois dos blocos. Responder vira uma
  /// fala de quem usa, e a próxima pergunta aparece.
  List<Widget> _questions() {
    final kind = _kind;
    final category = _category;
    return [
      if (_checked) ...[
        const ChatBubble('Confere', fromUser: true),
        _ask(
          StatementSample.kindQuestion,
          StatementSample.kinds,
          current: kind == null,
          onPick: (answer) => _update(() => _kind = answer),
        ),
      ],
      if (kind != null) ...[
        ChatBubble(kind, fromUser: true),
        _ask(
          StatementSample.categoryQuestion,
          StatementSample.categories,
          current: category == null,
          onPick: (answer) => _update(() => _category = answer),
        ),
      ],
      if (category != null) ChatBubble(category, fromUser: true),
    ];
  }

  Widget _ask(
    String question,
    List<String> options, {
    required bool current,
    required ValueChanged<String> onPick,
  }) {
    final live = current && _open;
    return CajuiChatPrompt(
      question,
      speaker: JujuScreen.speaker,
      options: live ? options : const [],
      onOption: live ? onPick : null,
    );
  }

  /// O fim: guardado para depois, lançado com o "Desfazer" ao lado, ou
  /// desfeito.
  List<Widget> _ending() => switch (_end) {
    _End.open => const [],
    _End.later => const [
      ChatBubble(StatementSample.later, speaker: JujuScreen.speaker),
    ],
    _End.launched => [_done(canUndo: true)],
    _End.undone => [
      _done(canUndo: false),
      ChatBubble(StatementSample.undone(_count), speaker: JujuScreen.speaker),
    ],
  };

  Widget _done({required bool canUndo}) => CajuiChatPrompt(
    StatementSample.done(_count),
    speaker: JujuScreen.speaker,
    actions: [
      if (canUndo)
        (
          label: 'Desfazer',
          onPressed: () => _update(() => _end = _End.undone),
          primary: false,
        ),
    ],
  );

  /// O pé da conversa: nada é gravado antes do "Pode lançar", e "Conferir
  /// depois" guarda a leitura sem gravar (RN-1115).
  Widget _launch() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CajuiButton(
        label: StatementSample.launch(_count),
        expand: true,
        onPressed: () => _update(() => _end = _End.launched),
      ),
      const SizedBox(height: CajuiSpacing.sm),
      CajuiButton(
        label: 'Conferir depois',
        variant: CajuiButtonVariant.secondary,
        expand: true,
        onPressed: () => _update(() => _end = _End.later),
      ),
    ],
  );
}
