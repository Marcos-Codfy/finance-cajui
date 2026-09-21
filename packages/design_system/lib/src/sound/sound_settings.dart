import 'package:design_system/src/sound/sound_category.dart';
import 'package:flutter/foundation.dart';

/// As preferências de som e de toque do usuário.
///
/// O padrão é **tudo desligado** — decisão do dono do produto e requisito de
/// acessibilidade (RNF-A11Y-17). O onboarding oferece ligar, com prévia.
@immutable
class SoundSettings {
  /// Cria as preferências.
  const new({
    this.soundEnabled = false,
    this.hapticsEnabled = true,
    this.volume = 1,
    this.categories = const {
      SoundCategory.touches,
      SoundCategory.confirmations,
      SoundCategory.ambient,
    },
  });

  /// Se o som está ligado. Nasce desligado.
  final bool soundEnabled;

  /// Se a resposta tátil está ligada. Segue também a configuração do sistema.
  final bool hapticsEnabled;

  /// O volume próprio do app, de 0 a 1.
  ///
  /// Nasce no máximo: quem manda no quanto o som aparece é o volume do
  /// aparelho, e cortar aqui por padrão só tirava alcance — no celular, o
  /// som sumia fora do volume máximo do sistema.
  final double volume;

  /// As famílias de som ligadas.
  final Set<SoundCategory> categories;

  /// Se um som da família [category] pode tocar.
  bool allows(SoundCategory category) =>
      soundEnabled && categories.contains(category);

  /// Devolve as preferências com as mudanças pedidas.
  SoundSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    double? volume,
    Set<SoundCategory>? categories,
  }) {
    return SoundSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      volume: volume ?? this.volume,
      categories: categories ?? this.categories,
    );
  }
}
