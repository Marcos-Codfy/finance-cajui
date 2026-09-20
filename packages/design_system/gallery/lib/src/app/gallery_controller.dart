import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// As escolhas de quem está olhando a gallery: tema, versão da falta do mês,
/// nível de movimento e som.
///
/// Fica num lugar só para que qualquer página mostre o mesmo componente sob
/// outra condição sem precisar de estado próprio — é assim que se confere um
/// estado nos dois temas em dois toques.
class GalleryController extends ChangeNotifier {
  Brightness _brightness = Brightness.light;
  ShortfallStyle _shortfallStyle = ShortfallStyle.calm;
  MotionLevel _motionLevel = MotionLevel.full;
  SoundSettings _sound = const SoundSettings();

  /// O tema em vigor, claro ou escuro.
  Brightness get brightness => _brightness;

  /// A versão da falta do mês em vigor.
  ShortfallStyle get shortfallStyle => _shortfallStyle;

  /// O nível de movimento em vigor.
  MotionLevel get motionLevel => _motionLevel;

  /// As preferências de som e de toque em vigor.
  SoundSettings get sound => _sound;

  /// O tema montado a partir das escolhas.
  CajuiThemeData get theme => switch (_brightness) {
    Brightness.light => CajuiThemeData.light(
      shortfallStyle: _shortfallStyle,
      motionLevel: _motionLevel,
    ),
    Brightness.dark => CajuiThemeData.dark(
      shortfallStyle: _shortfallStyle,
      motionLevel: _motionLevel,
    ),
  };

  /// Alterna entre o tema claro e o escuro.
  void toggleBrightness() {
    _brightness = switch (_brightness) {
      Brightness.light => Brightness.dark,
      Brightness.dark => Brightness.light,
    };
    notifyListeners();
  }

  /// Troca a versão da falta do mês.
  void useShortfallStyle(ShortfallStyle style) {
    _shortfallStyle = style;
    notifyListeners();
  }

  /// Troca o nível de movimento.
  void useMotionLevel(MotionLevel level) {
    _motionLevel = level;
    notifyListeners();
  }

  /// Troca as preferências de som e de toque.
  void useSound(SoundSettings settings) {
    _sound = settings;
    notifyListeners();
  }
}
