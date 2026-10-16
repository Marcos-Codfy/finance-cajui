import 'package:cajui/src/core/presentation/loading_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a espera já mostra o título da tela que vem e o formato dela, '
      'nunca branco', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (context, _) => CajuiAppSurface(
          theme: CajuiThemeData.light(),
          feedback: const SilentFeedback(),
          child: const LoadingPage(title: 'Dívida'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dívida'), findsOneWidget);
    expect(find.byType(CajuiSkeleton), findsNWidgets(3));
  });
}
