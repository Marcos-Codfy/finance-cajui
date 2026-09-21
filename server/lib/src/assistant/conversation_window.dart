/// A **janela** da conversa (RN-959): só as trocas mais recentes acompanham
/// cada pergunta. O que saiu da janela não é enviado nem resumido.
///
/// Vive na memória do processo, por sessão, e some quando o servidor
/// reinicia ou a sessão acaba — é o modo "não guardar" da RN-957, o mais
/// conservador. Conversa guardada, com prazo e exclusão, é outra peça, com
/// armazenamento próprio fora do registro de eventos (RN-956).
final class ConversationWindow {
  /// Cria a janela, com lugar para [size] trocas por sessão.
  new({this.size = 8, this.maxSessions = 50});

  /// Quantas trocas ficam por sessão.
  final int size;

  /// Quantas sessões têm janela ao mesmo tempo. Usuário único tem poucas; o
  /// teto existe para a memória não crescer sem limite.
  final int maxSessions;

  final Map<String, List<(String, String)>> _bySession = {};

  /// As trocas recentes da sessão [sessionId], da mais antiga para a mais
  /// nova.
  List<(String question, String answer)> of(String sessionId) =>
      List.unmodifiable(_bySession[sessionId] ?? const []);

  /// Acrescenta a troca à sessão [sessionId].
  void add(String sessionId, String question, String answer) {
    final talk = [...?_bySession.remove(sessionId), (question, answer)];
    if (talk.length > size) talk.removeAt(0);
    _bySession[sessionId] = talk;
    if (_bySession.length > maxSessions) {
      _bySession.remove(_bySession.keys.first);
    }
  }

  /// Esquece a conversa da sessão [sessionId].
  void forget(String sessionId) => _bySession.remove(sessionId);
}
