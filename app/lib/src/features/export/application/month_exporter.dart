import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quem transforma o mês num arquivo e o entrega (RN-1090): no celular, pela
/// tela de compartilhar do Android; na web, como download.
abstract interface class MonthExporter {
  /// Entrega [month] como planilha.
  Future<void> export(MonthExport month);
}

/// O exportador. A raiz do app decide qual.
final monthExporterProvider = Provider<MonthExporter>(
  (ref) => throw StateError('monthExporterProvider sem override na raiz.'),
);
