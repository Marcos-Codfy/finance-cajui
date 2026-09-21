import 'package:cajui/src/features/ledger/application/ledger_event.dart';

/// Onde os fatos do livro ficam guardados.
///
/// É uma porta: a aplicação não sabe se por trás há um arquivo cifrado no
/// Android ou só a memória do navegador. Trocar um pelo outro não toca em
/// nenhuma regra.
abstract interface class LedgerJournal {
  /// Os fatos já gravados, na ordem em que aconteceram.
  Future<List<LedgerEvent>> readAll();

  /// Grava [event] no fim do registro. Só volta depois de gravado: quem
  /// chama pode dizer "salvo" sem mentir.
  Future<void> append(LedgerEvent event);
}
