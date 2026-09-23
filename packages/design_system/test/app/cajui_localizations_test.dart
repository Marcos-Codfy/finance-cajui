import 'package:design_system/design_system.dart';
// O Material entra aqui, e só aqui: é o teste conferindo que o menu do
// campo de texto — que é do Material por dentro — fala português.
import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BL-029 · os textos de sistema falam português', () {
    testWidgets('o menu de copiar e colar do campo de texto vem traduzido', (
      tester,
    ) async {
      late BuildContext inside;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          localizationsDelegates: CajuiLocalizations.delegates,
          supportedLocales: CajuiLocalizations.locales,
          locale: CajuiLocalizations.locales.first,
          builder: (context, child) {
            inside = context;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pump();

      final textos = MaterialLocalizations.of(inside);

      expect(textos.copyButtonLabel, 'Copiar');
      expect(textos.pasteButtonLabel, 'Colar');
      expect(textos.selectAllButtonLabel, 'Selecionar tudo');
    });

    test('o app declara um idioma só, e é o nosso', () {
      expect(CajuiLocalizations.locales, [const Locale('pt', 'BR')]);
    });
  });
}
