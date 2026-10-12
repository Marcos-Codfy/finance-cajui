import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O que a leitura de um extrato rendeu, página a página (ADR-030): as
/// movimentações, o texto original de cada página, o período, e o que não
/// deu para ler — dito, nunca em silêncio (RN-1101 a RN-1104).
///
/// Ainda não decide nada: cada linha vai ao `StatementLineResolver`, com o
/// texto original dela ([originalOf]), para virar certeza ou pergunta.
@immutable
final class StatementReading {
  /// Cria o resultado.
  const new({
    required this.lines,
    required this.originals,
    required this.pageCount,
    required this.pagesRead,
    this.period,
    this.failedPages = const [],
    this.partialPages = const [],
    this.beyondLimit = 0,
    this.failure,
  });

  /// As movimentações, na ordem das páginas, com a página e a linha de
  /// origem preenchidas e a data já com o ano do período (RN-1105).
  final List<StatementLine> lines;

  /// O texto original, sem máscara, de cada linha de cada página: a linha
  /// `n` da página `p` está em `originals[p - 1][n - 1]`. Nunca saiu do
  /// celular (RN-1106).
  final List<List<String>> originals;

  /// O mês do extrato: o que a primeira página que o escreve disse; senão
  /// o da maioria das datas. `null` sem movimentação nenhuma.
  final BudgetMonth? period;

  /// Quantas páginas os arquivos têm de verdade, mesmo as que ficaram de
  /// fora do limite: "Li as páginas 1 a 20 de 24" (RN-1101).
  final int pageCount;

  /// Quantas páginas foram entregues à leitura.
  final int pagesRead;

  /// As páginas que falharam duas vezes e ficaram de fora: "A página 4 não
  /// deu para ler" (RN-1102).
  final List<int> failedPages;

  /// As páginas lidas só em parte (RN-1103): o resumo avisa com `E-AI-05`.
  final List<int> partialPages;

  /// Quantas movimentações passaram do teto do extrato e ficaram de fora
  /// (RN-1104).
  final int beyondLimit;

  /// Por que a última página que falhou falhou: sem rede, IA fora do ar,
  /// teto de tokens.
  final ErrorCode? failure;

  /// O texto original da linha de onde [line] saiu, ou `null` quando a
  /// linha só apareceu na imagem.
  String? originalOf(StatementLine line) {
    final (page, number) = (line.page, line.sourceLine);
    if (page == null || number == null || page < 1) return null;
    final lines = originals.elementAtOrNull(page - 1);
    return number < 1 ? null : lines?.elementAtOrNull(number - 1);
  }

  /// Se tudo foi lido, sem nada de fora.
  bool get isComplete =>
      pagesRead >= pageCount &&
      failedPages.isEmpty &&
      partialPages.isEmpty &&
      beyondLimit == 0;
}
