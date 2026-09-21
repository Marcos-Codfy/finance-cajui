import 'package:cajui/src/features/budget/application/month_setup.dart';
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

/// O plano do mês foi cadastrado ou alterado.
///
/// O fato carrega o cadastro **inteiro**, e o mais recente vale. É a forma
/// mais simples que não perde nada: o registro guarda cada versão do plano,
/// na ordem, e dá para saber com que plano cada mês foi vivido.
final class PlanDefined extends LedgerEvent {
  /// Registra o cadastro [setup].
  const new({required super.id, required this.setup});

  /// O cadastro que passa a valer.
  final MonthSetup setup;
}

/// Um cartão de crédito foi cadastrado, ou teve os dados alterados.
///
/// Cartão é **forma de pagamento**, nunca despesa (RN-301): o fato guarda por
/// onde se paga e quando a fatura fecha e vence — nada de valor.
final class CardDefined extends LedgerEvent {
  /// Registra o cartão [card]. Alterar um cartão é um fato novo, com [id]
  /// próprio: o registro guarda cada versão, e a mais recente vale.
  const new({required super.id, required this.card});

  /// O cartão, já aceito pelo domínio.
  final CreditCard card;
}

/// A fatura de um cartão foi paga. É uma **liquidação** (RN-340): não é
/// lançamento, não entra em bloco nenhum e não muda indicador de despesa — as
/// compras já contaram quando foram feitas.
final class StatementSettled extends LedgerEvent {
  /// Registra a liquidação [settlement].
  new(this.settlement) : super(id: 'settlement-${settlement.id}');

  /// O pagamento: cartão, mês de vencimento, valor e data.
  final Settlement settlement;
}

/// Uma renda foi recebida: o salário, o crédito mensal do vale, uma entrada
/// avulsa.
///
/// Recebimento **não é lançamento** (RN-132): não tem categoria, não entra
/// em bloco de despesa e nunca se compensa com um gasto. Em dinheiro, o valor
/// recebido passa a valer no lugar do esperado nas contas do mês (RN-131); no
/// vale, é o crédito que entra no saldo (RN-120).
final class IncomeReceived extends LedgerEvent {
  /// Registra o recebimento [receipt].
  new(this.receipt) : super(id: 'income-${receipt.id}');

  /// O recebimento: moeda, valor, dia e, se houver, a fonte.
  final IncomeReceipt receipt;
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
