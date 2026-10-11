import 'package:design_system/design_system.dart';

/// A nota de um som na mesa: de que é feito, onde toca e quanto dura.
typedef SoundNote = ({String timbre, String use, int milliseconds});

/// O que a mesa de som diz de cada som. A duração é a do arquivo gerado por
/// `tool/sound/build_sounds.py`; o teste da gallery confere que nenhum som
/// ficou sem nota.
abstract final class SoundNotes {
  /// A nota de cada som.
  static const Map<CajuiSound, SoundNote> all = {
    CajuiSound.tap: (
      timbre: 'Batida leve em madeira oca',
      use: 'Todo toque em botão, chip, cartão e linha',
      milliseconds: 70,
    ),
    CajuiSound.toggleOn: (
      timbre: 'Duas notas de madeira, subindo',
      use: 'Chave ligada',
      milliseconds: 155,
    ),
    CajuiSound.toggleOff: (
      timbre: 'As mesmas duas notas, descendo',
      use: 'Chave desligada',
      milliseconds: 155,
    ),
    CajuiSound.open: (
      timbre: 'Papel deslizando',
      use: 'Folha inferior e lista de opções abrindo',
      milliseconds: 180,
    ),
    CajuiSound.swipe: (
      timbre: 'Palha roçando',
      use: 'Deslizar para dispensar ou trocar de semana',
      milliseconds: 140,
    ),
    CajuiSound.receiptIn: (
      timbre: 'Folha de papel pousando',
      use: 'Comprovante recebido pelo compartilhamento',
      milliseconds: 130,
    ),
    CajuiSound.saved: (
      timbre: 'Sementes rolando e uma batida macia',
      use: 'Lançamento salvo',
      milliseconds: 220,
    ),
    CajuiSound.notice: (
      timbre: 'Nota grave e macia de madeira',
      use: 'Aviso. É o que o app tem no lugar de um som de erro',
      milliseconds: 260,
    ),
    CajuiSound.success: (
      timbre: 'Gota d’água',
      use: 'Sincronizou, fechou o mês, fatura paga',
      milliseconds: 200,
    ),
    CajuiSound.achievement: (
      timbre: 'Três notas subindo',
      use: 'Dívida quitada, meta batida. Raro, e o único acima de 300 ms',
      milliseconds: 580,
    ),
    CajuiSound.entrySaved: (
      timbre: 'Semente caindo na cuia, com dois quiques',
      use: 'Lançamento feito, com pulso leve',
      milliseconds: 260,
    ),
    CajuiSound.undone: (
      timbre: 'Folha roçando, que vai e volta',
      use: 'Desfazer um lançamento, com pulso leve',
      milliseconds: 210,
    ),
  };
}
