import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Os estados do Início. A tela faz `switch` exaustivo sobre eles (ADR-002).
@immutable
sealed class HomeState {
  const new();
}

/// O livro ainda está abrindo.
final class HomeLoading extends HomeState {
  /// Cria o estado de carregamento.
  const new();
}

/// A consulta na web antes de o servidor ter qualquer coisa: o celular ainda
/// não mandou nada.
final class HomeFirstUse extends HomeState {
  /// Cria o estado de consulta vazia.
  const new();
}

/// Há o que mostrar, com ou sem plano.
final class HomeReady extends HomeState {
  /// Cria o estado com a visão [view].
  const new(this.view, {required this.readOnly, this.pendingCaptures = 0});

  /// O que o Início mostra.
  final HomeView view;

  /// Consulta pela web: mostra, mas não grava (RN-906).
  final bool readOnly;

  /// Quantos comprovantes esperam conferência.
  final int pendingCaptures;
}

/// O estado do Início, derivado do livro e da lista "Para conferir". É o
/// ViewModel da tela: ela só lê.
final homeStateProvider = Provider<HomeState>((ref) {
  final view = ref.watch(homeViewProvider);
  final book = ref.watch(ledgerProvider).value;
  if (view == null || book == null) return const HomeLoading();
  final readOnly = !ref.watch(ledgerUplinkProvider).isPaired;
  if (readOnly && !view.hasPlan && book.entries.isEmpty) {
    return const HomeFirstUse();
  }
  return HomeReady(
    view,
    readOnly: readOnly,
    pendingCaptures: ref.watch(pendingCapturesProvider).value?.length ?? 0,
  );
});
