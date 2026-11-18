import 'package:cajui/src/core/motion/tilt_providers.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/cards/presentation/cards_coordinator.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os cartões de crédito cadastrados, e a porta para a fatura de cada um.
///
/// No Cajui o cartão é **por onde se paga**, nunca o que se gastou: a compra
/// conta na categoria dela, no dia em que foi feita, e a fatura é só uma
/// visão calculada das compras (RN-301, RN-330).
class CardsPage extends ConsumerWidget {
  /// Cria a tela de cartões.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(ledgerProvider).value;
    final finances = ref.watch(financesProvider);
    final cards = book?.cards ?? const <CreditCard>[];
    final month = ref.watch(todayProvider).budgetMonth;
    CardMonthUsage? usageOf(CreditCard card) =>
        finances?.cardUsage(card, month);
    ({Money planned, Money spent}) amountsOf(CreditCard card) =>
        _amounts(finances, card, month);
    final tilt = _tilt(context, ref);
    return CajuiScreen(
      title: 'Cartões de crédito',
      onBack: context.back,
      footer: ref.watch(ledgerUplinkProvider).isPaired
          ? _register(context)
          : null,
      depth: true,
      cinematic: true,
      children: [
        if (cards.isEmpty) _noCardsYet,
        for (final card in cards)
          if (_alert(card, usageOf(card)) case final alert?) ...[
            alert,
            const SizedBox(height: CajuiSpacing.md),
          ],
        if (cards.isNotEmpty) _wallet(context, cards, usageOf, amountsOf, tilt),
      ],
    );
  }

  /// Os cartões numa carteira 3D (ADR-028): saem do maço ao abrir a tela,
  /// param no alto ao rolar e abrem em leque ao puxar além do topo. Cada um
  /// leva junto a sua linha de uso, para o número não se separar dele.
  Widget _wallet(
    BuildContext context,
    List<CreditCard> cards,
    CardMonthUsage? Function(CreditCard card) usageOf,
    ({Money planned, Money spent}) Function(CreditCard card) amountsOf,
    CajuiTilt? tilt,
  ) => CajuiWalletStack(
    // A chave guarda o leque aberto quando um aviso de limite aparece acima.
    key: const ValueKey('carteira'),
    children: [
      for (final card in cards)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _plastic(context, card, usageOf(card), tilt),
            _row(context, card, usageOf(card), amountsOf(card)),
          ],
        ),
    ],
  );

  /// O que as contas do mês cobram no cartão e o que passou por ele no mês.
  static ({Money planned, Money spent}) _amounts(
    Finances? finances,
    CreditCard card,
    BudgetMonth month,
  ) => (
    planned: finances?.plannedOnCard(card, month) ?? Money.zero,
    spent: finances?.spentOnCard(card, month) ?? Money.zero,
  );

  static Widget _register(BuildContext context) => CajuiButton(
    label: 'Cadastrar cartão',
    icon: CajuiIconData.plus,
    expand: true,
    onPressed: () =>
        context.coordinator(cardsCoordinatorProvider).openCardForm(),
  );

  /// Só à vista o sensor é lido: tela coberta por outra não balança.
  static CajuiTilt? _tilt(BuildContext context, WidgetRef ref) =>
      TickerMode.valuesOf(context).enabled
      ? ref.watch(deviceTiltProvider)
      : null;

  /// A folha: um cartão é o que ainda vai crescer na lista.
  static const _noCardsYet = CajuiEmptyState(
    illustration: CajuiCerradoArt(CajuiCerrado.leaf),
    title: 'Nenhum cartão ainda',
    message:
        'Cadastre o cartão para pagar compras com ele. O Cajui só precisa '
        'do nome e dos dias de fechamento e de vencimento — nunca do número.',
  );

  /// O aviso do cartão que passou da metade ou de 80% do limite no mês
  /// (RN-1020). Descreve, não alarma.
  static Widget? _alert(CreditCard card, CardMonthUsage? usage) {
    if (usage == null) return null;
    final percent = usage.percent ?? 0;
    return switch (usage.alert) {
      CardUsageAlert.none => null,
      CardUsageAlert.half => CajuiNotice(
        intent: CajuiNoticeIntent.info,
        what: '${card.name}: $percent% do limite usado este mês.',
      ),
      CardUsageAlert.high => CajuiNotice(
        intent: CajuiNoticeIntent.info,
        what: '${card.name} passou de 80% do limite este mês.',
        meaning:
            'Usado ${BrlFormatter.format(usage.used.cents)} de '
            '${BrlFormatter.format(usage.limit.cents)}.',
      ),
    };
  }

  /// O cartão em 3D, que inclina com o celular e vira com um toque para
  /// mostrar o limite (escolha 2 do dono). Só com limite informado: sem ele
  /// não há o que mostrar no verso — e, no lugar, o convite para informar,
  /// senão ninguém descobre que o cartão existe (16/10/2026).
  static Widget _plastic(
    BuildContext context,
    CreditCard card,
    CardMonthUsage? usage,
    CajuiTilt? tilt,
  ) {
    if (usage == null || !usage.limit.isPositive) {
      return CajuiButton(
        label: 'Informe o limite do cartão',
        icon: CajuiIconData.card,
        variant: CajuiButtonVariant.ghost,
        onPressed: () => context
            .coordinator(cardsCoordinatorProvider)
            .openCardForm(card: card),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.sm),
      child: CajuiCreditCard3D(
        name: card.name,
        detail: 'fecha dia ${card.closingDay} · vence dia ${card.dueDay}',
        usedCents: usage.used.cents,
        limitCents: usage.limit.cents,
        tilt: tilt,
        skin: CajuiCardSkin.of(card.skin),
      ),
    );
  }

  /// O uso do mês em texto; sem limite informado, os dias do cartão.
  static String _usageText(
    CreditCard card,
    CardMonthUsage? usage,
    ({Money planned, Money spent}) month,
  ) {
    final days = 'fecha dia ${card.closingDay} · vence dia ${card.dueDay}';
    // As contas de "Minhas contas" pagas neste cartão: sem esta linha, a
    // assinatura cadastrada no cartão não aparecia em lugar nenhum.
    final bills = month.planned.isPositive
        ? 'contas do mês ${BrlFormatter.format(month.planned.cents)} · '
        : '';
    final used = 'Usei ${BrlFormatter.format(month.spent.cents)} este mês · ';
    if (usage == null) {
      // Sem limite não há sobra, mas a compra no cartão aparece aqui, e não
      // só dentro da fatura.
      return '${month.spent.isPositive ? used : ''}$bills$days';
    }
    // A sobra desconta as contas do mês no cartão: elas vão cair nele.
    final left = usage.left - month.planned;
    final sobra = left.isNegative
        ? 'passou ${BrlFormatter.format(-left.cents)}'
        : 'sobra ${BrlFormatter.format(left.cents)}';
    return '$used$bills$sobra · $days';
  }

  Widget _row(
    BuildContext context,
    CreditCard card,
    CardMonthUsage? usage,
    ({Money planned, Money spent}) month,
  ) => CajuiListRow(
    leading: const CajuiIcon(CajuiIconData.card),
    title: card.name,
    subtitle: _usageText(card, usage, month),
    trailing: const CajuiIcon(CajuiIconData.chevronRight),
    semanticLabel: '${card.name}, ver a fatura',
    onPressed: () =>
        context.coordinator(cardsCoordinatorProvider).openStatement(card),
  );
}
