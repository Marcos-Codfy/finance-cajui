import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:persistence/persistence.dart';

/// No aparelho, o registro é o arquivo de eventos cifrado, na pasta privada
/// do app — a que o Android não mostra a nenhum outro app.
Future<EventStore> openEventStore() async {
  final support = await getApplicationSupportDirectory();
  return await openEventStoreAt(Directory(p.join(support.path, 'ledger')));
}

/// O mesmo, numa pasta dada. Existe para o teste usar uma pasta temporária.
Future<EventStore> openEventStoreAt(Directory directory) {
  directory.createSync(recursive: true);
  return FileEventStore.open(
    directory,
    AesGcmRecordCipher(_dataKey(directory)),
  );
}

/// A chave que cifra o registro, criada na primeira abertura.
///
/// Por ora ela fica ao lado do registro, na pasta privada do app: protege de
/// quem copia só o arquivo de dados, não de quem alcança a pasta inteira. O
/// lugar definitivo é o Keystore do Android, liberado por biometria — item
/// BL-032 do backlog, que chega com o passo de biometria.
List<int> _dataKey(Directory directory) {
  final file = File(p.join(directory.path, 'data.key'));
  if (!file.existsSync()) file.writeAsStringSync(DataKey.generate());
  return DataKey.read(file.path);
}
