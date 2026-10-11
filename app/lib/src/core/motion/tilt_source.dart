import 'package:design_system/design_system.dart';

/// Uma leitura da inclinação em andamento: o valor que os enfeites seguem e
/// o jeito de parar o sensor.
typedef TiltReading = ({CajuiTilt tilt, void Function() close});

/// De onde vem a inclinação do aparelho, para o pote de água e os cartões
/// 3D balançarem (escolha 1 e 2 do dono, em 11/10/2026).
///
/// É enfeite, nunca informação: sem fonte — na web, no teste —, os
/// componentes ficam parados e continuam completos.
abstract interface class TiltSource {
  /// Começa a ler; `null` quando o aparelho não tem o que ler.
  TiltReading? open();
}
