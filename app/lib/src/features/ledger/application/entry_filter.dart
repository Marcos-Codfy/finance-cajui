import 'package:cajui/src/features/ledger/application/search_fold.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O que a pessoa pediu para ver na lista de lançamentos: um mês e, se
/// quiser, um pedaço da descrição, uma categoria, uma forma de pagamento, um
/// tipo de pagamento (só vale alimentação, só cartão) e uma semana.
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
    this.paymentKind,
    this.weekStart,
  });

  /// O mês à vista.
  final BudgetMonth month;

  /// O que foi digitado na busca, como foi digitado.
  final String text;

  /// A categoria escolhida, ou `null` para todas.
  final String? categoryId;

  /// A forma de pagamento escolhida, ou `null` para todas.
  final String? paymentMethodId;

  /// O tipo de pagamento dos atalhos "Só vale alimentação" e "Só cartão",
  /// ou `null` para todos. É o tipo, e não uma forma: a casa pode ter dois
  /// cartões, e "só cartão" quer os dois.
  final PaymentMethodKind? paymentKind;

  /// A segunda-feira da semana do atalho "Esta semana", ou `null` sem ele.
  final LocalDate? weekStart;

  String get _needle => SearchFold.of(text);

  /// Se há algum recorte além do mês. O mês sempre existe; os outros é que
  /// podem esvaziar a lista sozinhos.
  bool get isNarrowed =>
      _needle.isNotEmpty ||
      categoryId != null ||
      paymentMethodId != null ||
      paymentKind != null ||
      weekStart != null;

  /// Se [entry] passa por todos os recortes ao mesmo tempo.
  bool matches(Entry entry) =>
      month.contains(entry.occurredOn) &&
      _hasText(entry) &&
      (categoryId == null || entry.categoryId == categoryId) &&
      _paidWith(entry) &&
      _paidByKind(entry) &&
      _inWeek(entry.occurredOn);

  /// Os lançamentos de [entries] que passam, do mais recente para o mais
  /// antigo — a mesma ordem da lista sem filtro.
  List<Entry> apply(Iterable<Entry> entries) =>
      entries.where(matches).toList()
        ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));

  /// O mesmo filtro com a busca [text].
  EntryFilter withText(String text) => _with(text: text);

  /// O mesmo filtro no mês [month]. A semana sai: ela é a de hoje, e o mês
  /// novo pode nem contê-la.
  EntryFilter withMonth(BudgetMonth month) =>
      _with(month: month, weekStart: null);

  /// O mesmo filtro com a categoria [id]; `null` volta a todas.
  EntryFilter withCategory(String? id) => _with(categoryId: id);

  /// O mesmo filtro com a forma de pagamento [id]; `null` volta a todas.
  EntryFilter withPaymentMethod(String? id) => _with(paymentMethodId: id);

  /// O mesmo filtro só com o tipo [kind]; `null` volta a todos.
  EntryFilter withPaymentKind(PaymentMethodKind? kind) =>
      _with(paymentKind: kind);

  /// O mesmo filtro só com a semana de [day]; `null` tira a semana.
  EntryFilter withWeekOf(LocalDate? day) =>
      _with(weekStart: day?.addDays(1 - day.weekday));

  /// O mesmo mês, sem nenhum outro recorte.
  EntryFilter get cleared => EntryFilter(month: month);

  /// Marca de "não mexer": `null` é um valor válido (tirar o recorte), então
  /// não serve para dizer "mantenha o que está".
  static const Object _keep = Object();

  EntryFilter _with({
    BudgetMonth? month,
    String? text,
    Object? categoryId = _keep,
    Object? paymentMethodId = _keep,
    Object? paymentKind = _keep,
    Object? weekStart = _keep,
  }) => EntryFilter(
    month: month ?? this.month,
    text: text ?? this.text,
    categoryId: identical(categoryId, _keep)
        ? this.categoryId
        : categoryId as String?,
    paymentMethodId: identical(paymentMethodId, _keep)
        ? this.paymentMethodId
        : paymentMethodId as String?,
    paymentKind: identical(paymentKind, _keep)
        ? this.paymentKind
        : paymentKind as PaymentMethodKind?,
    weekStart: identical(weekStart, _keep)
        ? this.weekStart
        : weekStart as LocalDate?,
  );

  bool _hasText(Entry entry) {
    final needle = _needle;
    return needle.isEmpty || SearchFold.of(entry.description).contains(needle);
  }

  /// Pagamento dividido aparece nas duas formas: a compra que saiu metade no
  /// vale e metade no Pix também foi paga no Pix (RN-204).
  bool _paidWith(Entry entry) =>
      paymentMethodId == null ||
      entry.paymentLines.any((line) => line.paymentMethodId == paymentMethodId);

  /// Pela mesma razão, a compra dividida entra em "Só vale alimentação" se
  /// uma das linhas saiu do vale.
  bool _paidByKind(Entry entry) =>
      paymentKind == null ||
      entry.paymentLines.any((line) => line.kind == paymentKind);

  bool _inWeek(LocalDate day) {
    final start = weekStart;
    if (start == null) return true;
    final offset = start.daysUntil(day);
    return offset >= 0 && offset < DateTime.daysPerWeek;
  }

  @override
  bool operator ==(Object other) =>
      other is EntryFilter &&
      other.month == month &&
      other.text == text &&
      other.categoryId == categoryId &&
      other.paymentMethodId == paymentMethodId &&
      other.paymentKind == paymentKind &&
      other.weekStart == weekStart;

  @override
  int get hashCode => Object.hash(
    month,
    text,
    categoryId,
    paymentMethodId,
    paymentKind,
    weekStart,
  );
}
