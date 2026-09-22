/// Quem é o assistente do Cajui.
///
/// **Buriti** — a palmeira das veredas do Cerrado. O ditado do sertão é o
/// resumo do trabalho dele: *onde tem buriti, tem água*. Ele é o sinal de
/// que há reserva, e não o dono dela.
///
/// O nome mora **aqui e só aqui**: o app o usa para se apresentar e para
/// entender quando é chamado, e o servidor o usa nas instruções da IA.
/// Trocá-lo é mudar uma linha.
abstract final class AssistantIdentity {
  /// Como ele se chama.
  static const name = 'Buriti';

  /// Uma frase sobre o que ele é, para quando perguntarem.
  static const about =
      'Sou o $name, o assistente do Cajui. Olho os seus números e respondo '
      'com a conta na mão — nunca com palpite de investimento, e nunca '
      'julgando o seu gasto.';

  /// A pergunta sem o chamado pelo nome.
  ///
  /// "Buriti, quanto sobrou?" e "quanto sobrou?" são a mesma pergunta. Sem
  /// tirar o vocativo, o nome atrapalharia justamente quem se deu ao
  /// trabalho de usá-lo.
  static String withoutVocative(String question) {
    var text = question.trimLeft();
    for (final greeting in _greetings) {
      text = _dropPrefix(text, greeting);
    }
    text = _dropPrefix(text, name);
    return text.replaceFirst(RegExp('^[,:;!?-]+'), '').trimLeft();
  }

  /// Se [question] é só um cumprimento, sem pergunta junto.
  static bool isGreeting(String question) {
    final text = withoutVocative(question)
        .toLowerCase()
        .replaceAll(RegExp('[^a-zà-ú ]'), '')
        .trim();
    return text.isEmpty || _greetings.contains(text);
  }

  static String _dropPrefix(String text, String prefix) {
    if (!text.toLowerCase().startsWith(prefix.toLowerCase())) return text;
    final rest = text.substring(prefix.length);
    // "buritiz" não é o nome; "buriti," e "buriti " são.
    if (rest.isNotEmpty && RegExp('[a-zà-ú]').hasMatch(rest[0])) return text;
    return rest.replaceFirst(RegExp('^[,:;!?-]+'), '').trimLeft();
  }

  static const _greetings = {
    'oi',
    'ola',
    'olá',
    'e aí',
    'e ai',
    'eai',
    'bom dia',
    'boa tarde',
    'boa noite',
    'opa',
    'fala',
    'salve',
  };
}
