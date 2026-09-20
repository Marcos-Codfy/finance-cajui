import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/assistant/chat_bubble.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// O assistente, em todos os estados da matriz de telas.
///
/// Quando a IA não está disponível, o campo de pergunta fica inativo e o
/// aviso diz por quê: o resto do app não depende dela.
class AssistantPage extends StatelessWidget {
  /// Cria a página do assistente.
  const new({super.key});

  static const _title = 'Assistente';
  static const _question = 'Dá para jantar fora no sábado?';
  static const _suggestions = [
    'Quanto dá para gastar nesta semana?',
    'Para onde foi o dinheiro de setembro?',
    'Quando eu quito o empréstimo?',
  ];

  static String _brl(int cents) => BrlFormatter.format(cents);

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: 'Assistente',
      lead:
          'Conversa sobre os números do mês. Recebe só totais e categorias, '
          'nunca o comprovante; responde sem julgar o gasto de ninguém.',
      variants: [
        _conversation(),
        CommonVariants.loading(_title),
        CommonVariants.serverError(_title),
        _empty(),
        _answering(),
        _blocked('IA fora do ar', 'E-AI-01', _aiDown()),
        _blocked('Muitas perguntas', 'E-AI-02', _rateLimited()),
        _blocked('Tokens esgotados', 'E-AI-03', _outOfTokens()),
        _blocked('Sem rede', 'E-NET-01', _offline()),
        _readOnly(),
      ],
    );
  }

  ScreenVariant _variant(
    String label,
    String note,
    List<Widget> children, {
    bool canAsk = true,
  }) {
    return ScreenVariant(
      label: label,
      note: note,
      builder: (_) => MockScreen(
        title: _title,
        footer: _Composer(enabled: canAsk),
        children: children,
      ),
    );
  }

  ScreenVariant _blocked(String label, String code, CajuiNotice notice) =>
      _variant(label, '$code, do catálogo de erros.', [
        const ChatBubble(_question, fromUser: true),
        notice,
      ], canAsk: false);

  ScreenVariant _conversation() => _variant(
    'Com conversa',
    'A resposta traz o número e a conta, não um conselho.',
    [
      const ChatBubble(_question, fromUser: true),
      ChatBubble(
        'Dá. Você tem ${_brl(14027)} livres nesta semana; um jantar de '
        '${_brl(9000)} ainda deixa ${_brl(5027)} até domingo.',
      ),
    ],
  );

  ScreenVariant _empty() => _variant(
    'Vazia, com sugestões',
    'Primeira conversa: três perguntas que o app sabe responder bem.',
    [
      const CajuiEmptyState(
        title: 'Pergunte sobre o seu mês',
        message: 'Eu olho os seus números e respondo com a conta na mão.',
      ),
      const SizedBox(height: CajuiSpacing.lg),
      CajuiOptionList<String>(
        options: _suggestions,
        labelOf: (suggestion) => suggestion,
        onSelected: (_) {},
      ),
    ],
  );

  ScreenVariant _answering() => _variant(
    'Respondendo',
    'Três pontos respirando, não girando. O campo espera a resposta.',
    const [
      ChatBubble(_question, fromUser: true),
      ChatBubble('', thinking: true),
    ],
    canAsk: false,
  );

  CajuiNotice _aiDown() => CajuiNotice(
    what: 'O assistente está fora do ar.',
    meaning:
        'Seus números continuam no painel, e lançar funciona normalmente.',
    primaryAction: CajuiNoticeAction(
      label: 'Perguntar de novo',
      onPressed: () {},
    ),
  );

  CajuiNotice _rateLimited() => const CajuiNotice(
    what: 'Muitas perguntas em pouco tempo.',
    meaning:
        'O serviço de IA pediu uma pausa. Dá para perguntar de novo em 40 '
        'segundos.',
  );

  CajuiNotice _outOfTokens() => CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: 'O uso da IA chegou ao teto de setembro.',
    meaning:
        'A classificação segue pelas regras locais, e a conversa volta no '
        'dia 1º.',
    primaryAction: CajuiNoticeAction(label: 'Rever o teto', onPressed: () {}),
    secondaryAction: CajuiNoticeAction(
      label: 'Ver o consumo',
      onPressed: () {},
    ),
  );

  CajuiNotice _offline() => const CajuiNotice(
    what: 'Sem conexão agora.',
    meaning:
        'O assistente só funciona com internet, porque a resposta vem do '
        'servidor. Seus números continuam no painel.',
  );

  ScreenVariant _readOnly() => _variant(
    'Modo consulta (web)',
    'No computador o assistente responde, mas não lança.',
    const [
      ChatBubble('Lança um almoço de 32 reais no Pix.', fromUser: true),
      ChatBubble(
        'No computador eu só consulto. Para lançar, use o app no celular — '
        'dá para digitar ou compartilhar o comprovante.',
      ),
    ],
  );
}

class _Composer extends StatelessWidget {
  const new({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CajuiTextField(
            label: 'Sua pergunta',
            hint: 'Pergunte sobre o seu mês',
            enabled: enabled,
          ),
        ),
        const SizedBox(width: CajuiSpacing.sm),
        CajuiIconButton(
          icon: CajuiIconData.chevronRight,
          semanticLabel: 'Enviar a pergunta',
          variant: CajuiButtonVariant.primary,
          onPressed: enabled ? () {} : null,
        ),
      ],
    );
  }
}
