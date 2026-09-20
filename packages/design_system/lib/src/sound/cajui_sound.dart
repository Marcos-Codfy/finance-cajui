import 'package:design_system/src/sound/sound_category.dart';

/// Os tokens de som do Cajui.
///
/// São nomeados pelo que significam (`saved`, `notice`), como os tokens de
/// cor — nunca pelo timbre. Trocar o som de "salvo" é trocar um arquivo.
///
/// Repare na ausência: **não existe som de erro.** O aviso é uma nota grave e
/// macia de madeira, que informa sem assustar.
enum CajuiSound {
  /// Toque num controle: batida leve em madeira.
  tap('tap', SoundCategory.touches),

  /// Chave ligada: duas notas de madeira, subindo.
  toggleOn('toggle_on', SoundCategory.touches),

  /// Chave desligada: as mesmas duas notas, descendo.
  toggleOff('toggle_off', SoundCategory.touches),

  /// Folha ou aviso abrindo: papel deslizando.
  open('open', SoundCategory.ambient),

  /// Deslize: palha roçando.
  swipe('swipe', SoundCategory.ambient),

  /// Comprovante recebido: folha de papel.
  receiptIn('receipt_in', SoundCategory.confirmations),

  /// Salvo: sementes rolando e uma batida macia.
  saved('saved', SoundCategory.confirmations),

  /// Aviso: nota grave e macia. É o que o app tem no lugar de um som de erro.
  notice('notice', SoundCategory.confirmations),

  /// Algo deu certo: gota d'água.
  success('success', SoundCategory.confirmations),

  /// Conquista: três notas subindo. O único som acima de 300 ms, e raro.
  achievement('achievement', SoundCategory.confirmations);

  new(this._file, this.category);

  final String _file;

  /// A família a que o som pertence.
  final SoundCategory category;

  /// O caminho do arquivo dentro do pacote.
  String get asset => 'packages/design_system/assets/sounds/$_file.wav';
}
