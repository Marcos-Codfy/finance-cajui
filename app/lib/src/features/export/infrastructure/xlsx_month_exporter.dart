import 'package:cajui/src/features/export/application/month_exporter.dart';
import 'package:cajui/src/features/export/infrastructure/file_hand_off.dart';
import 'package:cajui/src/features/export/infrastructure/month_workbook.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_writer.dart';
import 'package:domain/domain.dart';

/// O mês em `.xlsx`, entregue por [_handOff] (RN-1090).
final class XlsxMonthExporter implements MonthExporter {
  /// Cria o exportador sobre a entrega [_handOff].
  const new(this._handOff);

  final FileHandOff _handOff;

  @override
  Future<void> export(MonthExport month) => _handOff.handOff(
    name: MonthWorkbook.fileName(month.month),
    mimeType: XlsxWriter.mimeType,
    bytes: XlsxWriter.write(MonthWorkbook.of(month)),
  );
}
