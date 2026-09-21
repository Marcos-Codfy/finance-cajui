import 'package:domain/src/voice/voice_guide.dart';

/// O filtro da descrição que a IA sugere para um lançamento (RN-775).
///
/// É o **único texto livre da IA que chega à tela**, e por isso o caminho
/// mais curto para um comprovante malicioso falar com a pessoa pela voz do
/// app — "ligue para 0800… para regularizar". O filtro só deixa passar o que
/// tem cara de nome de compra: curto, numa linha, sem contato e sem ordem.
abstract final class ReceiptDescriptionPolicy {
  /// O teto da descrição.
  static const maxLength = 60;

  // Expressões literais fixas e sem quantificador aninhado (RN-733).
  static final _contact = RegExp(
    r'https?:|www\.|\.com|\.br\b|@|\d{8,}|\b0800\b',
    caseSensitive: false,
  );
  static final _lineBreak = RegExp(r'[\r\n]');
  // Cara de credencial ou de identificador, e não de nome de compra: prefixo
  // de chave, ou um bloco comprido sem nenhum espaço.
  static final _secretLike = RegExp(
    r'\b(?:sk|pk|api|key|token|bearer|senha)[-_: ]|\S{25,}',
    caseSensitive: false,
  );

  /// A descrição [raw] se ela puder ir para a tela; senão `null`, e vale o
  /// estabelecimento lido pelas regras.
  static String? accepted(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty || text.length > maxLength) return null;
    if (_lineBreak.hasMatch(text) || _contact.hasMatch(text)) return null;
    if (_secretLike.hasMatch(text)) return null;
    // Telefone escrito com espaços ou traços também é contato.
    if (text.replaceAll(RegExp(r'[\s().-]'), '').contains(RegExp(r'\d{8,}'))) {
      return null;
    }
    return VoiceGuide.violations(text).isEmpty ? text : null;
  }
}
