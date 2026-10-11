import 'package:domain/src/notifications/bank_app.dart';
import 'package:domain/src/notifications/movement_kind.dart';

/// Diz que movimentação uma notificação de banco avisa — ou que ela não
/// avisa movimentação nenhuma (RN-787).
///
/// Lê o texto já dobrado por `NoticeText.fold`: minúsculas, sem acento.
abstract final class MovementReader {
  /// O que desfaz qualquer leitura: a compra que não passou, o que foi
  /// desfeito, o que ainda vai acontecer, a fatura — pagar a fatura não é
  /// gastar de novo (RN-340) — e o que é propaganda, código ou investimento.
  static const _notAMovement = [
    'negad',
    'recusad',
    'nao aprovad',
    'nao foi aprovad',
    'nao autorizad',
    'nao realizad',
    'nao concluid',
    'bloquead',
    'cancelad',
    'estorn',
    'devolvid',
    'contestad',
    'agendad',
    'agendamento',
    'fatura',
    'cashback',
    'codigo de acesso',
    'codigo de seguranca',
    'codigo de verificacao',
    'codigo de confirmacao',
    'seu codigo',
    'senha',
    'token',
    'emprestimo',
    'pre-aprovad',
    'pre aprovad',
    'oferta',
    'promo',
    'investi',
    'rendimento',
  ];

  /// As movimentações de conta, na ordem em que são conferidas: o boleto
  /// antes do pagamento genérico, o que entrou antes do que saiu.
  static final List<(RegExp, MovementKind)> _flows = [
    (
      RegExp(
        r'boleto\b.*\b(pago|paga|pagamento|quitado|liquidado|realizado|'
        r'efetuado|confirmado)\b|\b(pagamento|pagou|pago)\b.*\bboleto',
      ),
      MovementKind.boletoPaid,
    ),
    (
      RegExp(
        'pix recebido|recebeu (um )?pix|recebido via pix|recebimento de pix|'
        r'pix de r\$ ?[\d.,]+ recebido|voce recebeu r\$',
      ),
      MovementKind.pixReceived,
    ),
    (
      RegExp(
        'transferencia recebida|recebeu uma transferencia|ted recebida|'
        'doc recebido|credito em conta|deposito recebido',
      ),
      MovementKind.transferReceived,
    ),
    (
      RegExp(
        'pix (enviado|realizado|efetuado|feito|pago|concluido)|'
        r'(enviou|fez) (um )?pix|\b(via|por|com) pix\b|'
        r'pix de r\$ ?[\d.,]+ (enviado|realizado|efetuado)',
      ),
      MovementKind.pixSent,
    ),
    (
      RegExp(
        'transferencia (enviada|realizada|efetuada|concluida)|'
        'enviou uma transferencia|voce transferiu|voce enviou|'
        'ted (enviada|realizada|efetuada)|doc (enviado|realizado)',
      ),
      MovementKind.transferSent,
    ),
  ];

  /// "Compra aprovada", "compra de R$ 45,90 APROVADA", "compra realizada".
  static final _cardPurchase = RegExp(
    r'\bcompra\b.*\b(aprovad[ao]|realizad[ao]|efetuad[ao]|confirmad[ao]|'
    r'autorizad[ao]|concluid[ao])\b|'
    r'\b(aprovad[ao]|realizad[ao])\b.*\bcompra\b',
  );

  /// "Você pagou R$ 15,00", "pagamento de R$ 22,90 aprovado": dinheiro que
  /// saiu do saldo da conta, sem cartão de crédito.
  static final _accountPayment = RegExp(
    r'voce pagou|pagou r\$|pagamento (de r\$ ?[\d.,]+ )?(aprovado|realizado|'
    'efetuado|concluido|confirmado)',
  );

  /// A movimentação que [folded] avisa, vinda de [app]; `null` quando não é
  /// movimentação de dinheiro.
  static MovementKind? kindIn(String folded, BankApp app) {
    if (_notAMovement.any(folded.contains)) return null;
    for (final (pattern, kind) in _flows) {
      if (pattern.hasMatch(folded)) return kind;
    }
    return _purchase(folded, app);
  }

  /// Compra: no crédito, a não ser que o texto diga débito. Notificação de
  /// compra que não diz o tipo é, quase sempre, do cartão de crédito — o
  /// débito os bancos fazem questão de nomear. O pagamento com o saldo da
  /// conta é débito, a não ser na carteira, que só paga com cartão.
  static MovementKind? _purchase(String folded, BankApp app) {
    final card = _cardPurchase.hasMatch(folded);
    final account = _accountPayment.hasMatch(folded);
    if (!card && !account && !app.isWallet) return null;
    if (folded.contains('debito')) return MovementKind.debitPurchase;
    if (folded.contains('credito')) return MovementKind.creditPurchase;
    return account && !card && !app.isWallet
        ? MovementKind.debitPurchase
        : MovementKind.creditPurchase;
  }
}
