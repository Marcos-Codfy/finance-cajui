import 'package:domain/src/statements/line_treatment.dart';
import 'package:meta/meta.dart';

/// Uma resposta da pessoa, lembrada pela chave do estabelecimento
/// (RN-1116): "PADARIA BOA VISTA é Padaria", "João P Silva é alguém da
/// casa".
///
/// Vai e volta entre os celulares como fato (ADR-030). Responder de novo
/// grava outra, e a mais nova vence; esquecer grava uma vazia. Por isso a
/// resposta é sempre completa: quem responde a categoria depois de "É um
/// gasto" grava as duas coisas juntas ([merging]), ou a categoria apagaria
/// o tipo.
@immutable
final class LearnedAnswer {
  /// Cria a resposta.
  const new({
    required this.key,
    required this.definedAt,
    this.categoryId,
    this.treatment,
    this.aboutPerson = false,
  });

  /// A chave do estabelecimento: a marca, o nome normalizado (RN-727) ou,
  /// para Pix com pessoa, o nome dela.
  final String key;

  /// A categoria escolhida, quando a resposta foi de categoria.
  final String? categoryId;

  /// O que a linha é, quando a resposta foi de tipo.
  final LineTreatment? treatment;

  /// Se a chave é o nome de uma pessoa. Resposta de pessoa nunca vira
  /// exemplo para a IA (RN-1107).
  final bool aboutPerson;

  /// Quando foi dada: entre duas, vale a mais nova.
  final DateTime definedAt;

  /// Sem categoria e sem tipo: a resposta foi esquecida.
  bool get isForgotten => categoryId == null && treatment == null;

  /// Esta resposta somada ao que [known] já dizia: o que esta não diz vem
  /// de lá.
  LearnedAnswer merging(LearnedAnswer? known) => LearnedAnswer(
    key: key,
    definedAt: definedAt,
    categoryId: categoryId ?? known?.categoryId,
    treatment: treatment ?? known?.treatment,
    aboutPerson: aboutPerson || (known?.aboutPerson ?? false),
  );
}
