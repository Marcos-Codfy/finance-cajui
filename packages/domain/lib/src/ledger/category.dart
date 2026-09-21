import 'package:domain/src/ledger/block.dart';
import 'package:meta/meta.dart';

/// Uma categoria: **o que** foi comprado.
///
/// Pertence a um bloco e a um grupo (RN-202), e diz se o vale alimentação
/// pode pagá-la (RN-113) — é atributo da categoria porque cada cartão de vale
/// é aceito em lugares diferentes, e quem sabe disso é a pessoa.
@immutable
final class Category {
  /// Cria a categoria.
  const new({
    required this.id,
    required this.name,
    required this.block,
    required this.groupId,
    this.voucherEligible = false,
  });

  /// O identificador da categoria.
  final String id;

  /// O nome na tela: "Mercado".
  final String name;

  /// O bloco a que os lançamentos desta categoria pertencem.
  final Block block;

  /// O grupo, para somar categorias afins: "alimentação", "moradia".
  final String groupId;

  /// O vale alimentação pode pagar esta categoria.
  final bool voucherEligible;
}
