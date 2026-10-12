import 'package:design_system/design_system.dart';

/// A nota de um som na mesa: de que é feito, onde toca e quanto dura.
typedef SoundNote = ({String timbre, String use, int milliseconds});

/// O que a mesa de som diz de cada som. A duração é a do arquivo: os de
/// toque vêm de gravações tratadas, e os outros de
/// `tool/sound/build_sounds.py` (origem de cada um em `assets/CREDITS.md`).
/// O teste da gallery confere que nenhum som ficou sem nota.
abstract final class SoundNotes {
  /// A nota de cada som.
  static const Map<CajuiSound, SoundNote> all = {
    CajuiSound.tap: (
      timbre: 'Clique moderno, com cauda curta',
      use: 'Toque em botão de ação',
      milliseconds: 300,
    ),
    CajuiSound.card: (
      timbre: 'Pop mínimo',
      use: 'Toque em card, linha de lista, opção e barra de gráfico',
      milliseconds: 70,
    ),
    CajuiSound.key: (
      timbre: 'Tique curto e baixo',
      use: 'Cada tecla digitada num campo',
      milliseconds: 24,
    ),
    CajuiSound.toggleOn: (
      timbre: 'Dois toques curtos, brilhantes',
      use: 'Chave ou chip ligado',
      milliseconds: 230,
    ),
    CajuiSound.toggleOff: (
      timbre: 'Os mesmos dois toques, mais graves',
      use: 'Chave ou chip desligado',
      milliseconds: 274,
    ),
    CajuiSound.open: (
      timbre: 'Papel deslizando',
      use: 'Folha inferior e lista de opções abrindo',
      milliseconds: 180,
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
