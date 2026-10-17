import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  group('CajuiNotice', () {
    testWidgets('diz o que aconteceu, o que significa e o que fazer', (
      tester,
    ) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 360,
            child: CajuiNotice(
              what: 'Não consegui ler este comprovante.',
              meaning: 'O arquivo está guardado; nada foi perdido.',
              primaryAction: CajuiNoticeAction(
                label: 'Tirar outra foto',
                onPressed: () => chosen.add('foto'),
              ),
              secondaryAction: CajuiNoticeAction(
                label: 'Digitar os dados',
                onPressed: () => chosen.add('digitar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Digitar os dados'));

      expect(find.text('Não consegui ler este comprovante.'), findsOneWidget);
      expect(
        find.text('O arquivo está guardado; nada foi perdido.'),
        findsOneWidget,
      );
      expect(chosen, ['digitar']);
    });

    testWidgets('RNF-A11Y-13 continua na tela: não some sozinho', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 360,
            child: CajuiNotice(what: 'Sem conexão agora.'),
          ),
        ),
      );

      await tester.pump(const Duration(minutes: 5));

      expect(find.text('Sem conexão agora.'), findsOneWidget);
    });

    testWidgets('a intenção vem com ícone, não só com cor', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 360,
            child: CajuiNotice(
              what: 'Setembro fechou com sobra.',
              intent: CajuiNoticeIntent.positive,
            ),
          ),
        ),
      );

      expect(find.byType(CajuiIcon), findsOneWidget);
    });
  });

  group('CajuiEmptyState', () {
    testWidgets('convida, em vez de constatar, e oferece o próximo passo', (
      tester,
    ) async {
      var started = 0;
      await tester.pumpWidget(
        host(
          CajuiEmptyState(
            title: 'Nada lançado ainda.',
            message: 'Compartilhe um comprovante ou lance o primeiro à mão.',
            action: CajuiNoticeAction(
              label: 'Lançar',
              onPressed: () => started++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Lançar'));

      expect(started, 1);
    });

    testWidgets('a ilustração é opcional: sem ela, só o texto; com ela, o '
        'desenho vem antes do título', (tester) async {
      const title = 'Nenhum cartão ainda';
      await tester.pumpWidget(
        host(const CajuiEmptyState(title: title, message: 'Cadastre.')),
      );
      expect(find.byType(CajuiCerradoArt), findsNothing);

      await tester.pumpWidget(
        host(
          const CajuiEmptyState(
            title: title,
            message: 'Cadastre.',
            illustration: CajuiCerradoArt(CajuiCerrado.leaf),
          ),
        ),
      );

      final art = tester.getRect(find.byType(CajuiCerradoArt));
      expect(art.bottom, lessThan(tester.getTopLeft(find.text(title)).dy));
      expect(
        art.center.dx,
        closeTo(tester.getCenter(find.text(title)).dx, 0.5),
      );
    });
  });

  group('movimento reduzido (RNF-A11Y-07)', () {
    final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);

    testWidgets('esqueleto, pontos e herói ficam parados', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CajuiSkeleton.line(width: 120),
              CajuiLoadingDots(color: Color(0xFF2A1D17)),
              CajuiHeroFruit(size: 80),
            ],
          ),
          theme: reduced,
        ),
      );

      // Se alguma animação estivesse rodando, isto estouraria o tempo.
      await tester.pumpAndSettle();

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('no nível completo o herói flutua', (tester) async {
      await tester.pumpWidget(host(const CajuiHeroFruit(size: 80)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.hasRunningAnimations, isTrue);
    });
  });
}
