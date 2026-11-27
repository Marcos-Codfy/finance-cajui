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

/// Engrenagem: os ajustes. Um anel com oito dentes curtos, para não se
/// confundir com o filtro de lista (27/11/2026).
void drawGear(Path p) {
  const center = Offset(12, 12);
  p
    ..addOval(Rect.fromCircle(center: center, radius: 3))
    ..addOval(Rect.fromCircle(center: center, radius: 6.5));
  for (var i = 0; i < 8; i++) {
    final angle = i * math.pi / 4;
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    p
      ..moveTo(12 + dx * 6.5, 12 + dy * 6.5)
      ..lineTo(12 + dx * 9, 12 + dy * 9);
  }
}

/// Lupa: buscar. Um círculo e o cabo na diagonal de baixo.
void drawSearch(Path p) {
  p
    ..addOval(Rect.fromCircle(center: const Offset(10.5, 10.5), radius: 6.5))
    ..moveTo(15.2, 15.2)
    ..lineTo(20, 20);
}

/// Olho: os valores estão à vista. O mesmo desenho do olho do widget.
void drawEye(Path p) {
  _drawEyeLids(p);
  p.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 3));
}

/// Olho riscado: os valores estão escondidos.
void drawEyeOff(Path p) {
  _drawEyeLids(p);
  p
    ..moveTo(4, 4)
    ..lineTo(20, 20);
}

void _drawEyeLids(Path p) {
  p
    ..moveTo(2, 12)
    ..cubicTo(4.5, 7, 8, 5, 12, 5)
    ..cubicTo(16, 5, 19.5, 7, 22, 12)
    ..cubicTo(19.5, 17, 16, 19, 12, 19)
    ..cubicTo(8, 19, 4.5, 17, 2, 12)
    ..close();
}
