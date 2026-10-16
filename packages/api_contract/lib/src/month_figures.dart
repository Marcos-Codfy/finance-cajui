import 'package:domain/domain.dart';

/// Os números do mês do jeito que o celular mostra no Início e no Meu mês,
/// mandados junto de cada pergunta à Juju.
///
/// O servidor sabe fazer a mesma conta, com o mesmo domínio, mas só com o
/// que já chegou a ele: um lançamento ou uma mudança na planilha que ainda
/// não sincronizou fazia a Juju dizer uma sobra diferente da que estava na
/// tela (15/10/2026). Com estes números ela responde o que a pessoa vê.
final class MonthFigures {
  /// Os números de um mês já feitos; quem faz é [MonthFigures.of].
  const new({
    required this.period,
    required this.hasPlan,
    required this.cashIncome,
    required this.voucher,
    required this.fixedBills,
    required this.subscriptions,
    required this.dayToDay,
    required this.debtInstallments,
    required this.tithe,
    required this.totalOut,
    required this.voucherCovered,
    required this.outOfPocket,
    required this.result,
    required this.owed,
  });

  /// Os números de [finances] no mês de [today], todos feitos pelo domínio.
  factory of(Finances finances, LocalDate today) {
    final budget = finances.budgetFor(today.budgetMonth);
    return MonthFigures(
      period: '${budget.month}',
      hasPlan: !finances.plan.isEmpty,
      cashIncome: budget.cashIncome,
      voucher: budget.voucher,
      fixedBills: budget.fixedBills,
      subscriptions: budget.subscriptions,
      dayToDay: budget.dayToDay,
      debtInstallments: budget.debtInstallments,
      tithe: budget.tithe,
      totalOut: budget.totalOut,
      voucherCovered: budget.voucherCovered,
      outOfPocket: budget.outOfPocket,
      result: budget.result,
      owed: finances.owedOn(today),
    );
  }

  /// O mês, como o domínio o escreve.
  final String period;

  /// Se a casa já tem planilha; sem ela, só [owed] vale alguma coisa.
  final bool hasPlan;

  /// O que entra no mês, em dinheiro.
  final Money cashIncome;

  /// O vale do mês — outra moeda, nunca somada ao dinheiro (RN-111).
  final Money voucher;

  /// Contas fixas do mês.
  final Money fixedBills;

  /// Assinaturas do mês.
  final Money subscriptions;

  /// O dia a dia: o maior entre o previsto e o gasto.
  final Money dayToDay;

  /// Parcelas de dívida do mês.
  final Money debtInstallments;

  /// Dízimo do mês.
  final Money tithe;

  /// Tudo o que sai no mês.
  final Money totalOut;

  /// A parte que o vale paga.
  final Money voucherCovered;

  /// O que sai do bolso.
  final Money outOfPocket;

  /// O que sobra (ou, negativo, o que falta) no fim do mês.
  final Money result;

  /// Quanto ainda se deve, com as parcelas de cartão.
  final Money owed;

  /// Se o mês fecha.
  bool get closes => !result.isNegative;

  /// Quanto falta para fechar; zero quando fecha.
  Money get shortfall => (-result).orZeroIfNegative;

  /// Os valores em centavos, pelo nome de cada campo.
  Map<String, Money> get _amounts => {
    'cashIncome': cashIncome,
    'voucher': voucher,
    'fixedBills': fixedBills,
    'subscriptions': subscriptions,
    'dayToDay': dayToDay,
    'debtInstallments': debtInstallments,
    'tithe': tithe,
    'totalOut': totalOut,
    'voucherCovered': voucherCovered,
    'outOfPocket': outOfPocket,
    'result': result,
    'owed': owed,
  };

  /// O corpo que vai junto da pergunta.
  Map<String, Object?> toJson() => {
    'period': period,
    'hasPlan': hasPlan,
    for (final MapEntry(:key, :value) in _amounts.entries) key: value.cents,
  };

  /// Lê o que o celular mandou. Qualquer campo faltando ou de outro tipo
  /// devolve nulo, e o servidor volta a usar os números que ele mesmo tem:
  /// a pergunta nunca falha por causa disto.
  static MonthFigures? fromJson(Object? json) {
    if (json is! Map) return null;
    final (period, hasPlan) = (json['period'], json['hasPlan']);
    if (period is! String || period.length > 10 || hasPlan is! bool) {
      return null;
    }
    final cents = <String, Money>{};
    for (final field in _fields) {
      final value = json[field];
      if (value is! int) return null;
      cents[field] = Money.fromCents(value);
    }
    return _figures(period, hasPlan, cents);
  }

  static const List<String> _fields = [
    'cashIncome',
    'voucher',
    'fixedBills',
    'subscriptions',
    'dayToDay',
    'debtInstallments',
    'tithe',
    'totalOut',
    'voucherCovered',
    'outOfPocket',
    'result',
    'owed',
  ];
}

/// Monta os números já lidos e conferidos por [MonthFigures.fromJson].
MonthFigures _figures(String period, bool hasPlan, Map<String, Money> cents) =>
    MonthFigures(
      period: period,
      hasPlan: hasPlan,
      cashIncome: cents['cashIncome']!,
      voucher: cents['voucher']!,
      fixedBills: cents['fixedBills']!,
      subscriptions: cents['subscriptions']!,
      dayToDay: cents['dayToDay']!,
      debtInstallments: cents['debtInstallments']!,
      tithe: cents['tithe']!,
      totalOut: cents['totalOut']!,
      voucherCovered: cents['voucherCovered']!,
      outOfPocket: cents['outOfPocket']!,
      result: cents['result']!,
      owed: cents['owed']!,
    );
