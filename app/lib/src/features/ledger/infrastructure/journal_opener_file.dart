import 'dart:io';

import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:persistence/persistence.dart';

/// No aparelho, o livro é o registro de eventos cifrado, na pasta privada do
/// app — a que o Android não mostra a nenhum outro app.
Future<LedgerJournal> openLedgerJournal() async {
  final support = await getApplicationSupportDirectory();
  return await openLedgerJournalAt(Directory(p.join(support.path, 'ledger')));
}

/// O mesmo, numa pasta dada. Existe para o teste usar uma pasta temporária.
Future<LedgerJournal> openLedgerJournalAt(Directory directory) async {
  directory.createSync(recursive: true);
  final store = await FileEventStore.open(
    directory,
    AesGcmRecordCipher(_dataKey(directory)),
  );
  return EventStoreLedgerJournal(
    store: store,
    codec: const LedgerEventCodec(categoryOf: _defaultCategory),
  );
}

Category _defaultCategory(String id) => DefaultCatalog.emptyBook.categoryOf(id);

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
