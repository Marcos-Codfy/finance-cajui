import 'package:design_system/src/components/timeline/cajui_timeline_mark.dart';
import 'package:flutter/foundation.dart';

/// Um item da linha do tempo: o que é, quando e como está.
@immutable
class CajuiTimelineItem {
  /// Cria o item [title], com [subtitle], valor [cents] e marca [mark].
  const new({
    required this.title,
    required this.subtitle,
    required this.cents,
    required this.mark,
  });

  /// O que é: "Aluguel".
  final String title;

  /// Quando e como: "vence dia 10 · a pagar".
  final String subtitle;

  /// O valor, em centavos.
  final int cents;

  /// Como está.
  final CajuiTimelineMark mark;
}
