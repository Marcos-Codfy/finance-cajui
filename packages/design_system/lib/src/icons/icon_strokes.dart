import 'dart:math' as math;
import 'dart:ui';

// Desenhos de ícone que não cabiam no arquivo do `CajuiIconData` (limite de
// 300 linhas): mesma grade de 24 × 24, mesmo traço. Interno ao design
// system — o que se exporta é o ícone, não o desenho.

/// Repete todo mês: duas setas num círculo (as assinaturas).
void drawRepeat(Path p) {
  p
    ..addArc(Rect.fromCircle(center: const Offset(12, 12), radius: 7), 0.6, 4.6)
    ..moveTo(19.2, 5.2)
    ..lineTo(18.6, 9.4)
    ..lineTo(14.6, 8.4);
}

/// Sem rede: o sinal de wi-fi riscado.
void drawOffline(Path p) {
  p
    ..addArc(
      Rect.fromCircle(center: const Offset(12, 18), radius: 11),
      -math.pi * 0.78,
      math.pi * 0.56,
    )
    ..addArc(
      Rect.fromCircle(center: const Offset(12, 18), radius: 6.5),
      -math.pi * 0.78,
      math.pi * 0.56,
    )
    ..moveTo(12, 18)
    ..lineTo(12, 18.1)
    ..moveTo(4, 4)
    ..lineTo(20, 20);
}
