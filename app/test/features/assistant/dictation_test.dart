import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/scripted_assistant.dart';
import '../../support/test_scope.dart';

/// Um reconhecedor que "ouve" sempre a mesma frase.
final class _Hears implements SpeechInput {
  const new(this.phrase);

  final String phrase;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String?> listen() async => phrase;
}

Future<ProviderContainer> _talk(
  WidgetTester tester, {
  required String said,
  required ScriptedAssistant juju,
}) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(assistant: juju, speech: _Hears(said)),
      child: const CajuiApp(),
    ),
  );
  await settleAfterTap(tester);
  await tester.tap(find.bySemanticsLabel('Ditar a pergunta'));
  await settleAfterTap(tester);
  return ProviderScope.containerOf(tester.element(find.byType(CajuiApp)));
}

void main() {
  testWidgets('BL-050 · o ditado vai direto para a Juju, sem tocar em '
      'enviar', (tester) async {
    final juju = ScriptedAssistant([
      const AssistantAnswered(r'Lancei R$ 40,00 em Mercado, no Pix.'),
    ]);

    await _talk(tester, said: 'gastei 40 no mercado no Pix', juju: juju);

    expect(juju.asked, ['gastei 40 no mercado no Pix']);
  });

  testWidgets('RN-1091 · sem rede, o gasto dito abre a conferência pelo '
      'leitor do aparelho', (tester) async {
    final juju = ScriptedAssistant([const AssistantFailed(ErrorCode.net01)]);
    final container = await _talk(
      tester,
      said: 'gastei 40 no mercado no Pix',
      juju: juju,
    );

    await tester.tap(find.text('Lançar pela conferência'));
    await settleAfterTap(tester);

    final state = container.read(captureProvider);
    expect(state, isA<CaptureReady>());
    final proposal = (state as CaptureReady).capture.proposal;
    expect(proposal.amount.value?.cents, 4000);
    expect(proposal.paymentKind.value, PaymentMethodKind.pix);
  });

  testWidgets('RN-1091 · pergunta que falha não oferece a conferência', (
    tester,
  ) async {
    final juju = ScriptedAssistant([const AssistantFailed(ErrorCode.ai01)]);

    await _talk(tester, said: 'quanto gastei em outubro?', juju: juju);

    expect(find.text('Lançar pela conferência'), findsNothing);
  });
}
