import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Mês a mês", como a aba da planilha: quanto entrou, quanto saiu, se
/// sobrou ou faltou e quanto ainda se devia, de cada mês.
///
/// Ninguém fecha o mês aqui. Os números são calculados dos mesmos fatos a
/// qualquer hora, e um lançamento atrasado corrige o mês dele sozinho
/// (RN-1040).
class MonthHistoryPage extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const MonthHistoryPage()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finances = ref.watch(financesProvider);
    final month = ref.watch(clockProvider).today().budgetMonth;
    final history = finances?.history(month) ?? const <MonthRecord>[];
    return CajuiScreen(
      title: 'Mês a mês',
      overline: 'Meta: sobrar dinheiro três meses seguidos',
      onBack: Navigator.of(context).pop,
      children: [
        if (history.isEmpty)
          const CajuiEmptyState(
            title: 'Ainda não há meses',
            message:
                'Assim que houver um lançamento ou uma entrada, cada mês '
                'aparece aqui com o que entrou, saiu e sobrou.',
          ),
        for (final record in history)
          _row(record, current: record.month == month),
      ],
    );
  }

  static Widget _row(MonthRecord record, {required bool current}) {
    String brl(Money amount) => BrlFormatter.format(amount.cents);
    final left = record.leftOver;
    final label = DateLabels.month(record.month);
    final owed = record.stillOwed.isPositive
        ? ' · devo ${brl(record.stillOwed)}'
        : '';
    return CajuiListRow(
      title: current ? '$label · até agora' : label,
      subtitle:
          'Entrou ${brl(record.cameIn)} · saiu ${brl(record.wentOut)}$owed',
      trailing: CajuiAmountText(
        left.isNegative ? -left.cents : left.cents,
        tone: left.isNegative
            ? CajuiAmountTone.shortfall
            : CajuiAmountTone.positive,
      ),
    );
  }
}
