import 'dart:math' as math;
import 'dart:ui';

/// Os ícones de traço da interface, desenhados numa grade de 24.
///
/// São caminhos, e não uma fonte de ícones nem SVG: o design system fica sem
/// dependência, o traço de 1,75 px e as pontas redondas — o mesmo gesto da
/// castanha do logo — valem para todos, e a cor é sempre herdada.
///
/// Os conceitos próprios do produto têm desenho próprio: o vale é um cartão
/// com garfo (vale não é dinheiro, então nada de cifrão) e a dívida é uma
/// escada que desce (parcelas que acabam).
enum CajuiIconData {
  /// Comprovante.
  receipt(_receipt),

  /// Cartão de crédito: forma de pagamento.
  card(_card),

  /// Carteira: dinheiro.
  wallet(_wallet),

  /// Vale alimentação.
  voucher(_voucher),

  /// Dívida: escada descendo.
  debt(_debt),

  /// Calendário: mês, vencimento.
  calendar(_calendar),

  /// Gráfico de barras.
  chart(_chart),

  /// Conversa com o assistente.
  chat(_chat),

  /// Compartilhar.
  share(_share),

  /// Som.
  sound(_sound),

  /// Confirmado.
  check(_check),

  /// Fechar.
  close(_close),

  /// Adicionar, lançar.
  plus(_plus),

  /// Avançar.
  chevronRight(_chevronRight),

  /// Voltar.
  chevronLeft(_chevronLeft),

  /// Ajustes: dois controles deslizantes, e não engrenagem — o que se faz
  /// ali é regular, não consertar.
  sliders(_sliders),

  /// Informação e aviso.
  info(_info),

  /// Sem rede.
  offline(_offline);

  new(this.build);

  /// Acrescenta o desenho do ícone a um caminho, na grade de 24 × 24.
  final void Function(Path path) build;
}

Rect _box(double l, double t, double w, double h) => Rect.fromLTWH(l, t, w, h);

void _line(Path p, double x1, double y1, double x2, double y2) => p
  ..moveTo(x1, y1)
  ..lineTo(x2, y2);

void _roundedBox(Path p, Rect rect, [double radius = 3]) =>
    p.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

void _receipt(Path p) {
  p
    ..moveTo(6, 3)
    ..lineTo(18, 3)
    ..lineTo(18, 21)
    ..lineTo(15, 19)
    ..lineTo(12, 21)
    ..lineTo(9, 19)
    ..lineTo(6, 21)
    ..close();
  _line(p, 9, 8, 15, 8);
  _line(p, 9, 12, 15, 12);
}

void _card(Path p) {
  _roundedBox(p, _box(3, 6, 18, 13));
  _line(p, 3, 10.5, 21, 10.5);
  _line(p, 7, 15, 10, 15);
}

void _wallet(Path p) {
  _roundedBox(p, _box(4, 7, 16, 13), 2);
  p
    ..moveTo(4, 7)
    ..lineTo(14, 4)
    ..lineTo(14, 7)
    ..addOval(Rect.fromCircle(center: const Offset(16, 13.5), radius: 1.2));
}

void _voucher(Path p) {
  _roundedBox(p, _box(3, 6, 18, 13));
  _line(p, 9, 9.5, 9, 16);
  _line(p, 7.5, 9.5, 7.5, 12);
  _line(p, 10.5, 9.5, 10.5, 12);
  _line(p, 7.5, 12, 10.5, 12);
  _line(p, 14, 12.5, 18, 12.5);
}

void _debt(Path p) {
  p
    ..moveTo(4, 6)
    ..lineTo(9, 6)
    ..lineTo(9, 11)
    ..lineTo(14, 11)
    ..lineTo(14, 16)
    ..lineTo(20, 16);
  _line(p, 4, 20, 20, 20);
}

void _calendar(Path p) {
  _roundedBox(p, _box(4, 5, 16, 15));
  _line(p, 8, 3, 8, 7);
  _line(p, 16, 3, 16, 7);
  _line(p, 4, 10, 20, 10);
}

void _chart(Path p) {
  _line(p, 4, 20, 20, 20);
  _line(p, 7, 16, 7, 12);
  _line(p, 12, 16, 12, 8);
  _line(p, 17, 16, 17, 9);
}

void _chat(Path p) {
  p
    ..moveTo(5, 5)
    ..lineTo(19, 5)
    ..arcToPoint(const Offset(21, 7), radius: const Radius.circular(2))
    ..lineTo(21, 15)
    ..arcToPoint(const Offset(19, 17), radius: const Radius.circular(2))
    ..lineTo(12, 17)
    ..lineTo(7, 21)
    ..lineTo(7, 17)
    ..lineTo(5, 17)
    ..arcToPoint(const Offset(3, 15), radius: const Radius.circular(2))
    ..lineTo(3, 7)
    ..arcToPoint(const Offset(5, 5), radius: const Radius.circular(2));
}

void _share(Path p) {
  for (final center in const [Offset(6, 12), Offset(17, 6), Offset(17, 18)]) {
    p.addOval(Rect.fromCircle(center: center, radius: 2.4));
  }
  _line(p, 8.2, 10.9, 14.8, 7.2);
  _line(p, 8.2, 13.1, 14.8, 16.8);
}

void _sound(Path p) {
  p
    ..moveTo(4, 10)
    ..lineTo(4, 14)
    ..lineTo(7, 14)
    ..lineTo(12, 18)
    ..lineTo(12, 6)
    ..lineTo(7, 10)
    ..close()
    ..addArc(
      Rect.fromCircle(center: const Offset(13, 12), radius: 4.5),
      -math.pi / 3.2,
      math.pi / 1.6,
    )
    ..addArc(
      Rect.fromCircle(center: const Offset(13, 12), radius: 8),
      -math.pi / 3.6,
      math.pi / 1.8,
    );
}

void _check(Path p) => p
  ..moveTo(5, 12.5)
  ..lineTo(10, 17.5)
  ..lineTo(19, 7);

void _close(Path p) {
  _line(p, 6, 6, 18, 18);
  _line(p, 18, 6, 6, 18);
}

void _plus(Path p) {
  _line(p, 12, 5, 12, 19);
  _line(p, 5, 12, 19, 12);
}

void _chevronRight(Path p) => p
  ..moveTo(9, 5)
  ..lineTo(16, 12)
  ..lineTo(9, 19);

void _chevronLeft(Path p) => p
  ..moveTo(15, 5)
  ..lineTo(8, 12)
  ..lineTo(15, 19);

void _sliders(Path p) {
  // O trilho para na borda do botão: ícone de traço não tem preenchimento
  // para esconder a linha que passaria por dentro dele.
  _line(p, 4, 8, 6.5, 8);
  _line(p, 11.5, 8, 20, 8);
  _line(p, 4, 16, 12.5, 16);
  _line(p, 17.5, 16, 20, 16);
  p
    ..addOval(Rect.fromCircle(center: const Offset(9, 8), radius: 2.5))
    ..addOval(Rect.fromCircle(center: const Offset(15, 16), radius: 2.5));
}

void _info(Path p) {
  p.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9));
  _line(p, 12, 11, 12, 16.5);
  _line(p, 12, 7.6, 12, 7.7);
}

void _offline(Path p) {
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
    );
  _line(p, 12, 18, 12, 18.1);
  _line(p, 4, 4, 20, 20);
}
