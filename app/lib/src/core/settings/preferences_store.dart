import 'package:cajui/src/core/settings/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onde as preferências ficam entre uma abertura e outra.
///
/// É uma porta porque o lugar muda com a plataforma: no aparelho, o registro
/// cifrado; no navegador, lugar nenhum — lá a aba é a sessão, e guardar
/// preferência seria guardar rastro de quem só veio consultar.
abstract interface class PreferencesStore {
  /// O que está guardado agora. Nunca falha: sem nada gravado, devolve os
  /// padrões.
  Preferences read();

  /// Aplica [change] ao que está guardado e grava o resultado.
  ///
  /// É "mude esta parte", e não "grave tudo", **de propósito**. Dois
  /// controladores diferentes mexem nestas preferências — som e tema —, e
  /// cada um só conhece a parte dele. Com "grave tudo", ligar o som e trocar
  /// o tema em seguida fazia o segundo gravar por cima do primeiro, porque
  /// ele havia lido antes de a gravação anterior terminar.
  ///
  /// Não se espera por isto para mudar a tela: escolha que demora a valer
  /// parece não ter valido.
  Future<void> update(Preferences Function(Preferences current) change);
}

/// Onde as preferências moram. A raiz do app decide.
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => throw StateError('preferencesStoreProvider sem override na raiz.'),
);
