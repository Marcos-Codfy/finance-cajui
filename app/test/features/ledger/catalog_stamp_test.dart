import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/catalog_stamp.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// O cadastro de fábrica como estava em [CatalogStamp.definedAt]: id,
/// bloco, grupo, nome e se o vale paga.
const _catalogAtStamp = [
  ('groceries', 'variable', 'food', 'Mercado', true),
  ('street-market', 'variable', 'food', 'Feira', true),
  ('butcher', 'variable', 'food', 'Açougue', true),
  ('bakery', 'variable', 'food', 'Padaria', true),
  ('produce', 'variable', 'food', 'Hortifrúti', true),
  ('eating-out', 'variable', 'food', 'Restaurante e lanche', false),
  ('transport', 'variable', 'transport', 'Transporte', false),
  ('health', 'variable', 'health', 'Saúde e farmácia', false),
  ('leisure', 'variable', 'leisure', 'Lazer', false),
  ('home', 'variable', 'housing', 'Casa', false),
  ('other', 'variable', 'other', 'Outros', false),
  ('rent', 'fixed', 'housing', 'Aluguel', false),
  ('utilities', 'fixed', 'housing', 'Água, luz e internet', false),
  ('debt-installment', 'debt', 'debt', 'Parcela de dívida', false),
  ('interest-and-fees', 'debt', 'debt', 'Juros e tarifas', false),
];

void main() {
  test('ADR-024 · mudou o cadastro de fábrica, subiu o carimbo junto', () {
    String line(Category category) =>
        '${category.id}: '
        '${CatalogVersion.signatureOf(CategoryCodec.encode(category))}';
    final now = [
      for (final category in DefaultCatalog.categories) line(category),
    ];
    final atStamp = [
      for (final (id, block, group, name, voucher) in _catalogAtStamp)
        '$id: block=$block|groupId=$group|name=$name|voucherEligible=$voucher',
    ];

    expect(
      now,
      atStamp,
      reason:
          'O cadastro de fábrica mudou. Suba CatalogStamp.definedAt para o '
          'dia da mudança — sem isso a categoria nova não passa por cima da '
          'que o servidor já tem — e atualize esta lista.',
    );
  });
}
