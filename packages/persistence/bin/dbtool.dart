import 'dart:io';

import 'package:persistence/src/db_tool.dart';

/// Ponto de entrada do `dbtool`. A lógica mora em `DbTool`, para poder ser
/// testada sem abrir um processo.
Future<void> main(List<String> arguments) async {
  exitCode = await DbTool(stdout).run(arguments);
}
