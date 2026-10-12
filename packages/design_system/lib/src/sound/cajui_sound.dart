import 'package:design_system/src/sound/sound_category.dart';

/// Os tokens de som do Cajui.
///
/// São nomeados pelo que significam (`saved`, `notice`), como os tokens de
/// cor — nunca pelo timbre. Trocar o som de "salvo" é trocar um arquivo.
///
/// Repare na ausência: **não existe som de erro.** O aviso é uma nota grave e
/// macia de madeira, que informa sem assustar.
enum CajuiSound {
  /// Toque num botão de ação: um clique moderno, com cauda curta.
  tap('tap', SoundCategory.touches),

  /// Toque num card, numa linha de lista ou numa opção: um pop mínimo.
  card('card', SoundCategory.touches),

  /// Tecla digitada num campo: um tique de poucos milissegundos, baixo, para
  /// não cansar numa frase inteira.
  key('key', SoundCategory.touches),

  /// Chave ou chip ligado: dois toques curtos, brilhantes.
  toggleOn('toggle_on', SoundCategory.touches),

  /// Chave ou chip desligado: os mesmos dois toques, mais graves.
  toggleOff('toggle_off', SoundCategory.touches),

  /// Folha ou aviso abrindo: papel deslizando.
  open('open', SoundCategory.ambient),

  /// Comprovante recebido: folha de papel.
  receiptIn('receipt_in', SoundCategory.confirmations),

  /// Salvo: sementes rolando e uma batida macia.
  saved('saved', SoundCategory.confirmations),

  /// Aviso: nota grave e macia. É o que o app tem no lugar de um som de erro.
  notice('notice', SoundCategory.confirmations),

  /// Algo deu certo: gota d'água.
  success('success', SoundCategory.confirmations),

  /// Conquista: três notas subindo. O único som acima de 300 ms, e raro.
  achievement('achievement', SoundCategory.confirmations),

  /// Lançamento feito: uma semente caindo na cuia, com dois quiques.
  ///
  /// É mais leve que [saved] de propósito: lançar é o gesto mais repetido do
  /// app, e o som dele precisa dar gosto na décima vez do dia.
  entrySaved('entry_saved', SoundCategory.confirmations),

  /// Desfeito: uma folha roçando, que vai e volta.
  undone('undone', SoundCategory.confirmations);

  new(this._file, this.category);

  final String _file;

  /// A família a que o som pertence.
  final SoundCategory category;

  /// O caminho do arquivo dentro do pacote.
  String get asset => 'packages/design_system/assets/sounds/$_file.wav';
}
