import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Os estados do painel. A tela faz `switch` exaustivo sobre eles (ADR-002).
@immutable
sealed class DashboardState {
  const new();
}

/// O livro ainda está abrindo.
final class DashboardLoading extends DashboardState {
  /// Cria o estado de carregamento.
  const new();
}

/// Primeiro uso: nada cadastrado. A tela explica o que vai aparecer e dá o
/// primeiro passo, em vez de mostrar zeros.
final class DashboardFirstUse extends DashboardState {
  /// Cria o estado de primeiro uso.
  const new();
}

/// Há o que mostrar. Sem renda cadastrada, [overview] ainda vale para o que
/// não depende dela; o que depende aparece sem número (RN-604).
final class DashboardReady extends DashboardState {
  /// Cria o estado com a visão do mês [overview].
  const new(this.overview, {this.pendingCaptures = 0});

  /// O mês de relance.
  final MonthOverview overview;

  /// Quantos comprovantes esperam conferência. Não contam em número nenhum
  /// do painel (RN-721), e por isso são ditos à parte.
  final int pendingCaptures;
}

/// O estado do painel, derivado do livro, do dia de hoje e da lista "Para
/// conferir". É o ViewModel desta tela: ela só lê.
final dashboardStateProvider = Provider<DashboardState>((ref) {
  final overview = ref.watch(monthOverviewProvider);
  final book = ref.watch(ledgerProvider).value;
  if (overview == null || book == null) return const DashboardLoading();
  final untouched = book.setup.isEmpty && book.entries.isEmpty;
  if (untouched) return const DashboardFirstUse();
  return DashboardReady(
    overview,
    pendingCaptures: ref.watch(pendingCapturesProvider).value?.length ?? 0,
  );
});
