import 'package:cajui/src/features/receipts/application/capture_service.dart';
import 'package:cajui/src/features/receipts/application/capture_shelf.dart';
import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:cajui/src/features/receipts/application/receipt_inbox.dart';
import 'package:cajui/src/features/receipts/application/receipt_reader.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Por onde chegam os compartilhamentos. A raiz do app liga ao módulo nativo.
final receiptInboxProvider = Provider<ReceiptInbox>(
  (ref) => throw StateError('receiptInboxProvider sem override na raiz.'),
);

/// Quem lê o texto do comprovante. A raiz do app liga ao módulo nativo.
final receiptReaderProvider = Provider<ReceiptReader>(
  (ref) => throw StateError('receiptReaderProvider sem override na raiz.'),
);

/// Onde ficam as capturas pendentes e as regras aprendidas.
final captureShelfProvider = Provider<CaptureShelf>(
  (ref) => throw StateError('captureShelfProvider sem override na raiz.'),
);

/// Quem classifica. No aparelho, as regras — que não dependem de rede. A IA
/// entra por cima quando o aparelho estiver cadastrado no servidor; até lá,
/// e sempre que ela faltar, a proposta é a das regras (RN-780, RN-784).
final receiptClassifierProvider = Provider<ReceiptClassifier>(
  (ref) => const RuleBasedClassifier(),
);

/// Os casos de uso da captura.
final captureServiceProvider = Provider<CaptureService>(CaptureService.new);

/// A lista "Para conferir". Quem guarda, confirma ou descarta uma captura a
/// invalida, e a tela relê.
final pendingCapturesProvider = FutureProvider<List<PendingCapture>>(
  (ref) => ref.watch(captureShelfProvider).pending(),
);
