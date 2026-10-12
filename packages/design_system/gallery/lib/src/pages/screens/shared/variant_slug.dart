import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// O estado [label] como pedaço de endereço: "Sem rede" → `sem-rede`.
///
/// É o que vai em `?estado=` — legível, sem acento e sem espaço, para que o
/// link de uma tela num estado possa ir num README ou numa mensagem.
String variantSlug(String label) {
  const plain = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ç': 'c',
  };
  final folded = label
      .toLowerCase()
      .split('')
      .map((letter) => plain[letter] ?? letter)
      .join();
  return folded
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// A posição do estado [slug] em [variants], se algum tiver esse nome.
int? variantIndexOf(List<ScreenVariant> variants, String? slug) {
  if (slug == null) return null;
  final index = variants.indexWhere((v) => variantSlug(v.label) == slug);
  return index < 0 ? null : index;
}
