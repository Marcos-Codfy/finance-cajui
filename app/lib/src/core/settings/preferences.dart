import 'package:meta/meta.dart';

/// O que a pessoa escolheu e espera encontrar do mesmo jeito amanhã.
///
/// São três chaves, e só elas: som, vibração e tema. Nada aqui é fato
/// financeiro — é preferência —, mas mora no mesmo registro cifrado do
/// resto, porque um segundo lugar para guardar coisa seria um segundo lugar
/// para esquecer de cifrar.
@immutable
final class Preferences {
  /// Cria as preferências. Os padrões são os de quem abre o app pela
  /// primeira vez: som desligado (som inesperado em lugar público
  /// constrange), vibração ligada e tema claro (o que se lê no sol).
  const new({
    this.soundEnabled = false,
    this.hapticsEnabled = true,
    this.dark = false,
  });

  /// Lê o que foi gravado. Campo que falta volta ao padrão: um registro
  /// gravado por uma versão mais antiga continua servindo.
  factory fromJson(Map<String, Object?> json) => Preferences(
    soundEnabled: json['soundEnabled'] as bool? ?? false,
    hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    dark: json['dark'] as bool? ?? false,
  );

  /// Se os sons tocam.
  final bool soundEnabled;

  /// Se o toque vibra.
  final bool hapticsEnabled;

  /// Se o tema escuro está ligado.
  final bool dark;

  /// As mesmas preferências com as partes dadas trocadas.
  Preferences copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? dark,
  }) => Preferences(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    dark: dark ?? this.dark,
  );

  /// O que gravar.
  Map<String, Object?> toJson() => {
    'soundEnabled': soundEnabled,
    'hapticsEnabled': hapticsEnabled,
    'dark': dark,
  };

  @override
  bool operator ==(Object other) =>
      other is Preferences &&
      other.soundEnabled == soundEnabled &&
      other.hapticsEnabled == hapticsEnabled &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(soundEnabled, hapticsEnabled, dark);
}
