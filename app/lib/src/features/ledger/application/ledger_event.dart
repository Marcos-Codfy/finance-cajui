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
  /// Registra o acerto [adjustment].
  new(this.adjustment) : super(id: 'voucher-${adjustment.id}');

  /// O acerto: quanto, quando e por quê.
  final VoucherAdjustment adjustment;
}

/// Um lançamento foi corrigido (RN-208).
///
/// O fato carrega o lançamento **como ele passa a valer**, com o mesmo
/// identificador do original. O original continua no registro: corrigir é
/// acrescentar, nunca reescrever — e dá para saber o que mudou, quando e em
/// quê.
final class EntryCorrected extends LedgerEvent {
  /// Registra que [entry] passa a valer no lugar da versão anterior.
  const new({
    required super.id,
    required this.entry,
    required this.on,
    required this.reason,
  });

  /// O lançamento corrigido, já aceito pelas regras do domínio.
  final Entry entry;

  /// O dia da correção.
  final LocalDate on;

  /// O que mudou: "categoria", "valor e data".
  final String reason;
}

/// Um lançamento foi cancelado (RN-208).
///
/// Não existe apagar: o lançamento sai de toda visão e de toda conta, mas o
/// fato original fica no registro cifrado (RN-995).
final class EntryCancelled extends LedgerEvent {
  /// Registra o cancelamento do lançamento [entryId].
  const new({
    required super.id,
    required this.entryId,
    required this.on,
    required this.reason,
  });

  /// O lançamento cancelado.
  final String entryId;

  /// O dia do cancelamento.
  final LocalDate on;

  /// Por que foi cancelado, nas palavras que a tela ofereceu.
  final String reason;
}

/// O dinheiro de uma compra voltou, inteiro ou em parte (RN-209).
///
/// O estorno **não altera a compra**: é um registro próprio, que conta no mês
/// em que o dinheiro voltou e volta pela mesma forma de pagamento (RN-211).
final class EntryReversed extends LedgerEvent {
  /// Registra o estorno [reversal].
  new(this.reversal) : super(id: 'reversal-${reversal.id}');

  /// O estorno, já aceito pelo domínio.
  final Reversal reversal;
}

/// Uma dívida foi cadastrada, ou teve os dados alterados (RN-501).
///
/// O fato carrega a dívida **inteira**, e a versão mais recente vale — o
/// mesmo desenho do cartão. O valor para quitar informado pela pessoa vai
/// junto (RN-511).
final class DebtDefined extends LedgerEvent {
  /// Registra a dívida [debt]. Alterar é um fato novo, com [id] próprio.
  const new({required super.id, required this.debt});

  /// A dívida, já aceita pelo domínio.
  final Debt debt;
}

/// Uma parcela de dívida foi paga (RN-520).
///
/// O pagamento em si é um **lançamento** do bloco de dívidas; este fato só o
/// liga à dívida, para ela contar mais uma parcela paga. Se o lançamento for
/// cancelado, a parcela volta a estar em aberto.
final class DebtInstallmentPaid extends LedgerEvent {
  /// Liga o lançamento [entryId] à dívida [debtId].
  const new({required this.debtId, required this.entryId})
    : super(id: 'debt-payment-$entryId');

  /// A dívida que teve a parcela paga.
  final String debtId;

  /// O lançamento que pagou a parcela.
  final String entryId;
}

/// Um mês foi fechado, ou teve o fechamento revisado (RN-440 e RN-441).
///
/// Cada revisão é um fato próprio: a anterior continua no registro, e a
/// diferença entre as duas é o que a tela mostra depois de um lançamento
/// tardio.
final class MonthClosed extends LedgerEvent {
  /// Registra o fechamento [close].
  new(this.close) : super(id: 'close-${close.month}-${close.revision}');

  /// O retrato do mês: qual mês, que revisão, o resultado e quando foi feito.
  final MonthClose close;
}
