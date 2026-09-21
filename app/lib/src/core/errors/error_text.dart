import 'package:meta/meta.dart';

/// O que a pessoa lê quando um erro do catálogo acontece: a frase e as
/// saídas oferecidas, da principal para a secundária.
///
/// A frase vem com `{chaves}` no lugar dos valores — o saldo, a data, a
/// categoria —, que só existem na hora do erro. [fill] troca as chaves.
@immutable
class ErrorText {
  /// Cria o texto [message] com as saídas [actions].
  const new(this.message, {this.actions = const []});

  /// A frase do catálogo, ainda com as `{chaves}`.
  final String message;

  /// Os rótulos das saídas. Vazio quando o erro fica sob um campo, que já é
  /// a saída, ou quando só resta esperar uma contagem.
  final List<String> actions;

  static final _placeholder = RegExp(r'\{([^}]+)\}');

  /// Os nomes das chaves que [message] e [actions] pedem.
  Set<String> get placeholders => {
    for (final text in [message, ...actions])
      for (final match in _placeholder.allMatches(text)) match.group(1)!,
  };

  /// A frase desta tela, quando o catálogo traz uma por tela no mesmo código:
  /// "Na captura: … · No assistente: …". [label] é o rótulo da tela — "No
  /// assistente". Erro de frase única volta como está.
  ErrorText inContext(String label) {
    final start = message.indexOf('$label: ');
    if (start < 0) return this;
    final rest = message.substring(start + label.length + 2);
    final next = rest.indexOf(' · N');
    return ErrorText(
      next < 0 ? rest : rest.substring(0, next),
      actions: actions,
    );
  }

  /// O mesmo texto com cada `{chave}` trocada pelo valor dela em [values].
  ///
  /// Chave sem valor é defeito de quem chama, e o teste da tela pega. Em
  /// produção ela vira reticências: melhor uma frase com lacuna do que uma
  /// tela que cai por causa de um texto.
  ErrorText fill(Map<String, String> values) {
    String replace(String text) => text.replaceAllMapped(_placeholder, (match) {
      final value = values[match.group(1)];
      assert(value != null, 'Faltou o valor de {${match.group(1)}}.');
      return value ?? '…';
    });
    return ErrorText(replace(message), actions: actions.map(replace).toList());
  }
}
