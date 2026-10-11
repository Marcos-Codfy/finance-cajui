import 'package:cajui/src/features/home_widget/application/home_screen.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot_provider.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leva o retrato do livro para a tela inicial do celular (ADR-025).
///
/// O livro muda a cada lançamento, e quase sempre o retrato fica igual —
/// uma correção de descrição não muda o limite. Só o que mudou atravessa o
/// canal: cada publicação redesenha o widget.
class HomeSnapshotPublisher {
  /// Cria o publicador sobre [_screen].
  new(this._screen);

  final HomeScreen _screen;
  HomeSnapshot? _last;

  /// Publica [snapshot], se ele mudou desde a última vez.
  Future<void> publish(HomeSnapshot? snapshot) async {
    if (snapshot == null || snapshot == _last) return;
    _last = snapshot;
    await _screen.publish(snapshot);
  }

  /// Publica o retrato em vigor em [container]: é o que o motor de segundo
  /// plano faz depois de lançar, com o app fechado. Espera o livro e o que
  /// já foi revisto abrirem — sem isso, o retrato sairia sem nada para
  /// revisar e apagaria o aviso de domingo.
  Future<void> publishFrom(ProviderContainer container) async {
    await container.read(ledgerProvider.future);
    await container.read(reviewedEntriesProvider.future);
    await publish(container.read(homeSnapshotProvider));
  }
}
