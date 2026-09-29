import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// O cartão do cenário, com limite de R$ 5.000,00.
final CreditCard _limited = CreditCard.create(
  id: 'card',
  name: 'Cartão roxo',
  closingDay: 25,
  dueDay: 5,
  creditLimit: const Money.fromCents(500000),
).valueOrNull!;

/// O fogão: R$ 960,00 em 6× de R$ 160,00, comprado em 10/07. A 1ª parcela
/// vem na fatura de agosto; a 6ª, na de janeiro.
Entry _stove() => parceled(
  id: 'fogao',
  cents: 96000,
  count: 6,
  on: LocalDate(2026, 7, 10),
  onCard: _limited,
);

/// Mercado de R$ 800,00 à vista no cartão em 12/09: fatura de outubro.
Entry _market() => entry(id: 'mercado', cents: 80000, lines: [credit(80000)]);

Settlement _paid(int year, int month, int cents) => Settlement(
  id: 'pago-$year-$month',
  cardId: 'card',
  dueMonth: BudgetMonth(year, month),
  amount: Money.fromCents(cents),
  paidOn: LocalDate(year, month, 5),
);

CardLimitUsage _usage({
  List<Entry>? entries,
  List<Settlement> settlements = const [],
  List<Reversal> reversals = const [],
  List<Debt> legacy = const [],
  CreditCard? card,
}) => CardLimitUsage.of(
  card ?? _limited,
  entries: entries ?? [_stove(), _market()],
  today: today,
  settlements: settlements,
  reversals: reversals,
  legacy: legacy,
)!;

void main() {
  group('CardLimitUsage', () {
    test('RN-305 tomado = faturas em aberto + parcelas por vencer', () {
      // A fatura de agosto, com a 1ª parcela do fogão, já foi paga. Ficam
      // cinco parcelas de R$ 160,00 e o mercado de R$ 800,00.
      final usage = _usage(settlements: [_paid(2026, 8, 16000)]);

      expect(usage.taken, const Money.fromCents(160000));
      expect(usage.available, const Money.fromCents(340000));
      expect(usage.exceeded, Money.zero);
      expect(usage.fraction, closeTo(0.32, 0.0001));
    });

    test('RN-305 compra parcelada toma o limite pelo valor inteiro, e o '
        'devolve parcela a parcela', () {
      final noDia = _usage(entries: [_stove()]);
      final duasPagas = _usage(
        entries: [_stove()],
        settlements: [_paid(2026, 8, 16000), _paid(2026, 9, 16000)],
      );

      expect(noDia.taken, const Money.fromCents(96000));
      expect(duasPagas.taken, const Money.fromCents(64000));
    });

    test('RN-305 fatura paga em parte segura o limite pelo que ficou', () {
      final usage = _usage(
        entries: [_market()],
        settlements: [_paid(2026, 10, 50000)],
      );

      expect(usage.taken, const Money.fromCents(30000));
    });

    test('RN-344 pagar uma fatura a mais não devolve limite às outras', () {
      final usage = _usage(settlements: [_paid(2026, 8, 99900)]);

      expect(usage.taken, const Money.fromCents(160000));
    });

    test('RN-211 o estorno devolve o limite', () {
      final market = _market();
      final back = Reversal.create(
        id: 'r',
        entry: market,
        paymentMethodId: 'card',
        amount: const Money.fromCents(30000),
        occurredOn: LocalDate(2026, 9, 20),
      ).valueOrNull!;

      final usage = _usage(entries: [market], reversals: [back]);

      expect(usage.taken, const Money.fromCents(50000));
    });

    test('RN-521 parcela de compra anterior ao app também toma limite', () {
      final sofa = Debt.create(
        id: 'sofa',
        creditor: 'Loja de móveis',
        kind: DebtKind.cardInstallment,
        installmentAmount: const Money.fromCents(15000),
        totalInstallments: 10,
        paidInstallments: 6,
        dueDay: 5,
        firstMonth: const BudgetMonth(2026, 3),
        cardId: 'card',
      ).valueOrNull!;
      final deOutroCartao = Debt.create(
        id: 'tv',
        creditor: 'Loja',
        kind: DebtKind.cardInstallment,
        installmentAmount: const Money.fromCents(10000),
        totalInstallments: 10,
        paidInstallments: 0,
        dueDay: 5,
        firstMonth: const BudgetMonth(2026, 3),
        cardId: 'outro',
      ).valueOrNull!;

      final usage = _usage(entries: [], legacy: [sofa, deOutroCartao]);

      expect(usage.taken, const Money.fromCents(60000));
    });

    test('RN-305 passou do limite: o livre para em zero e a diferença '
        'aparece', () {
      final apertado = CreditCard.create(
        id: 'card',
        name: 'Cartão roxo',
        closingDay: 25,
        dueDay: 5,
        creditLimit: const Money.fromCents(100000),
      ).valueOrNull!;

      final usage = _usage(card: apertado);

      expect(usage.taken, const Money.fromCents(176000));
      expect(usage.available, Money.zero);
      expect(usage.exceeded, const Money.fromCents(76000));
      expect(usage.fraction, greaterThan(1));
    });

    test('RN-302 cartão sem limite informado não tem o que mostrar', () {
      final usage = CardLimitUsage.of(card, entries: [_market()], today: today);

      expect(usage, isNull);
    });

    test('RN-301 o que foi pago por outra forma não toma limite nenhum', () {
      final usage = _usage(
        entries: [
          entry(id: 'pix', cents: 5000, lines: [pix(5000)]),
        ],
      );

      expect(usage.taken, Money.zero);
      expect(usage.available, const Money.fromCents(500000));
    });
  });
}
