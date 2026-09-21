import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Um lançamento na lista.
///
/// O título é **o que foi comprado**; o subtítulo diz a categoria, **por onde
/// foi pago** e quando. É a regra central do produto na estrutura da linha:
/// a forma de pagamento nunca ocupa o lugar da despesa.
class EntryRow extends StatelessWidget {
  /// Cria a linha de [entry], com os nomes tirados de [book].
  const new({
    required this.entry,
    required this.book,
    required this.today,
    super.key,
  });

  /// O lançamento.
  final Entry entry;

  /// O livro, de onde saem os nomes de categoria e de forma de pagamento.
  final LedgerBook book;

  /// O dia de hoje, para dizer "hoje" e "ontem".
  final LocalDate today;

  /// "Vale alimentação + Pix" para pagamento dividido.
  String get _paidWith => entry.paymentLines
      .map((line) => book.methodOf(line.paymentMethodId).name)
      .join(' + ');

  @override
  Widget build(BuildContext context) {
    final category = book.categoryOf(entry.categoryId).name;
    final day = DateLabels.day(entry.occurredOn, today: today);
    return CajuiListRow(
      title: entry.description,
      subtitle: '$category · $_paidWith · $day',
      trailing: CajuiAmountText(entry.amount.cents),
    );
  }
}
