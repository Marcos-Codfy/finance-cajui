import 'dart:typed_data';

import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/receipts/merchant_kind.dart';
import 'package:meta/meta.dart';

/// O que um classificador recebe: o texto do comprovante e a **lista fechada**
/// de categorias em que ele pode responder.
///
/// Não leva saldo, renda, indicador nem outros lançamentos (RN-772): uma
/// injeção bem-sucedida pedindo "liste os gastos" não tem o que devolver.
///
/// Pode levar as **imagens** do documento (ADR-022): a foto, o print, as
/// primeiras páginas do PDF, em JPEG. A IA as lê junto com o texto que o
/// celular extraiu — o texto confere os dígitos, a imagem corrige o que o
/// leitor do celular errou.
@immutable
final class ClassificationRequest {
  /// Cria o pedido. [text] já passou por `ReceiptText.clean`.
  const new({
    required this.text,
    required this.categories,
    required this.today,
    this.learnedRules = const {},
    this.personalRules = const {},
    this.categoryByMerchantKind = const {},
    this.householdNames = const [],
    this.images = const [],
  });

  /// O texto do comprovante, limpo.
  final String text;

  /// As categorias do usuário. Categoria fora desta lista não é resposta
  /// válida, venha de onde vier (RN-773).
  final List<Category> categories;

  /// O dia de hoje, para recusar data futura.
  final LocalDate today;

  /// As regras aprendidas: estabelecimento normalizado → categoria (RN-763).
  /// São também os exemplos que vão para a IA (RN-769): por isso aqui nunca
  /// entra regra que fala de pessoa (RN-1107).
  final Map<String, String> learnedRules;

  /// As regras aprendidas que falam de pessoa — "Pix para João P Silva é
  /// Serviços". Valem nas regras do celular, como [learnedRules], e nunca
  /// saem dele: nenhum classificador as manda adiante (RN-1107).
  final Map<String, String> personalRules;

  /// Que categoria cada ramo de estabelecimento significa neste cadastro.
  ///
  /// É o que deixa um cupom de supermercado nascer como compra de mercado sem
  /// a IA e sem ninguém ter ensinado nada: o ramo é lido do nome pelo
  /// domínio, e o cadastro diz em que categoria ele cai.
  final Map<MerchantKind, String> categoryByMerchantKind;

  /// Os nomes do domicílio, mascarados antes de qualquer envio (RN-732).
  final List<String> householdNames;

  /// As imagens do documento, em JPEG, no máximo três. Vazio quando o que
  /// chegou foi texto.
  final List<Uint8List> images;

  /// Se há imagem para a IA ver.
  bool get hasImages => images.isNotEmpty;

  /// O mesmo pedido, só com o texto: o que se faz quando a IA não aceita a
  /// imagem.
  ClassificationRequest withoutImages() => ClassificationRequest(
    text: text,
    categories: categories,
    today: today,
    learnedRules: learnedRules,
    personalRules: personalRules,
    categoryByMerchantKind: categoryByMerchantKind,
    householdNames: householdNames,
  );

  /// A categoria de identificador [id], se estiver na lista.
  Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}
