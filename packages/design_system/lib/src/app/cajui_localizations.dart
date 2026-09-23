import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Os textos de sistema que os componentes pedem ao Flutter.
///
/// O campo de texto do design system usa o do Material por dentro, e ele
/// exige estas localizações. Ficam aqui para o app não precisar importar o
/// Material só por causa disso — nem saber que ele existe.
///
/// São as **de verdade**, e não as de fábrica: as `Default…Localizations`
/// só falam inglês, e o menu de copiar, colar e selecionar do campo de texto
/// saía "Copy", "Paste", "Select all" num app inteiro em português
/// (BL-029). Isso arrasta o `flutter_localizations`, que traz as traduções
/// de todos os idiomas — por isso [locales] declara só o nosso, e o pacote
/// da web não carrega o resto.
abstract final class CajuiLocalizations {
  /// O que o `WidgetsApp` recebe em `localizationsDelegates`.
  static const List<LocalizationsDelegate<Object?>> delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Os idiomas que o app declara. É um só, e de propósito: o Cajui é escrito
  /// em português do Brasil, do texto da tela ao nome do botão de colar.
  static const List<Locale> locales = [Locale('pt', 'BR')];
}
