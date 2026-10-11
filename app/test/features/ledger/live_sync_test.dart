import 'dart:async';

import 'package:cajui/src/features/ledger/application/live_sync.dart';
import 'package:cajui/src/features/ledger/application/server_head.dart';
import 'package:flutter_test/flutter_test.dart';

/// Um topo de servidor que responde o que o teste mandar; `null` é "sem
/// rede".
final class _Head implements ServerHead {
  int? seq;
  int asked = 0;

  @override
  Future<int?> ledgerSeq() async {
    asked++;
    return seq;
  }
}

/// Um relógio que o teste adianta à mão: guarda a batida e o intervalo.
final class _Clock {
  void Function()? tick;
  Duration? every;
  final List<_Timer> timers = [];

  Timer start(Duration every, void Function() tick) {
    this.every = every;
    this.tick = tick;
    final timer = _Timer();
    timers.add(timer);
    return timer;
  }

  /// Uma batida, se o relógio ainda está andando.
  Future<void> beat() async {
    if (timers.lastOrNull?.isActive ?? false) tick?.call();
    await pumpEventQueue();
  }
}

final class _Timer implements Timer {
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

void main() {
  late _Head head;
  late _Clock clock;
  late int refreshes;
  late bool refreshWorks;
  Completer<void>? slow;
  late LiveSync live;

  setUp(() {
    head = _Head();
    clock = _Clock();
    refreshes = 0;
    refreshWorks = true;
    slow = null;
    live = LiveSync(
      head: head,
      refresh: () async {
        refreshes++;
        await slow?.future;
        return refreshWorks;
      },
      ticker: clock.start,
    );
  });

  group('ADR-024 · a conferência ao vivo', () {
    test(
      'pergunta o topo a cada 20 segundos enquanto o app está na frente',
      () {
        live.resume();

        expect(clock.every, const Duration(seconds: 20));
        expect(live.isRunning, isTrue);
      },
    );

    test(
      'o topo parado não desce nada; o topo que andou desce uma vez',
      () async {
        head.seq = 7;
        live.resume();
        await pumpEventQueue();
        final first = refreshes;

        await clock.beat();
        await clock.beat();
        expect(refreshes, first, reason: 'nada mudou: só o número foi pedido');

        head.seq = 8;
        await clock.beat();
        await clock.beat();
        expect(refreshes, first + 1);
        expect(head.asked, 5);
      },
    );

    test('voltar ao app no celular desce mesmo sem o topo ter andado: '
        'sobe o que foi lançado sem rede', () async {
      head.seq = 7;
      live.resume();
      await pumpEventQueue();

      live.resume(force: true);
      await pumpEventQueue();

      expect(refreshes, 2);
    });

    test('no fundo o relógio para, e a batida que sobrou não pergunta '
        'nada', () async {
      head.seq = 7;
      live.resume();
      await pumpEventQueue();
      final asked = head.asked;

      live.pause();
      head.seq = 9;
      await clock.beat();

      expect(live.isRunning, isFalse);
      expect(clock.timers.single.cancelled, isTrue);
      expect(head.asked, asked);
    });

    test('voltar à frente cancela o relógio antigo e começa outro', () async {
      live
        ..resume()
        ..resume();
      await pumpEventQueue();

      expect(clock.timers, hasLength(2));
      expect(clock.timers.first.cancelled, isTrue);
      expect(clock.timers.last.isActive, isTrue);
    });

    test('uma conferência de cada vez: a batida durante uma descida lenta '
        'é pulada', () async {
      head.seq = 1;
      slow = Completer<void>();
      live.resume();
      await pumpEventQueue();

      head.seq = 2;
      await clock.beat();
      await clock.beat();
      expect(refreshes, 1, reason: 'a primeira ainda está no ar');

      slow!.complete();
      await pumpEventQueue();
      await clock.beat();
      expect(refreshes, 2, reason: 'o topo andou durante a lenta');
    });

    test('a descida que falhou não conta como vista: a próxima batida '
        'tenta de novo', () async {
      head.seq = 3;
      refreshWorks = false;
      live.resume();
      await pumpEventQueue();

      refreshWorks = true;
      await clock.beat();
      await clock.beat();

      expect(refreshes, 2);
    });

    test('sem rede o topo não responde, e nada desce; a rede voltando, '
        'desce', () async {
      live.resume();
      await pumpEventQueue();
      await clock.beat();
      expect(refreshes, 0);

      head.seq = 4;
      await clock.beat();
      expect(refreshes, 1);
    });

    test('erro do servidor ou do livro não escapa da conferência', () async {
      final broken = LiveSync(
        head: head..seq = 1,
        refresh: () => throw StateError('livro não abriu'),
        ticker: clock.start,
      )..resume(force: true);
      await pumpEventQueue();

      expect(broken.isRunning, isTrue);
    });
  });
}
