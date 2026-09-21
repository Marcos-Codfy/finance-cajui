import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O que a pessoa já preencheu de um lançamento, antes de qualquer regra.
///
/// Pode estar incompleto e pode estar errado — é rascunho. Quem decide se
/// vira lançamento é o domínio, na hora de gravar.
@immutable
final class EntryDraft {
  /// Cria o rascunho de uma compra feita em [occurredOn].
  const new({
    required this.occurredOn,
    this.amountCents = 0,
    this.description = '',
    this.category,
    this.method,
    this.secondMethod,
    this.firstCents = 0,
    this.secondCents = 0,
    this.isSplit = false,
    this.installments = 1,
    this.captureId,
  });

  /// O valor da compra, em centavos.
  final int amountCents;

  /// O que foi comprado, ou onde.
  final String description;

  /// A categoria escolhida.
  final Category? category;

  /// A data da compra.
  final LocalDate occurredOn;

  /// A forma de pagamento — a primeira, quando o pagamento é dividido.
  final PaymentMethod? method;

  /// Se o pagamento está dividido em duas formas (RN-204).
  final bool isSplit;

  /// A segunda forma de pagamento, quando dividido.
  final PaymentMethod? secondMethod;

  /// Quanto a primeira forma paga, quando dividido.
  final int firstCents;

  /// Quanto a segunda forma paga, quando dividido.
  ///
  /// É um campo, e não "o resto": a pessoa digita os dois valores como estão
  /// no comprovante, e se a soma não fechar é o domínio que recusa (RN-203),
  /// dizendo quanto falta.
  final int secondCents;

  /// Em quantas vezes a compra foi feita no cartão de crédito. Uma vez é à
  /// vista. Só vale com uma forma de pagamento só, e ela sendo cartão de
  /// crédito: [installmentCount] é o que de fato vai para o domínio.
  final int installments;

  /// As parcelas que contam: mais de uma, só em compra paga inteira num
  /// cartão de crédito. Em qualquer outro caso a compra é à vista.
  int get installmentCount {
    final onCard = method?.kind.isCreditCard ?? false;
    return onCard && !isSplit && installments > 1 ? installments : 1;
  }

  /// O identificador da captura de onde o rascunho nasceu; `null` quando foi
  /// digitado à mão. É a chave de idempotência do lançamento (RN-781): o
  /// mesmo comprovante confirmado duas vezes grava um fato só.
  final String? captureId;

  /// De onde o lançamento vem.
  EntryOrigin get origin =>
      captureId == null ? EntryOrigin.manual : EntryOrigin.share;

  /// Quanto falta para as duas linhas fecharem o valor. Negativo se passaram.
  int get unassignedCents => amountCents - firstCents - secondCents;

  /// Se já há o bastante para tentar gravar.
  bool get isComplete =>
      description.trim().isNotEmpty &&
      category != null &&
      method != null &&
      (!isSplit || secondMethod != null);

  /// As linhas de pagamento que o rascunho descreve.
  List<PaymentLine> get lines {
    final first = method;
    final second = secondMethod;
    if (first == null) return const [];
    if (!isSplit || second == null) {
      return [first.line(Money.fromCents(amountCents))];
    }
    return [
      first.line(Money.fromCents(firstCents)),
      second.line(Money.fromCents(secondCents)),
    ];
  }

  /// O mesmo rascunho com os campos dados trocados.
  ///
  /// Para **limpar** categoria ou forma de pagamento, use [without]: aqui,
  /// `null` quer dizer "não mexa".
  EntryDraft copyWith({
    int? amountCents,
    String? description,
    Category? category,
    LocalDate? occurredOn,
    PaymentMethod? method,
    PaymentMethod? secondMethod,
    int? firstCents,
    int? secondCents,
    bool? isSplit,
    int? installments,
  }) {
    return EntryDraft(
      installments: installments ?? this.installments,
      amountCents: amountCents ?? this.amountCents,
      description: description ?? this.description,
      category: category ?? this.category,
      occurredOn: occurredOn ?? this.occurredOn,
      method: method ?? this.method,
      secondMethod: secondMethod ?? this.secondMethod,
      firstCents: firstCents ?? this.firstCents,
      secondCents: secondCents ?? this.secondCents,
      isSplit: isSplit ?? this.isSplit,
      captureId: captureId,
    );
  }

  /// O mesmo rascunho com a segunda forma de pagamento no lugar da primeira.
  EntryDraft get swapped => EntryDraft(
    amountCents: amountCents,
    description: description,
    category: category,
    occurredOn: occurredOn,
    method: secondMethod,
    secondMethod: method,
    firstCents: secondCents,
    secondCents: firstCents,
    isSplit: isSplit,
    installments: installments,
    captureId: captureId,
  );

  /// O mesmo rascunho sem a categoria e/ou sem a forma de pagamento. Tirar a
  /// forma de pagamento desfaz também a divisão.
  EntryDraft without({bool category = false, bool method = false}) {
    return EntryDraft(
      amountCents: amountCents,
      description: description,
      occurredOn: occurredOn,
      category: category ? null : this.category,
      method: method ? null : this.method,
      secondMethod: method ? null : secondMethod,
      firstCents: method ? 0 : firstCents,
      secondCents: method ? 0 : secondCents,
      isSplit: !method && isSplit,
      installments: method ? 1 : installments,
      captureId: captureId,
    );
  }
}
