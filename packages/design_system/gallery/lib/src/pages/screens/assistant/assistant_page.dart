import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/assistant/assistant_failures.dart';
import 'package:gallery/src/pages/screens/assistant/chat_bubble.dart';
import 'package:gallery/src/pages/screens/assistant/juju_composer.dart';
import 'package:gallery/src/pages/screens/assistant/juju_screen.dart';
import 'package:gallery/src/pages/screens/assistant/statement_sample.dart';
import 'package:gallery/src/pages/screens/assistant/statement_talk.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// A Juju, em todos os estados da matriz de telas, e o extrato conferido
/// com ela.
///
/// Quando a IA não está disponível, o aviso fica dentro da conversa e diz
/// por quê: o resto do app não depende dela.
class AssistantPage extends StatelessWidget {
  /// Cria a página da Juju.
  const new({super.key});

  static const String _juju = JujuScreen.speaker;
  static const _spoken = 'Gastei 35 no mercado';
  static const _question = 'Dá para jantar fora no sábado?';

  /// As três coisas que ela faz bem, as mesmas do app.
  static const List<String> _suggestions = [
    _spoken,
    'Quanto sobra neste mês?',
    'Para onde foi o dinheiro deste mês?',
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: 'Juju, a assistente',
      lead:
          'A tela principal do app: diga o que gastou e ela lança; pergunte '
          'e ela responde com os números do mês na mão. Recebe só totais e '
          'categorias, e responde sem julgar o gasto de ninguém.',
      variants: [
        _conversation(),
        _firstTalk(),
        _answering(),
        CommonVariants.loading('Juju'),
        CommonVariants.serverError('Juju'),
        _failed('IA fora do ar', 'E-AI-01', AssistantFailures.aiDown()),
        _failed('Muitas perguntas', 'E-AI-02', AssistantFailures.rateLimited()),
        _failed('Tokens esgotados', 'E-AI-03', AssistantFailures.outOfTokens()),
        _failed('Sem rede', 'E-NET-01', AssistantFailures.offline()),
        _readOnly(),
        _reading(),
        _statement,
        _launched,
      ],
    );
  }

  static final _statement = ScreenVariant(
    label: 'Extrato pela Juju',
    note:
        'RN-1112 a RN-1115: o resumo, os blocos por categoria e as dúvidas '
        'uma a uma. Os botões respondem: toque e a conversa anda. Nada é '
        'gravado antes de "Pode lançar".',
    builder: (_) => const StatementTalk(),
  );

  static final _launched = ScreenVariant(
    label: 'Extrato lançado',
    note:
        'RN-1118 e RN-1119: o lote gravado e o "Fica assim?", com "Pronto" '
        'e o "Desfazer tudo" num toque.',
    builder: (_) => const StatementTalk(launched: true),
  );

  static ScreenVariant _variant(
    String label,
    String note,
    List<Widget> children, {
    bool canAsk = true,
    bool readOnly = false,
  }) => ScreenVariant(
    label: label,
    note: note,
    builder: (_) => JujuScreen(
      readOnly: readOnly,
      footer: JujuComposer(enabled: canAsk),
      children: children,
    ),
  );

  static ScreenVariant _conversation() => _variant(
    'Com conversa',
    'ADR-021: ela lança e mostra o "Desfazer" ao lado; pergunta respondida '
        'traz o número e a conta, não um conselho.',
    [
      const ChatBubble(_spoken, fromUser: true),
      ChatBubble('Lancei ${_brl(3500)} em Mercado, hoje.', speaker: _juju),
      _UndoRow('Mercado · ${_brl(3500)}'),
      const ChatBubble(_question, fromUser: true),
      ChatBubble(
        'Dá. Sobram ${_brl(HomeNumbers.leftover)} neste mês; um jantar de '
        '${_brl(9000)} ainda deixa ${_brl(HomeNumbers.leftover - 9000)} para '
        'o resto de outubro.',
        speaker: _juju,
      ),
    ],
  );

  static String _brl(int cents) => BrlFormatter.format(cents);

  static ScreenVariant _firstTalk() => _variant(
    'Primeira conversa',
    'Nada de campo vazio: a apresentação e três coisas que ela faz bem, '
        'num toque.',
    [
      const CajuiEmptyState(
        title: 'Oi, eu sou a Juju',
        message:
            'Diga o que gastou e eu lanço. Pergunte, e eu respondo com os '
            'seus números na mão.',
      ),
      const SizedBox(height: CajuiSpacing.lg),
      Wrap(
        spacing: CajuiSpacing.sm,
        runSpacing: CajuiSpacing.sm,
        children: [
          for (final suggestion in _suggestions)
            CajuiChip(label: suggestion, selected: false, onSelected: (_) {}),
        ],
      ),
    ],
  );

  static ScreenVariant _answering() => _variant(
    'Respondendo',
    'Três pontos respirando, não girando. O campo espera a resposta.',
    const [
      ChatBubble(_question, fromUser: true),
      ChatBubble('', thinking: true, speaker: _juju),
    ],
    canAsk: false,
  );

  /// A falha logo abaixo da frase. Um gasto dito ainda pode ser lançado
  /// pela conferência, que funciona sem a IA (RN-1091).
  static ScreenVariant _failed(String label, String code, CajuiNotice notice) =>
      _variant(
        label,
        '$code, do catálogo de erros, no contexto do assistente.',
        [
          const ChatBubble(_spoken, fromUser: true),
          notice,
          const SizedBox(height: CajuiSpacing.sm),
          CajuiButton(
            label: 'Lançar pela conferência',
            icon: CajuiIconData.receipt,
            variant: CajuiButtonVariant.secondary,
            onPressed: () {},
          ),
        ],
      );

  static ScreenVariant _readOnly() => _variant(
    'Consulta pela web',
    'ADR-013: no computador ela responde, mas não lança. Sem câmera nem '
        'galeria no alto.',
    const [
      ChatBubble('Lança um almoço de 32 reais no Pix.', fromUser: true),
      ChatBubble(
        'No computador eu só consulto. Para lançar, use o app no celular — '
        'dá para digitar ou compartilhar o comprovante.',
        speaker: _juju,
      ),
    ],
    readOnly: true,
  );

  static ScreenVariant _reading() => _variant(
    'Extrato: lendo',
    'RN-1100 a RN-1102: o extrato compartilhado do banco abre aqui, e é '
        'lido uma página por vez, com a página dita e o "Parar" à mão.',
    const [
      ChatBubble(StatementSample.file, fromUser: true),
      CajuiChatPrompt(
        StatementSample.reading,
        speaker: _juju,
        actions: [(label: 'Parar', onPressed: _stay, primary: false)],
      ),
    ],
    canAsk: false,
  );

  /// Na vitrine, "Parar" não tem leitura para parar.
  static void _stay() {}
}

/// O que ela lançou, com o "Desfazer" ao lado: um toque, sem pergunta.
class _UndoRow extends StatelessWidget {
  const new(this.what);

  final String what;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              what,
              style: theme.typography.caption.copyWith(
                color: theme.colors.text.muted,
              ),
            ),
          ),
          CajuiButton(
            label: 'Desfazer',
            variant: CajuiButtonVariant.ghost,
            size: CajuiButtonSize.compact,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
