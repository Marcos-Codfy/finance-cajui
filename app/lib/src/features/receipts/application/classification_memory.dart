import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/receipts/application/capture_shelf.dart';
import 'package:domain/domain.dart';

/// As regras aprendidas que a classificação do comprovante e da notificação
/// do banco usa: a memória das respostas, que atravessa os celulares
/// (RN-1116), por cima das regras antigas deste aparelho (RN-763).
///
/// Vêm separadas em duas, e o pedido ao classificador leva cada uma no seu
/// lugar: as que podem ir à IA como exemplo e as de pessoa, que valem só no
/// celular (RN-1107). A conta de qual vale é do domínio.
abstract final class ClassificationMemory {
  /// As regras a partir do livro [book] e da prateleira [shelf].
  static Future<LearnedRules> of(LedgerBook book, CaptureShelf shelf) async {
    final personal = await shelf.personalRules();
    final shared = await shelf.learnedRules();
    return LearnedRules.of(
      answers: book.answerHistory,
      legacy: {...personal, ...shared},
    );
  }
}
