import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O que a pessoa pediu para ver na lista de lançamentos: um mês e, se
/// quiser, um pedaço da descrição, uma categoria e uma forma de pagamento.
///
/// É valor puro, sem tela nem livro: filtrar é decidir quais lançamentos
/// ficam, e isso se testa com uma lista na mão. Não há conta de dinheiro
/// aqui — o gasto do mês continua vindo do livro, inteiro, e não da soma do
/// que sobrou na lista filtrada.
@immutable
final class EntryFilter {
  /// Cria o filtro do mês [month], sem nenhum outro recorte por padrão.
  const new({
    required this.month,
    this.text = '',
    this.categoryId,
    this.paymentMethodId,
  });

  /// O mês à vista.
  final BudgetMonth month;

  /// O que foi digitado na busca, como foi digitado.
  final String text;

  /// A categoria escolhida, ou `null` para todas.
  final String? categoryId;

  /// A forma de pagamento escolhida, ou `null` para todas.
  final String? paymentMethodId;

  /// A busca já dobrada. Só espaço não é busca: quem apagou o texto e deixou
  /// um espaço não pode ficar sem lista.
  String get _needle => _fold(text);

  /// Se há algum recorte além do mês. O mês sempre existe; é a busca, a
  /// categoria e a forma de pagamento que podem esvaziar a lista sozinhas.
  bool get isNarrowed =>
      _needle.isNotEmpty || categoryId != null || paymentMethodId != null;

  /// Se [entry] passa por todos os recortes ao mesmo tempo.
  bool matches(Entry entry) =>
      month.contains(entry.occurredOn) &&
      _hasText(entry) &&
      (categoryId == null || entry.categoryId == categoryId) &&
      _paidWith(entry);

  /// Os lançamentos de [entries] que passam, do mais recente para o mais
  /// antigo — a mesma ordem da lista sem filtro.
  List<Entry> apply(Iterable<Entry> entries) =>
      entries.where(matches).toList()
        ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));

  /// O mesmo filtro com a busca [text].
  EntryFilter withText(String text) => _copy(text: text);

  /// O mesmo filtro no mês [month].
  EntryFilter withMonth(BudgetMonth month) => _copy(month: month);

  /// O mesmo filtro com a categoria [id]; `null` volta a todas.
  EntryFilter withCategory(String? id) => EntryFilter(
    month: month,
    text: text,
    categoryId: id,
    paymentMethodId: paymentMethodId,
  );

  /// O mesmo filtro com a forma de pagamento [id]; `null` volta a todas.
  EntryFilter withPaymentMethod(String? id) => EntryFilter(
    month: month,
    text: text,
    categoryId: categoryId,
    paymentMethodId: id,
  );

  /// O mesmo mês, sem busca, categoria nem forma de pagamento.
  EntryFilter get cleared => EntryFilter(month: month);

  EntryFilter _copy({BudgetMonth? month, String? text}) => EntryFilter(
    month: month ?? this.month,
    text: text ?? this.text,
    categoryId: categoryId,
    paymentMethodId: paymentMethodId,
  );

  bool _hasText(Entry entry) {
    final needle = _needle;
    return needle.isEmpty || _fold(entry.description).contains(needle);
  }

  /// Pagamento dividido aparece nas duas formas: a compra que saiu metade no
  /// vale e metade no Pix também foi paga no Pix (RN-204).
  bool _paidWith(Entry entry) =>
      paymentMethodId == null ||
      entry.paymentLines.any((line) => line.paymentMethodId == paymentMethodId);

  @override
  bool operator ==(Object other) =>
      other is EntryFilter &&
      other.month == month &&
      other.text == text &&
      other.categoryId == categoryId &&
      other.paymentMethodId == paymentMethodId;

  @override
  int get hashCode => Object.hash(month, text, categoryId, paymentMethodId);

  /// As letras com acento que se escrevem em português, e as poucas de nome
  /// estrangeiro que aparecem em comprovante.
  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n',
  };

  static final _spaces = RegExp(r'\s+');

  /// Minúsculas, sem acento e com um espaço só entre as palavras.
  ///
  /// Não é a normalização do domínio (`PossibleDuplicate.normalize`): aquela
  /// tira número e "Ltda." porque compara estabelecimentos, e quem busca
  /// "99" ou "ltda" quer achar exatamente isso.
  static String _fold(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().replaceAll(_spaces, ' ').trim();
  }
}
