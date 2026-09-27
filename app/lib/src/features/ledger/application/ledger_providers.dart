import 'dart:math';

import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onde o livro é gravado. Quem decide é a raiz do app, que conhece a
/// plataforma; a aplicação só declara que precisa de um.
final ledgerJournalProvider = Provider<LedgerJournal>(
  (ref) => throw StateError('ledgerJournalProvider sem override na raiz.'),
);

/// De onde vem o dia de hoje. O teste troca por uma data fixa.
final clockProvider = Provider<Clock>((ref) => const _DeviceClock());

/// Quem cria identificadores novos. O teste troca por uma sequência.
final newIdProvider = Provider<String Function()>((ref) => _randomId);

/// O dia de hoje no fuso do aparelho — que, para quem usa, é o fuso de
/// negócio: a compra "de hoje" é a do dia que a pessoa está vivendo.
class _DeviceClock implements Clock {
  const new();

  @override
  LocalDate today() => LocalDate.fromDateTime(DateTime.now());

  @override
  DateTime now() => DateTime.now().toUtc();
}

final _random = Random.secure();

/// Hora em base 36 mais 8 dígitos ao acaso: ordena por criação e não repete
/// nem entre dois aparelhos que lançam no mesmo instante.
String _randomId() {
  final moment = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  // Um byte por vez, e não `nextInt(1 << 32)`: na web os inteiros são os do
  // JavaScript, esse deslocamento dá zero e o sorteio lança erro.
  final noise = [
    for (var i = 0; i < 4; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  return '$moment-$noise';
}
