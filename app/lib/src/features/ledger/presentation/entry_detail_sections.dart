import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// As seções do detalhe de um lançamento: por onde foi pago e o que já
/// voltou.
///
/// O "por onde" tem seção própria, separada do "o quê" do topo da tela: a
/// forma de pagamento nunca ocupa o lugar da despesa.
abstract final class EntryDetailSections {
  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  /// As linhas de pagamento e, em compra parcelada, as parcelas.
  static List<Widget> payment(LedgerBook book, Entry entry) => [
    const CajuiSectionTitle('Por onde foi pago'),
    for (final line in entry.paymentLines)
      CajuiListRow(
        title: book.methodOf(line.paymentMethodId).name,
        trailing: CajuiAmountText(line.amount.cents),
      ),
    if (entry.installmentPlan case final plan?)
      CajuiListRow(
        title:
            'Em ${plan.installments.length}x de '
            '${_brl(plan.installments.first.amount)}',
        subtitle: 'Cada parcela entra no mês em que a fatura vence',
      ),
  ];

  /// Os estornos do lançamento; nada, quando não houve nenhum.
  static List<Widget> reversals(LedgerBook book, Entry entry, LocalDate today) {
    final back = book.reversedOf(entry.id);
    if (back.isEmpty) return const [];
    return [
      const CajuiSectionTitle('O que voltou'),
      for (final reversal in back)
        CajuiListRow(
          title: 'Voltou por ${_methodName(book, reversal)}',
          subtitle: DateLabels.day(reversal.occurredOn, today: today),
          trailing: CajuiAmountText(
            reversal.line.amount.cents,
            tone: CajuiAmountTone.positive,
          ),
        ),
    ];
  }

  static String _methodName(LedgerBook book, Reversal reversal) =>
      book.methodOf(reversal.line.paymentMethodId).name;
}
