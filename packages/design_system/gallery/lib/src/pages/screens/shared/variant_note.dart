/// A nota de um estado separada da regra que a define.
///
/// As notas são escritas com a regra na frente — "RN-441: lançamento tardio
/// gera revisão" — para que, no código, cada estado aponte para a
/// especificação. Para quem lê a gallery, o código no meio da frase era
/// anotação interna esquecida. A página mostra a frase limpa e a regra numa
/// linha à parte, mais apagada.
typedef VariantNote = ({String text, String? rule});

/// Um código da especificação: regra (RN-441), decisão (ADR-017), erro do
/// catálogo (E-SRV-01, E-CAPT-05) ou decisão de pesquisa (D-UX-22).
const _code = r'(?:RN|ADR|D-UX|E-[A-Z]+)-\d+';

/// Um ou mais códigos no começo, ligados por "a", "e" ou vírgula, seguidos
/// de dois-pontos ou de ponto médio.
final _leading = RegExp(
  '^($_code(?:(?:,| a| e) $_code)*)\\s*[:·]\\s*',
);

/// Um código entre parênteses no meio da frase: "(RN-441)".
final _inline = RegExp('\\s*\\(($_code)\\)');

/// Separa a regra da frase de [note].
VariantNote splitRule(String note) {
  final rules = <String>[];
  var text = note.replaceAllMapped(_inline, (match) {
    rules.add(match.group(1)!);
    return '';
  });
  final leading = _leading.firstMatch(text);
  if (leading != null) {
    rules.insert(0, leading.group(1)!);
    text = text.substring(leading.end);
  }
  if (text.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);
  return (text: text, rule: rules.isEmpty ? null : rules.join(' · '));
}
