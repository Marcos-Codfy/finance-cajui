import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  testWidgets('o teto de caracteres para a digitação: o texto que o '
      'servidor recusaria nem entra no campo', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        CajuiTextField(label: 'O que é', controller: controller, maxLength: 40),
      ),
    );

    await tester.enterText(
      find.byType(EditableText),
      'Plano de saúde da família com coparticipação',
    );

    expect(controller.text, hasLength(40));
  });
}
