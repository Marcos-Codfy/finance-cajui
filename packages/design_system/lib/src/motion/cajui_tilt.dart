import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// A inclinação do aparelho, como o design system a entende.
///
/// O design system não lê sensor: isso pediria um plugin e uma permissão, e
/// ele precisa rodar igual na gallery, na web e no teste. Quem lê o sensor é
/// o app, que entrega aqui um `Offset` normalizado de -1 a 1 em cada eixo:
///
/// - `dx`: o lado. Positivo quando o aparelho gira para a direita (sentido
///   horário, a borda direita descendo). No acelerômetro do Android, é
///   `-x / 9,81` — o seno do ângulo.
/// - `dy`: frente e trás. Positivo quando o topo vem na direção de quem
///   segura. Quem lê o sensor desconta a pose de repouso (o celular na mão
///   costuma ficar a uns 40°), para o neutro ser `Offset.zero`.
///
/// Sem fonte nenhuma, os componentes ficam parados e continuam completos: a
/// inclinação é enfeite, nunca informação.
typedef CajuiTilt = ValueListenable<Offset>;
