/// A conferência de valores da RN-943: todo valor em reais que a Juju escreve
/// precisa existir no resumo do mês, no que uma ferramenta devolveu ou na
/// própria pergunta.
///
/// Existe porque o modelo, ao converter centavos e ao somar de cabeça,
/// escrevia valores que ninguém lhe deu: com a sobra do mês de R$ 1.206,40 no
/// resumo, respondeu "sobram R$ 123,45" (22/10/2026). Número errado dito com
/// segurança é pior que "não sei".
abstract final class AmountCheck {
  static final _written = RegExp(
    r'R\$\s*(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?',
  );
  static final _typed = RegExp(r'(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?');

  /// Os valores em reais escritos em [text] (`R$ 1.206,40`), em centavos.
  static List<int> writtenIn(String text) => [
    for (final match in _written.allMatches(text)) _cents(match[1]!, match[2]),
  ];

  /// Os números que a pessoa digitou em [message], lidos como reais: "gastei
  /// 35,50" cita 3550 centavos.
  static Set<int> typedIn(String message) => {
    for (final match in _typed.allMatches(message)) _cents(match[1]!, match[2]),
  };

  /// Os valores de [text] que não estão em [known]. Zero sempre vale.
  static List<int> unknownIn(String text, Set<int> known) => [
    for (final cents in writtenIn(text))
      if (cents != 0 && !known.contains(cents)) cents,
  ];

  /// Cada número inteiro de [json] — mapas e listas inclusive. É de propósito
  /// largo: um inteiro que não é dinheiro só deixa passar o valor igual a ele,
  /// e o que se quer barrar é o valor que não existe em lugar nenhum.
  static Set<int> intsIn(Object? json) => switch (json) {
    final int value => {value},
    final Map<Object?, Object?> map => {
      for (final value in map.values) ...intsIn(value),
    },
    final Iterable<Object?> list => {for (final item in list) ...intsIn(item)},
    _ => const {},
  };

  static int _cents(String whole, String? fraction) {
    final reais = int.parse(whole.replaceAll('.', ''));
    final cents = fraction == null ? 0 : int.parse(fraction.padRight(2, '0'));
    return reais * 100 + cents;
  }
}
