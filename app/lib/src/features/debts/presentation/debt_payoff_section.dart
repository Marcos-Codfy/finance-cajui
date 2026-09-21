import 'package:cajui/src/core/format/date_labels.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// A parte da tela que fala em **terminar antes**: o valor para quitar hoje,
/// quando o credor informou (RN-511), e a simulação de pagar um pouco mais
/// por mês (RN-533).
///
/// O Cajui não calcula tabela de juros por conta própria — fingiria uma
/// precisão que não tem. A simulação é sobre o saldo nominal, e o texto diz
/// isso, para ninguém tomá-la por promessa do credor.
abstract final class DebtPayoffSection {
  /// Quanto a mais por mês a simulação oferece testar.
  static const extras = [
    Money.fromCents(5000),
    Money.fromCents(10000),
    Money.fromCents(20000),
  ];

  /// A seção de [debt]; vazia quando a dívida já está quitada.
  static List<Widget> of(Debt debt, {required LocalDate today}) {
    if (debt.isPaidOff) return const [];
    return [
      const CajuiSectionTitle('Terminar antes'),
      if (debt.payoffQuote case final quote?) _quote(quote, today),
      for (final extra in extras) ?_simulated(debt, extra),
    ];
  }

  static Widget _quote(PayoffQuote quote, LocalDate today) {
    final when = DateLabels.long(quote.quotedOn);
    final age = quote.ageOn(today);
    return CajuiListRow(
      title: 'Para quitar hoje',
      subtitle: quote.isStaleOn(today)
          ? 'informado há $age dias — pode ter mudado'
          : 'informado em $when pelo credor',
      trailing: CajuiAmountText(quote.amount.cents),
    );
  }

  /// "Pagando R$ 100,00 a mais por mês, termina 3 meses antes." Linha
  /// nenhuma aparece quando o ritmo novo não muda o prazo.
  static Widget? _simulated(Debt debt, Money extra) {
    final simulation = PayoffSimulation.withExtra(debt, extra);
    if (simulation.monthsSaved <= 0) return null;
    final months = simulation.monthsSaved == 1
        ? '1 mês antes'
        : '${simulation.monthsSaved} meses antes';
    return CajuiListRow(
      title: 'Pagando ${BrlFormatter.format(extra.cents)} a mais por mês',
      subtitle:
          'termina $months, em ${simulation.monthsToPayoff} parcelas — conta '
          'sobre o que falta, sem juros',
    );
  }
}
