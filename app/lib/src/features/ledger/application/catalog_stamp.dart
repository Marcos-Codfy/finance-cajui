/// Quando o cadastro de fábrica — as categorias do `DefaultCatalog` — mudou
/// pela última vez (ADR-024).
///
/// As categorias nascem do código, e não de uma tela: o carimbo delas é o
/// da versão do app que as trouxe. Quem muda uma categoria de lugar — de
/// bloco, de grupo, de "o vale paga" — **sobe este carimbo junto**. É ele
/// que faz a versão nova passar por cima da que o servidor tem, e que
/// impede o celular ainda com o APK velho de desfazê-la. O teste
/// `catalog_stamp_test.dart` reprova a mudança que esquecer.
abstract final class CatalogStamp {
  /// O dia da última mudança no cadastro de fábrica, em UTC.
  /// Subiu duas vezes no mesmo dia: a sincronia ao vivo trouxe o carimbo,
  /// e a planilha (ADR-023) trouxe "Outra conta fixa" e "Assinaturas".
  static final DateTime definedAt = DateTime.utc(2026, 10, 11, 9);
}
