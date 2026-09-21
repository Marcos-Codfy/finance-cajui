import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Um fato do livro de lançamentos, como fica gravado no aparelho.
///
/// O livro não guarda "o estado": guarda o que aconteceu, em ordem, e o
/// estado é sempre recalculado a partir disso (ADR-004). É o que permite
/// corrigir sem apagar e subir a fila para o servidor sem perder nada.
@immutable
sealed class LedgerEvent {
  const new({required this.id});

  /// O identificador do fato. Gravar o mesmo `id` duas vezes não duplica.
  final String id;
}

/// Uma despesa foi lançada.
final class EntryRecorded extends LedgerEvent {
  /// Registra o lançamento [entry].
  new(this.entry) : super(id: 'entry-${entry.id}');

  /// O lançamento, já aceito pelas regras do domínio.
  final Entry entry;
}

/// O saldo do vale foi corrigido para bater com o da operadora (RN-123).
///
/// Não é renda nem despesa, e não entra em indicador: é só o app admitindo
/// que o saldo de verdade é o do cartão do vale, não o que ele calculou.
final class VoucherBalanceAdjusted extends LedgerEvent {
  /// Registra o ajuste [adjustment], feito em [on].
  const new({
    required super.id,
    required this.adjustment,
    required this.on,
    required this.reason,
  });

  /// Quanto entra (positivo) ou sai (negativo) do saldo.
  final Money adjustment;

  /// O dia do ajuste.
  final LocalDate on;

  /// Por que o saldo foi corrigido, nas palavras de quem corrigiu.
  final String reason;
}
