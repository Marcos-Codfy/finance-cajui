import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// A forma de pagamento como o modelo a escreve — "pix", "débito", "no
/// cartão" — traduzida para a forma que o app conhece: o identificador e o
/// tipo que vão na linha de pagamento.
///
/// O servidor não guarda as formas de pagamento: elas nascem no app, com
/// identificadores fixos, e só os cartões chegam aqui pelo cadastro. Este
/// mapa é a cópia desses identificadores; quem muda o cadastro do app muda
/// isto junto.
@immutable
final class PaymentChoice {
  /// Cria a escolha.
  const new({required this.id, required this.kind, required this.label});

  /// O identificador da forma, o mesmo do app.
  final String id;

  /// O tipo da forma.
  final PaymentMethodKind kind;

  /// O nome que a pessoa lê.
  final String label;

  static const _fixed = {
    'pix': PaymentChoice(id: 'pix', kind: PaymentMethodKind.pix, label: 'Pix'),
    'debito': PaymentChoice(
      id: 'debit',
      kind: PaymentMethodKind.debit,
      label: 'Débito',
    ),
    'dinheiro': PaymentChoice(
      id: 'cash',
      kind: PaymentMethodKind.physicalCash,
      label: 'Dinheiro vivo',
    ),
    'vale': PaymentChoice(
      id: 'voucher',
      kind: PaymentMethodKind.mealVoucher,
      label: 'Vale alimentação',
    ),
    'boleto': PaymentChoice(
      id: 'bank-slip',
      kind: PaymentMethodKind.bankSlip,
      label: 'Boleto',
    ),
  };

  /// Os jeitos de dizer cada forma. Sem acento e em minúsculas, que é como
  /// [_normalize] deixa o texto.
  static const _aliases = {
    'cartao de debito': 'debito',
    'debit': 'debito',
    'especie': 'dinheiro',
    'cash': 'dinheiro',
    'dinheiro vivo': 'dinheiro',
    'va': 'vale',
    'vr': 'vale',
    'voucher': 'vale',
    'vale alimentacao': 'vale',
    'vale refeicao': 'vale',
    'alimentacao': 'vale',
    'bank-slip': 'boleto',
  };

  static const _creditWords = {'credito', 'cartao', 'cartao de credito'};

  /// A forma escrita em [raw], ou `null` quando não é nenhuma conhecida.
  /// Cartão entra pelo identificador ou pelo nome; "no cartão", sem dizer
  /// qual, só vale quando há um cartão só.
  static PaymentChoice? parse(
    String raw, {
    required Map<String, CreditCard> cards,
  }) {
    final key = _normalize(raw);
    final fixed = _fixed[_aliases[key] ?? key];
    if (fixed != null) return fixed;
    for (final card in cards.values) {
      if (card.id == raw.trim() || _normalize(card.name) == key) {
        return PaymentChoice(
          id: card.id,
          kind: PaymentMethodKind.creditCard,
          label: card.name,
        );
      }
    }
    if (_creditWords.contains(key) && cards.length == 1) {
      final card = cards.values.single;
      return PaymentChoice(
        id: card.id,
        kind: PaymentMethodKind.creditCard,
        label: card.name,
      );
    }
    return null;
  }

  /// O nome da forma [methodId], para a listagem: a fixa pelo mapa, o
  /// cartão pelo cadastro, e o que não se conhece pelo próprio
  /// identificador.
  static String labelOf(String methodId, Map<String, CreditCard> cards) {
    for (final choice in _fixed.values) {
      if (choice.id == methodId) return choice.label;
    }
    return cards[methodId]?.name ?? methodId;
  }

  /// O que o modelo pode escrever em "forma", para a descrição da
  /// ferramenta. É a lista de chaves de [_fixed], escrita à mão para a
  /// descrição da ferramenta poder ser constante.
  static const options = 'pix, debito, dinheiro, vale, boleto';

  static String _normalize(String text) => text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp('[áàãâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòõôö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'^(no|na|em|pelo|pela|por|com)\s+'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}
