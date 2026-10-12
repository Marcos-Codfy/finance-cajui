import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/pages/screens/overview/screen_catalog.dart';
import 'package:gallery/src/pages/screens/shared/variant_note.dart';

void main() {
  test('a regra no começo da nota sai da frase e vai para a linha à parte', () {
    expect(splitRule('RN-441: lançamento tardio gera revisão.'), (
      text: 'Lançamento tardio gera revisão.',
      rule: 'RN-441',
    ));
    expect(splitRule('RN-1112 a RN-1115: o resumo e os blocos.'), (
      text: 'O resumo e os blocos.',
      rule: 'RN-1112 a RN-1115',
    ));
    expect(splitRule('E-SRV-01: erro interno do servidor.'), (
      text: 'Erro interno do servidor.',
      rule: 'E-SRV-01',
    ));
  });

  test('a regra entre parênteses no meio da frase também sai', () {
    expect(splitRule('Dá para fechar assim mesmo (RN-441).'), (
      text: 'Dá para fechar assim mesmo.',
      rule: 'RN-441',
    ));
  });

  test('nota sem regra fica como está', () {
    expect(splitRule('Esqueleto com a forma do conteúdo.'), (
      text: 'Esqueleto com a forma do conteúdo.',
      rule: null,
    ));
  });

  test('nenhuma nota de estado mostra código da especificação na frase', () {
    final code = RegExp(r'\b(RN|ADR|D-UX|E-[A-Z]+)-\d+');
    for (final screen in ScreenCatalog.screens) {
      for (final variant in screen.variants()) {
        final text = splitRule(variant.note).text;
        expect(text, isNot(contains(code)), reason: variant.label);
        expect(text, isNot(contains('docs/')), reason: variant.label);
      }
    }
  });
}
