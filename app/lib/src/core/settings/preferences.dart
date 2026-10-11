import 'package:meta/meta.dart';

/// O que a pessoa escolheu e espera encontrar do mesmo jeito amanhã.
///
/// São quatro chaves, e só elas: som, vibração, tema e o último mês que
/// ganhou a festa de fechar no verde. Nada aqui é fato
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
    this.celebratedMonth,
  });

  /// Lê o que foi gravado. Campo que falta volta ao padrão: um registro
  /// gravado por uma versão mais antiga continua servindo.
  factory fromJson(Map<String, Object?> json) => Preferences(
    soundEnabled: json['soundEnabled'] as bool? ?? false,
    hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    dark: json['dark'] as bool? ?? false,
    celebratedMonth: json['celebratedMonth'] as String?,
  );

  /// Se os sons tocam.
  final bool soundEnabled;

  /// Se o toque vibra.
  final bool hapticsEnabled;

  /// Se o tema escuro está ligado.
  final bool dark;

  /// O mês (`2026-10`) que já ganhou a festa do brilho ao fechar no verde:
  /// a festa é uma vez por mês, senão deixaria de significar algo.
  final String? celebratedMonth;

  /// As mesmas preferências com as partes dadas trocadas.
  Preferences copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? dark,
    String? celebratedMonth,
  }) => Preferences(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    dark: dark ?? this.dark,
    celebratedMonth: celebratedMonth ?? this.celebratedMonth,
  );

  /// O que gravar.
  Map<String, Object?> toJson() => {
    'soundEnabled': soundEnabled,
    'hapticsEnabled': hapticsEnabled,
    'dark': dark,
    'celebratedMonth': ?celebratedMonth,
  };

  @override
  bool operator ==(Object other) =>
      other is Preferences &&
      other.soundEnabled == soundEnabled &&
      other.hapticsEnabled == hapticsEnabled &&
      other.dark == dark &&
      other.celebratedMonth == celebratedMonth;

  @override
  int get hashCode =>
      Object.hash(soundEnabled, hapticsEnabled, dark, celebratedMonth);
}
