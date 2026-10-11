import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso dos nomes da casa (RN-1070): incluir e tirar um nome.
///
/// Cada mudança grava a lista inteira como um fato novo, que atravessa os
/// aparelhos e vale pelo carimbo — o mesmo desenho da ordem das dívidas.
class HouseholdNamesService {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro e o relógio.
  final Ref ref;

  /// Inclui [name]. Nome que não pode entrar (sem sobrenome, repetido, além
  /// do teto) não grava nada.
  Future<void> add(String name) =>
      _change((names, at) => names.adding(name, at));

  /// Tira [name] da lista.
  Future<void> remove(String name) =>
      _change((names, at) => names.removing(name, at));

  Future<void> _change(
    HouseholdNames Function(HouseholdNames names, DateTime at) change,
  ) async {
    final book = await ref.read(ledgerProvider.future);
    final current = book.householdNames;
    final next = change(current, _after(current.definedAt));
    if (identical(next, current)) return;
    await ref.read(ledgerProvider.notifier).append(HouseholdNamed(next));
  }

  /// O carimbo de agora, ou logo depois de [known] se o relógio daqui
  /// estiver atrás (ADR-024): quem muda depois de ver a mudança do outro
  /// aparelho vence, mesmo com o relógio atrasado.
  DateTime _after(DateTime? known) {
    final now = ref.read(clockProvider).now();
    if (known == null || now.isAfter(known)) return now;
    return known.add(const Duration(milliseconds: 1));
  }
}

/// O caso de uso dos nomes da casa.
final householdNamesServiceProvider = Provider<HouseholdNamesService>(
  HouseholdNamesService.new,
);
