import 'package:cajui/src/core/format/date_labels.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// "O que eu entendi": o comprovante traduzido em campos, antes do texto cru.
///
/// É a resposta à pergunta que a pessoa tem ao abrir esta tela. Campo que as
/// regras não resolveram aparece dito assim — "não consegui ler" —, porque
/// ficar em branco parece defeito, e inventar seria pior. Dúvida aparece como
/// dúvida: "R$ 664,41 ou R$ 653,58" (RN-744).
abstract final class UnderstoodSection {
  /// O que a tela diz de um campo que ninguém leu.
  static const unread = 'não consegui ler';

  /// A seção para [proposal], lida de [text].
  static List<Widget> of(EntryProposal proposal, {required String text}) => [
    const CajuiSectionTitle('O que eu entendi'),
    ..._rows(proposal, text),
    const SizedBox(height: CajuiSpacing.xl),
  ];

  static List<Widget> _rows(EntryProposal proposal, String text) => [
    _row('Tipo do documento', _of(proposal.documentKind, _kindName)),
    _row('Valor', _of(proposal.amount, _brl)),
    _row('Data', _of(proposal.occurredOn, DateLabels.long)),
    _row('Estabelecimento', proposal.displayDescription ?? unread),
    _row('Forma de pagamento', _of(proposal.paymentKind, _paymentName)),
    if (proposal.installments case final count?) _row('Parcelas', '${count}x'),
    _row('Linhas de texto', '${ReceiptLayout.lines(text).length}'),
  ];

  static Widget _row(String label, String value) =>
      CajuiListRow(title: label, trailing: _Value(value));

  /// O campo em palavras: o valor lido, os candidatos separados por "ou", ou
  /// a frase de não lido.
  static String _of<T>(ProposedField<T> field, String Function(T) label) {
    if (field.value case final value?) return label(value);
    if (field.candidates.isEmpty) return unread;
    return field.candidates.map(label).join(' ou ');
  }

  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  static String _paymentName(PaymentMethodKind kind) => switch (kind) {
    PaymentMethodKind.pix => 'Pix',
    PaymentMethodKind.debit => 'Débito',
    PaymentMethodKind.creditCard => 'Cartão de crédito',
    PaymentMethodKind.bankSlip => 'Boleto',
    PaymentMethodKind.physicalCash => 'Dinheiro',
    PaymentMethodKind.mealVoucher => 'Vale alimentação',
  };

  static String _kindName(DocumentKind kind) => switch (kind) {
    DocumentKind.purchase => 'Compra',
    DocumentKind.incomeReceipt => 'Dinheiro que entrou',
    DocumentKind.statementPayment => 'Pagamento de fatura',
    DocumentKind.ownTransfer => 'Transferência entre contas suas',
    DocumentKind.statement => 'Extrato',
  };
}

/// O valor de um campo entendido. Em itálico e apagado quando não foi lido: a
/// diferença entre "li isto" e "não li" é de forma, e não só de texto.
class _Value extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final isUnread = text == UnderstoodSection.unread;
    return Text(
      text,
      textAlign: TextAlign.end,
      style: theme.typography.body.copyWith(
        color: isUnread ? theme.colors.text.faint : theme.colors.text.primary,
        fontStyle: isUnread ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}
