import 'package:api_contract/src/entry_codec.dart';
import 'package:domain/domain.dart';

/// A ida e a volta da categoria com o registro e com a rede.
///
/// Mora no contrato porque os dois lados a escrevem: o app manda o
/// cadastro dele, e o servidor grava e devolve. Antes cada lado montava o
/// mapa à mão, e um campo esquecido de um lado sumia em silêncio.
abstract final class CategoryCodec {
  /// O que gravar para [category].
  static Map<String, Object?> encode(Category category) => {
    'id': category.id,
    'name': category.name,
    'block': category.block.name,
    'groupId': category.groupId,
    'voucherEligible': category.voucherEligible,
  };

  /// A categoria gravada em [payload]. Bloco desconhecido é formato
  /// inválido, e não categoria pela metade.
  static Category decode(Map<String, Object?> payload) => Category(
    id: payload['id']! as String,
    name: payload['name']! as String,
    block: EntryCodec.named(Block.values, payload['block']! as String),
    groupId: payload['groupId']! as String,
    voucherEligible: payload['voucherEligible'] as bool? ?? false,
  );
}
