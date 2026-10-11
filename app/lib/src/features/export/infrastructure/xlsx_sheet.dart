import 'package:cajui/src/features/export/infrastructure/xlsx_cell.dart';
import 'package:meta/meta.dart';

/// Uma aba da planilha: o nome, a largura de cada coluna, em caracteres, e as
/// linhas, de cima para baixo.
@immutable
final class XlsxSheet {
  /// Cria a aba [name]. Com [frozenRows], as primeiras linhas ficam paradas
  /// ao rolar — o título das colunas à vista no mês de cem lançamentos.
  const new({
    required this.name,
    required this.widths,
    required this.rows,
    this.frozenRows = 0,
  });

  /// O nome que aparece na aba. O Excel aceita até 31 caracteres.
  final String name;

  /// A largura de cada coluna, na ordem.
  final List<double> widths;

  /// As linhas.
  final List<List<XlsxCell>> rows;

  /// Quantas linhas do alto ficam paradas.
  final int frozenRows;
}
