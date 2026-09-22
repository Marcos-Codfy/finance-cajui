import 'package:server/src/auth/secure_random.dart';

/// O código que abre uma sessão de **consulta** no navegador (ADR-008 ·
/// ADR-013).
///
/// É outra coisa do que o código de cadastro, e de propósito. O navegador
/// não ganha identidade nenhuma: não guarda chave, não guarda nada. Quem o
/// autoriza é o celular já cadastrado, que emite um código curto; a web o
/// troca por um token **só de leitura**, que morre com a aba.
///
/// Por isso o prazo é de dois minutos, e não de dez: o código atravessa a
/// distância entre a tela do celular e o teclado do computador, e mais nada.
/// Vive só na memória — servidor reiniciado invalida o que estava em
/// trânsito, que é o comportamento certo para um código deste tamanho.
final class WebCodes {
  /// Cria o gerenciador. O relógio entra para o teste poder envelhecer o
  /// código sem esperar.
  new({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Por quanto tempo um código vale.
  static const validity = Duration(minutes: 2);

  final DateTime Function() _now;
  final Map<String, DateTime> _codes = {};

  /// Emite um código novo. O anterior continua valendo até vencer: quem
  /// pediu dois porque o primeiro sumiu da tela não fica sem nenhum.
  String issue() {
    _forget();
    final code = SecureRandom.code(8);
    _codes[SecureRandom.hash(code)] = _now().add(validity);
    return code;
  }

  /// Consome [code]: devolve se ele valia. Acertando, deixa de existir —
  /// um código, uma sessão.
  bool consume(String code) {
    _forget();
    return _codes.remove(SecureRandom.hash(code.toUpperCase())) != null;
  }

  void _forget() {
    final agora = _now();
    _codes.removeWhere((_, expiresAt) => agora.isAfter(expiresAt));
  }
}
