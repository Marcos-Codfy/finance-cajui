import 'package:domain/domain.dart';

/// Quando a leitura do celular basta, e como juntar a do servidor com ela
/// (ADR-022).
///
/// O celular lê primeiro, de graça e sem rede: o texto da foto e as regras
/// sobre ele. Quando as regras resolveram tudo o que importa — o valor ao
/// lado de "TOTAL", a data, o tipo do lugar, que é o caso do cupom de
/// mercado, de farmácia e de posto —, a IA não acrescenta nada que valha a
/// espera, e o comprovante abre na hora. Em todo o resto — Pix, print de
/// banco, cupom amassado, foto que o celular mal leu —, a foto vai para a
/// IA, que lê junto com o texto.
abstract final class ReadingStrategy {
  /// Se as regras do celular já leram o comprovante inteiro.
  static bool rulesSuffice(EntryProposal local) =>
      local.amount.confidence == Confidence.high &&
      local.occurredOn.value != null &&
      local.documentKind.value == DocumentKind.purchase &&
      local.merchant != null &&
      // Sem saber por onde pagou, a regra não basta: cupom de mercado pago
      // no vale, lido como débito, soma moedas que nunca se somam (RN-111).
      local.paymentKind.value != null &&
      (local.category.value != null || local.category.candidates.isNotEmpty);

  /// A proposta do servidor, com a categoria que só o celular sabe ler: o
  /// ramo do lugar pelo cadastro daqui (supermercado é Mercado). Ela entra
  /// depois do palpite da IA, como alternativa — ou no lugar dele, quando a
  /// IA não palpitou.
  static EntryProposal blend(EntryProposal remote, EntryProposal local) {
    final category = remote.category;
    if (category.value != null) return remote;
    final merged = <String>{
      ...category.candidates,
      ?local.category.value,
      ...local.category.candidates,
    }.take(3).toList();
    if (merged.isEmpty) return remote;
    if (category.candidates.isEmpty && local.category.value != null) {
      return remote.copyWith(category: local.category);
    }
    return remote.copyWith(
      category: ProposedField.undecided(
        merged,
        source: category.candidates.isEmpty
            ? local.category.source
            : category.source,
      ),
    );
  }
}
