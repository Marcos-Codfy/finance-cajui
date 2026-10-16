import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/assistant/context_number.dart';
import 'package:server/src/assistant/context_number_kind.dart';

/// Os números da planilha do dono (ADR-023) no contexto da Juju: o que
/// entra, o que sai por grupo, quanto o vale cobre, se sobra ou falta e
/// quanto ainda se deve. O "pode gastar por semana" saiu em 11/10/2026, a
/// pedido do dono.
///
/// São os mesmos do Início e do Meu mês, feitos pelo domínio (RN-915). O
/// contexto cresce com a existência do plano, não com o tamanho dele: trinta
/// contas fixas viram um número só (RN-912).
abstract final class SheetNumbers {
  /// Os números de [finances] em [today]. Sem plano, só o que se deve: o
  /// gasto do mês já vai por categoria, no resto do contexto.
  static List<ContextNumber> of(Finances finances, LocalDate today) =>
      from(MonthFigures.of(finances, today), today);

  /// Os mesmos números, a partir de [figures] já feitos — os que o celular
  /// manda junto da pergunta, para a Juju dizer o que está na tela dele.
  static List<ContextNumber> from(MonthFigures figures, LocalDate today) => [
    if (figures.hasPlan) ..._month(figures),
    if (figures.owed.isPositive)
      _number(
        'Quanto ainda devo, com as parcelas de cartão',
        figures.owed,
        '$today',
      ),
  ];

  static Iterable<ContextNumber> _month(MonthFigures budget) sync* {
    final period = budget.period;
    ContextNumber plan(String label, Money amount) =>
        _number(label, amount, period, kind: ContextNumberKind.plan);
    yield plan('O que entra no mês, em dinheiro', budget.cashIncome);
    if (budget.voucher.isPositive) {
      yield plan('Vale do mês (só compra comida)', budget.voucher);
    }
    yield plan('Contas fixas do mês', budget.fixedBills);
    yield plan('Assinaturas do mês', budget.subscriptions);
    yield plan(
      'Gastos do dia a dia (o maior entre previsto e gasto)',
      budget.dayToDay,
    );
    yield plan('Parcelas de dívida do mês', budget.debtInstallments);
    if (budget.tithe.isPositive) yield plan('Dízimo do mês', budget.tithe);
    yield plan('Total que sai no mês', budget.totalOut);
    yield plan('Parte que o vale paga', budget.voucherCovered);
    yield plan('O que sai do bolso no mês', budget.outOfPocket);
    yield budget.closes
        ? _number('Sobra do mês', budget.result, period, kind: _projection)
        : _number(
            'Faltam para fechar o mês',
            budget.shortfall,
            period,
            kind: _projection,
          );
  }

  static const ContextNumberKind _projection = ContextNumberKind.projection;

  /// O identificador sai depois, em sequência com o resto do contexto.
  static ContextNumber _number(
    String label,
    Money amount,
    String period, {
    ContextNumberKind kind = ContextNumberKind.fact,
  }) => ContextNumber(
    id: '',
    label: label,
    kind: kind,
    period: period,
    amount: amount,
  );
}
