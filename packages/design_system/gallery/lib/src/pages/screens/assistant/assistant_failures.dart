import 'package:design_system/design_system.dart';

/// As falhas da conversa, com o texto do catálogo de erros no contexto do
/// assistente. Ficam dentro da conversa, logo abaixo da pergunta que
/// falhou: o resto do app não depende da IA.
abstract final class AssistantFailures {
  static void _nothing() {}

  /// `E-AI-01`: a IA não respondeu, ou está fora do ar.
  static CajuiNotice aiDown() => const CajuiNotice(
    what: 'O assistente está fora do ar.',
    meaning: 'Seus números continuam no painel, e lançar funciona normalmente.',
    primaryAction: CajuiNoticeAction(
      label: 'Perguntar de novo',
      onPressed: _nothing,
    ),
  );

  /// `E-AI-02`: o serviço pediu uma pausa.
  static CajuiNotice rateLimited() => const CajuiNotice(
    what: 'Muitas perguntas em pouco tempo.',
    meaning:
        'O serviço de IA pediu uma pausa. Dá para perguntar de novo em 40 '
        'segundos.',
  );

  /// `E-AI-03`: o teto mensal de uso da IA.
  static CajuiNotice outOfTokens() => const CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: 'O uso da IA chegou ao teto de outubro.',
    meaning:
        'A classificação segue pelas regras locais, e a conversa volta no '
        'dia 1º.',
    primaryAction: CajuiNoticeAction(
      label: 'Rever o teto',
      onPressed: _nothing,
    ),
    secondaryAction: CajuiNoticeAction(
      label: 'Ver o consumo',
      onPressed: _nothing,
    ),
  );

  /// `E-NET-01`: a conversa só existe com rede.
  static CajuiNotice offline() => const CajuiNotice(
    what: 'Sem conexão agora.',
    meaning:
        'O assistente só funciona com internet, porque a resposta vem do '
        'servidor. Seus números continuam no painel.',
    primaryAction: CajuiNoticeAction(
      label: 'Tentar de novo',
      onPressed: _nothing,
    ),
  );
}
