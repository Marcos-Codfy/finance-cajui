import 'package:domain/src/ledger/block.dart';

/// Em que grupo uma linha de "Minhas contas" entra.
///
/// São três, e não quatro: a parcela de dívida vem da dívida cadastrada e
/// nunca é digitada como conta (regra 3 da planilha). Um tipo que não tem
/// esse valor é a forma mais curta de a regra nunca ser quebrada.
enum LineGroup {
  /// Conta fixa: aluguel, energia, internet.
  fixedBill(Block.fixed),

  /// Assinatura: o serviço que se paga todo mês.
  subscription(Block.subscription),

  /// Dia a dia: transporte, mercado, padaria, farmácia.
  dayToDay(Block.variable);

  new(this.block);

  /// O grupo do mês que a linha alimenta.
  final Block block;

  /// O grupo de linha de [block]; `null` para a parcela de dívida.
  static LineGroup? of(Block block) =>
      values.where((group) => group.block == block).firstOrNull;
}
