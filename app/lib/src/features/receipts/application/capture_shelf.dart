import 'package:cajui/src/features/receipts/application/pending_capture.dart';

/// O que a captura guarda no aparelho: a lista "Para conferir" e o que o app
/// aprendeu com as correções.
///
/// Nada daqui conta em indicador (RN-721): captura pendente não é
/// lançamento, e regra aprendida é só atalho para a próxima proposta.
abstract interface class CaptureShelf {
  /// As capturas ainda não conferidas, da mais antiga para a mais nova.
  Future<List<PendingCapture>> pending();

  /// Guarda [capture] para conferir depois.
  Future<void> defer(PendingCapture capture);

  /// Tira a captura [id] da lista: virou lançamento ou foi descartada.
  Future<void> close(String id);

  /// As regras aprendidas: estabelecimento normalizado → categoria.
  Future<Map<String, String>> learnedRules();

  /// Aprende que [merchant] é da categoria [categoryId] (RN-763). Aprender
  /// de novo o mesmo estabelecimento troca a regra anterior.
  Future<void> learn({required String merchant, required String categoryId});
}
