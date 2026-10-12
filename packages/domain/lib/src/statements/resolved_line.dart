import 'package:domain/src/receipts/statement_line.dart';
import 'package:domain/src/receipts/statement_line_kind.dart';
import 'package:domain/src/statements/installment_mark.dart';
import 'package:domain/src/statements/line_doubt.dart';
import 'package:domain/src/statements/line_treatment.dart';
import 'package:meta/meta.dart';

/// Uma linha de extrato depois de o celular decidir o que ela é (RN-1109,
/// RN-1110): com o nome que a pessoa reconhece, a categoria decidida, a
/// chave da memória e, quando falta certeza, o porquê.
@immutable
final class ResolvedLine {
  /// Cria a linha resolvida.
  const new({
    required this.line,
    required this.merchantKey,
    String? contentKey,
    this.person,
    this.installment,
    this.treatment,
    this.guess,
    this.doubts = const {},
  }) : contentKey = contentKey ?? merchantKey;

  /// A linha com o nome final e a categoria decidida — `null` quando a
  /// categoria é dúvida.
  final StatementLine line;

  /// A chave do estabelecimento, pela qual a resposta é lembrada (RN-1116).
  /// Vazia quando a linha não tem nome que sirva de chave — "Movimentação",
  /// um nome mascarado sem o original: aí a resposta vale só para ela.
  final String merchantKey;

  /// A chave do conteúdo, para a chave da linha gravada (RN-1117): sai do
  /// texto que o celular leu, e não da descrição da IA, que pode mudar de
  /// uma leitura para outra.
  final String contentKey;

  /// A parcela escrita na linha, quando é parcela (RN-1111).
  final InstallmentMark? installment;

  /// Se a resposta sobre esta linha pode ser lembrada para as próximas.
  bool get rememberable => merchantKey.isNotEmpty;

  /// O nome da pessoa, como o banco escreveu, num Pix ou transferência. Só
  /// existe no celular: para a IA ele foi `[NOME]` (RN-1106).
  final String? person;

  /// O que a linha é, quando a memória ou a lista da casa decidiu.
  final LineTreatment? treatment;

  /// O palpite de categoria da IA, para a pergunta oferecer primeiro.
  final String? guess;

  /// O que falta decidir; vazio quando a linha está certa.
  final Set<LineDoubt> doubts;

  /// Se não há nada a perguntar.
  bool get isSure => doubts.isEmpty;

  /// Se vira gasto ao lançar.
  bool get isExpense =>
      treatment == LineTreatment.expense ||
      (treatment == null && line.kind == StatementLineKind.expense);

  /// Se vira dinheiro que entrou ao lançar.
  bool get isIncome =>
      treatment == LineTreatment.income ||
      (treatment == null && line.kind == StatementLineKind.income);

  /// Lida, mas fora da conta: pagamento de fatura (RN-756), conta sua
  /// (RN-759), alguém da casa (RN-1070) ou "não lançar".
  bool get isLeftOut => !isExpense && !isIncome;
}
