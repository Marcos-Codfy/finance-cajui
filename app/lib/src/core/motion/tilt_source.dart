import 'package:design_system/design_system.dart';

/// Uma leitura da inclinação em andamento: o valor que os enfeites seguem e
/// o jeito de parar o sensor.
typedef TiltReading = ({CajuiTilt tilt, void Function() close});

/// De onde vem a inclinação do aparelho, para os cartões 3D balançarem
/// (escolha 2 do dono, em 11/10/2026; o pote da escolha 1 saiu no mesmo
/// dia, com o limite da semana).
///
/// É enfeite, nunca informação: sem fonte — na web, no teste —, os
/// componentes ficam parados e continuam completos.
abstract interface class TiltSource {
  /// Começa a ler; `null` quando o aparelho não tem o que ler.
  TiltReading? open();
}
