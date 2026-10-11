import 'package:domain/domain.dart';

/// Como cada tipo de dívida é chamado na tela (RN-502).
///
/// O parcelamento de compra no cartão não é oferecido para cadastro à mão:
/// ele nasce da própria compra parcelada (RN-503), e cadastrá-lo de novo
/// contaria a mesma parcela duas vezes.
abstract final class DebtKindLabel {
  /// Os tipos que a pessoa escolhe ao cadastrar.
  static const List<DebtKind> choosable = [
    DebtKind.loan,
    DebtKind.financing,
    DebtKind.cardRevolving,
    DebtKind.overdueBill,
    DebtKind.informal,
  ];

  /// O nome de [kind].
  static String of(DebtKind kind) => switch (kind) {
    DebtKind.loan => 'Empréstimo',
    DebtKind.financing => 'Financiamento',
    DebtKind.cardInstallment => 'Compra parcelada no cartão',
    DebtKind.cardRevolving => 'Fatura parcelada ou rotativo',
    DebtKind.informal => 'Devo a alguém',
    DebtKind.overdueBill => 'Conta atrasada',
  };
}
