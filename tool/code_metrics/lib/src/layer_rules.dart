/// As regras de importação por camada (ADR-001, ADR-002 e ADR-014).
///
/// Ficam num lugar só, em dado e não espalhadas em `if`, para a regra poder
/// ser lida de uma vez por quem chega ao projeto.
abstract final class LayerRules {
  /// O que o domínio pode importar. É lista do que **pode**, e não do que não
  /// pode: o domínio roda igual no app, no servidor e no teste, e qualquer
  /// dependência nova precisa ser uma decisão, não um descuido.
  static const _domainAllowed = [
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:core',
    'dart:math',
    'dart:typed_data',
    'package:domain/',
    'package:meta/',
  ];

  /// As bibliotecas que trazem aparência pronta de terceiros.
  static const _foreignKits = [
    'package:flutter/material.dart',
    'package:flutter/cupertino.dart',
  ];

  /// Camada de quem importa → camadas que ela não pode enxergar.
  static const _hidden = {
    'application': ['infrastructure', 'presentation'],
    'presentation': ['infrastructure'],
    'infrastructure': ['presentation'],
  };

  /// Se o arquivo em [path] está proibido de definir aparência: todo o código
  /// do app. Cor, tipo e duração moram no design system.
  static bool ownsNoAppearance(String path) => path.startsWith('app/lib/');

  /// Por que [path] não pode importar [uri], ou `null` se pode.
  static String? refusal(String path, String uri) {
    if (path.startsWith('packages/domain/lib/')) return _domain(uri);
    if (ownsNoAppearance(path) && _foreignKits.contains(uri)) {
      return 'o app não importa $uri; o que faltar entra no design system';
    }
    return _layer(path, uri);
  }

  static String? _domain(String uri) {
    if (_domainAllowed.any(uri.startsWith)) return null;
    return 'o domínio não importa $uri; ele só conhece Dart puro e a si mesmo';
  }

  static String? _layer(String path, String uri) {
    for (final MapEntry(key: layer, value: hidden) in _hidden.entries) {
      if (!path.contains('/$layer/')) continue;
      for (final other in hidden) {
        if (uri.contains('/$other/')) return '$layer não importa $other';
      }
    }
    return null;
  }
}
