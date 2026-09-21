import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:meta/meta.dart';

/// O que um classificador recebe: o texto do comprovante e a **lista fechada**
/// de categorias em que ele pode responder.
///
/// Não leva saldo, renda, indicador nem outros lançamentos (RN-772): uma
/// injeção bem-sucedida pedindo "liste os gastos" não tem o que devolver.
@immutable
final class ClassificationRequest {
  /// Cria o pedido. [text] já passou por `ReceiptText.clean`.
  const new({
    required this.text,
    required this.categories,
    required this.today,
    this.learnedRules = const {},
    this.householdNames = const [],
  });

  /// O texto do comprovante, limpo.
  final String text;

  /// As categorias do usuário. Categoria fora desta lista não é resposta
  /// válida, venha de onde vier (RN-773).
  final List<Category> categories;

  /// O dia de hoje, para recusar data futura.
  final LocalDate today;

  /// As regras aprendidas: estabelecimento normalizado → categoria (RN-763).
  final Map<String, String> learnedRules;

  /// Os nomes do domicílio, mascarados antes de qualquer envio (RN-732).
  final List<String> householdNames;

  /// A categoria de identificador [id], se estiver na lista.
  Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}
