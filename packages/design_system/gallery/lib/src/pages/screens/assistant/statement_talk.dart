import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/assistant/chat_bubble.dart';
import 'package:gallery/src/pages/screens/assistant/juju_composer.dart';
import 'package:gallery/src/pages/screens/assistant/juju_screen.dart';
import 'package:gallery/src/pages/screens/assistant/statement_sample.dart';

/// O extrato conferido com a Juju, de verdade: os botões respondem, a
/// conversa anda e o "Pode lançar" conta o que entra (RN-1112 a RN-1119).
///
/// É interativa de propósito. Numa tela parada, cada fala já respondida
/// apareceria com os botões ainda à vista, o que no app nunca acontece: a
/// fala respondida perde os botões, e a resposta vira uma fala de quem usa.
/// A ordem é a do app: o bloco, as dúvidas, o que já estava e o convite a
/// lançar.
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
  String? _pixCategory;
  late String? _category = widget.launched ? 'Padaria' : null;
  late bool? _included = widget.launched ? false : null;
  bool _alreadyOpen = false;
  late bool _launched = widget.launched;

  /// O que a Juju disse em lançamentos já desfeitos.
  final List<String> _history = [];

  final _scroll = ScrollController();

  static bool _counts(String? answer) =>
      answer != null && answer != StatementSample.skip;

  /// O que entra no lote: os gastos certos e as entradas, a linha cuja
  /// categoria foi respondida, o Pix se ele virou gasto com categoria, e as
  /// que já estavam, se a pessoa pediu para incluir.
  int get _count =>
      StatementSample.sureCount +
      (_counts(_category) ? 1 : 0) +
      (_kind == StatementSample.expense && _counts(_pixCategory) ? 1 : 0) +
      (_included ?? false ? StatementSample.alreadyCount : 0);

  bool get _pixDone =>
      _kind != null &&
      (_kind != StatementSample.expense || _pixCategory != null);

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

  /// No app, "Pronto", "Conferir depois" e "Descartar" fecham a conversa,
  /// e a Juju volta ao campo de pergunta. Aqui ela recomeça, para poder ser
  /// vista de novo.
  void _restart() => _update(() {
    _checked = _linesOpen = _alreadyOpen = _launched = false;
    _kind = _pixCategory = _category = null;
    _included = null;
    _history.clear();
  });

  @override
  Widget build(BuildContext context) {
    return JujuScreen(
      controller: _scroll,
      footer: _launched ? const JujuComposer() : _footer(),
      children: [
        const ChatBubble(StatementSample.file, fromUser: true),
        ChatBubble(StatementSample.summary, speaker: JujuScreen.speaker),
        _market(),
        ..._questions(),
        ..._closing(),
      ],
    );
  }

  bool get _live => !_launched;

  /// "Ver as linhas" vira "Esconder as linhas" com a lista aberta.
  CajuiPromptAction _lines(bool open, VoidCallback flip) => (
    label: open ? 'Esconder as linhas' : 'Ver as linhas',
    onPressed: () => _update(flip),
    primary: false,
  );

  /// O bloco Mercado. "Corrigir" abre as compras na própria fala: é nelas
  /// que se troca a categoria ou se tira uma compra do lote.
  Widget _market() => CajuiChatPrompt(
    StatementSample.market,
    speaker: JujuScreen.speaker,
    rows: _linesOpen ? StatementSample.marketRows : const [],
    actions: _live && !_checked
        ? [
            (
              label: 'Confere',
              onPressed: () => _update(() => _checked = true),
              primary: true,
            ),
            _lines(_linesOpen, () => _linesOpen = !_linesOpen),
            (
              label: 'Corrigir',
              onPressed: () => _update(() => _linesOpen = true),
              primary: false,
            ),
          ]
        : const [],
  );

  /// As dúvidas, uma de cada vez, depois dos blocos. O Pix que vira gasto
  /// ganha a pergunta da categoria dele antes da próxima dúvida.
  List<Widget> _questions() => [
    if (_checked) ...[
      const ChatBubble('Confere', fromUser: true),
      ..._ask(StatementSample.kindQuestion, StatementSample.kinds, _kind, (
        answer,
      ) {
        _kind = answer;
      }),
    ],
    if (_kind == StatementSample.expense)
      ..._ask(
        StatementSample.pixQuestion,
        StatementSample.pixCategories,
        _pixCategory,
        (answer) => _pixCategory = answer,
      ),
    if (_pixDone)
      ..._ask(
        StatementSample.categoryQuestion,
        StatementSample.categories,
        _category,
        (answer) => _category = answer,
      ),
  ];

  List<Widget> _ask(
    String question,
    List<String> options,
    String? answer,
    ValueChanged<String> pick,
  ) {
    final live = _live && answer == null;
    return [
      CajuiChatPrompt(
        question,
        speaker: JujuScreen.speaker,
        options: live ? options : const [],
        onOption: live ? (choice) => _update(() => pick(choice)) : null,
      ),
      if (answer != null) ChatBubble(answer, fromUser: true),
    ];
  }

  /// O que já estava, o "tudo conferido", os lançamentos desfeitos e o
  /// fim, com "Pronto" e "Desfazer tudo".
  List<Widget> _closing() {
    final included = _included;
    return [
      if (_category != null) _already(),
      if (included != null) ...[
        ChatBubble(included ? 'Incluir todas' : 'Confere', fromUser: true),
        ChatBubble(StatementSample.ready(_count), speaker: JujuScreen.speaker),
      ],
      for (final said in _history)
        ChatBubble(said, speaker: JujuScreen.speaker),
      if (_launched) ...[
        ChatBubble(StatementSample.done(_count), speaker: JujuScreen.speaker),
        CajuiChatPrompt(
          StatementSample.settle,
          speaker: JujuScreen.speaker,
          actions: [
            (label: 'Pronto', onPressed: _restart, primary: true),
            (label: 'Desfazer tudo', onPressed: _undo, primary: false),
          ],
        ),
      ],
    ];
  }

  Widget _already() => CajuiChatPrompt(
    StatementSample.already,
    speaker: JujuScreen.speaker,
    rows: _alreadyOpen ? StatementSample.alreadyRows : const [],
    actions: _live && _included == null
        ? [
            (
              label: 'Confere',
              onPressed: () => _update(() => _included = false),
              primary: true,
            ),
            _lines(_alreadyOpen, () => _alreadyOpen = !_alreadyOpen),
            (
              label: 'Incluir todas',
              onPressed: () => _update(() => _included = true),
              primary: false,
            ),
          ]
        : const [],
  );

  /// Desfeito, a conversa volta a ficar aberta, com o "Pode lançar" de novo
  /// (RN-1119).
  void _undo() => _update(() {
    _history.addAll([
      StatementSample.done(_count),
      StatementSample.undone(_count),
    ]);
    _launched = false;
  });

  /// O pé da conversa, como o do app: "Pode lançar" sempre à mão, e
  /// "Conferir depois" e "Descartar" lado a lado (RN-1115).
  Widget _footer() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CajuiButton(
        label: StatementSample.launch(_count),
        icon: CajuiIconData.check,
        expand: true,
        onPressed: () => _update(() => _launched = true),
      ),
      const SizedBox(height: CajuiSpacing.sm),
      Row(
        children: [
          for (final label in const ['Conferir depois', 'Descartar'])
            Expanded(
              child: CajuiButton(
                label: label,
                variant: CajuiButtonVariant.ghost,
                expand: true,
                onPressed: _restart,
              ),
            ),
        ],
      ),
    ],
  );
}
