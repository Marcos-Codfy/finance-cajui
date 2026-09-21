import 'dart:io';

import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:test/test.dart';

const sampleGroceries = Category(
  id: 'groceries',
  name: 'Mercado',
  block: Block.variable,
  groupId: 'food',
);
const sampleRent = Category(
  id: 'rent',
  name: 'Aluguel',
  block: Block.fixed,
  groupId: 'housing',
);

const sampleCoupon = r'''
MERCADO BOA COMPRA LTDA
TOTAL R$ 86,40
DEBITO
12/09/2026''';

ClassificationRequest sampleRequest(String text) => ClassificationRequest(
  text: ReceiptText.clean(text),
  categories: const [sampleGroceries, sampleRent],
  today: LocalDate(2026, 9, 20),
);

Future<TokenBudget> sampleBudget({int limit = 1000000}) async {
  final directory = Directory.systemTemp.createTempSync('cajui-ai-');
  addTearDown(() => directory.deleteSync(recursive: true));
  final store = await FileEventStore.open(
    directory,
    AesGcmRecordCipher(List.generate(32, (i) => i)),
  );
  return TokenBudget(store, monthlyLimit: limit);
}
