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

  /// As regras aprendidas neste aparelho que podem ir à IA como exemplo:
  /// estabelecimento normalizado → categoria. Nunca as de pessoa (RN-1107).
  ///
  /// São as antigas, só deste celular. A classificação usa a memória das
  /// respostas por cima delas (`LearnedRules`, RN-1116).
  Future<Map<String, String>> learnedRules();

  /// As regras aprendidas neste aparelho cuja chave é o nome de uma pessoa
  /// — o Pix para alguém. Valem nas regras do celular e nunca saem dele
  /// (RN-1107).
  Future<Map<String, String>> personalRules();

  /// Aprende que [merchant] é da categoria [categoryId] (RN-763). Aprender
  /// de novo o mesmo estabelecimento troca a regra anterior.
  Future<void> learn({required String merchant, required String categoryId});
}
