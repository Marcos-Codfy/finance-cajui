/// As regras do Cajui, em Dart puro.
///
/// O mesmo pacote roda no aparelho e no servidor (ADR-001): cada regra
/// `RN-xxx` tem uma implementação e um teste, nomeado pela regra.
library;

export 'src/calendar/budget_month.dart';
export 'src/calendar/local_date.dart';
export 'src/income/income_receipt.dart';
export 'src/income/income_source.dart';
export 'src/income/month_income.dart';
export 'src/ledger/block.dart';
export 'src/ledger/category.dart';
export 'src/ledger/entry.dart';
export 'src/ledger/entry_origin.dart';
export 'src/ledger/exceptional_spending.dart';
export 'src/ledger/payment_line.dart';
export 'src/ledger/payment_method_kind.dart';
export 'src/ledger/possible_duplicate.dart';
export 'src/ledger/reversal.dart';
export 'src/money/money.dart';
export 'src/money/tender.dart';
export 'src/money/tender_amounts.dart';
export 'src/shared/clock.dart';
export 'src/shared/failure.dart';
export 'src/shared/result.dart';
export 'src/voucher/voucher_account.dart';
