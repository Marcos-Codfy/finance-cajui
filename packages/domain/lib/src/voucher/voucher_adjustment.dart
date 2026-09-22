import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Um acerto do saldo do vale (RN-123).
///
/// Não é renda nem despesa, e não entra em indicador nenhum: é só admitir
/// que o saldo de verdade é o do cartão do vale, e não o que o Cajui
/// calculou. O valor pode ser negativo — acertar quase sempre é descobrir
/// que sobrou menos.
///
/// Existe como valor, e não só como fato do registro, porque o servidor
/// precisa dele: sem os acertos, o saldo que ele calcula desanda do saldo do
/// aparelho assim que alguém corrige o primeiro.
@immutable
final class VoucherAdjustment {
  /// Cria o acerto.
  const new({
    required this.id,
    required this.amount,
    required this.on,
    required this.reason,
  });

  /// O identificador do acerto.
  final String id;

  /// Quanto entra (positivo) ou sai (negativo) do saldo.
  final Money amount;

  /// O dia do acerto.
  final LocalDate on;

  /// Por que o saldo foi corrigido, nas palavras de quem corrigiu.
  final String reason;
}
