import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/business_time.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/debts/debt.dart';
import 'package:meta/meta.dart';

/// Todas as versões de cada dívida, para que cada dia e cada mês usem a que
/// valia nele (RN-1030 e RN-1040).
///
/// Atualizar o saldo depois de negociar é uma versão nova, e não uma
/// reescrita: setembro continua devendo o que devia em setembro, e a
/// parcela de outubro que venceu antes da negociação continua no mês. Entre
/// aparelhos, vale a versão mais nova pelo carimbo, nunca a que chegou por
/// último (ADR-024).
@immutable
final class DebtVersions {
  /// Agrupa [versions] por dívida, da mais velha à mais nova pelo carimbo;
  /// sem carimbo, a versão conta como a mais velha, e no empate vale a
  /// ordem de chegada. A ordem das dívidas é a do primeiro cadastro.
  factory of(Iterable<Debt> versions) {
    final byId = <String, List<Debt>>{};
    for (final debt in versions) {
      (byId[debt.id] ??= []).add(debt);
    }
    return DebtVersions._({
      for (final MapEntry(:key, :value) in byId.entries) key: _sorted(value),
    });
  }

  const new _(this._byId);

  final Map<String, List<Debt>> _byId;

  /// A versão que vale agora de cada dívida.
  List<Debt> get current => [
    for (final versions in _byId.values) versions.last,
  ];

  /// Cada dívida como valia em [day]. Uma dívida cadastrada num mês depois
  /// do de [day] ainda não existia, e fica de fora.
  List<Debt> on(LocalDate day) => [
    for (final versions in _byId.values)
      if (_existsIn(versions, day.budgetMonth)) _asOf(versions, day),
  ];

  /// Cada dívida como valia no vencimento dela em [month]: a parcela que
  /// venceu antes de uma negociação continua contando no mês.
  List<Debt> forMonth(BudgetMonth month) => [
    for (final versions in _byId.values)
      if (_existsIn(versions, month))
        _asOf(versions, month.dayClamped(versions.last.dueDay)),
  ];

  /// A versão mais nova informada até [day]; antes de toda informação, a
  /// primeira. A parcelada não tem dia informado, e vale sempre a mais nova.
  static Debt _asOf(List<Debt> versions, LocalDate day) {
    var chosen = versions.first;
    for (final version in versions) {
      final since = version.informedOn;
      if (since == null || !since.isAfter(day)) chosen = version;
    }
    return chosen;
  }

  /// Sem carimbo — as gravadas antes dele —, não se sabe quando nasceu, e a
  /// dívida conta em todo mês.
  static bool _existsIn(List<Debt> versions, BudgetMonth month) {
    final born = versions.first.definedAt;
    if (born == null) return true;
    return !BusinessTime.dateOf(born).budgetMonth.isAfter(month);
  }

  static List<Debt> _sorted(List<Debt> versions) {
    final indexed = [...versions.indexed]
      ..sort((a, b) {
        final (ia, da) = a;
        final (ib, db) = b;
        if (da.isNewerThan(db)) return 1;
        if (db.isNewerThan(da)) return -1;
        return ia.compareTo(ib);
      });
    return [for (final (_, debt) in indexed) debt];
  }
}
