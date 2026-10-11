import 'package:cajui/src/core/motion/tilt_providers.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/cards/presentation/card_form_page.dart';
import 'package:cajui/src/features/cards/presentation/statement_page.dart';
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

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const CardsPage()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(ledgerProvider).value;
    final finances = ref.watch(financesProvider);
    final cards = book?.cards ?? const <CreditCard>[];
    final month = ref.watch(todayProvider).budgetMonth;
    CardMonthUsage? usageOf(CreditCard card) =>
        finances?.cardUsage(card, month);
    final tilt = _tilt(context, ref);
    return CajuiScreen(
      title: 'Cartões de crédito',
      onBack: Navigator.of(context).pop,
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
        if (cards.isNotEmpty) _wallet(context, cards, usageOf, tilt),
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
    CajuiTilt? tilt,
  ) => CajuiWalletStack(
    children: [
      for (final card in cards)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?_plastic(card, usageOf(card), tilt),
            _row(context, card, usageOf(card)),
          ],
        ),
    ],
  );

  static Widget _register(BuildContext context) => CajuiButton(
    label: 'Cadastrar cartão',
    icon: CajuiIconData.plus,
    expand: true,
    onPressed: () => CardFormPage.open(context),
  );

  /// Só à vista o sensor é lido: tela coberta por outra não balança.
  static CajuiTilt? _tilt(BuildContext context, WidgetRef ref) =>
      TickerMode.valuesOf(context).enabled
      ? ref.watch(deviceTiltProvider)
      : null;

  static const _noCardsYet = CajuiEmptyState(
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
  /// não há o que mostrar no verso.
  static Widget? _plastic(
    CreditCard card,
    CardMonthUsage? usage,
    CajuiTilt? tilt,
  ) {
    if (usage == null || !usage.limit.isPositive) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.sm),
      child: CajuiCreditCard3D(
        name: card.name,
        detail: 'fecha dia ${card.closingDay} · vence dia ${card.dueDay}',
        usedCents: usage.used.cents,
        limitCents: usage.limit.cents,
        tilt: tilt,
      ),
    );
  }

  /// O uso do mês em texto; sem limite informado, os dias do cartão.
  static String _usageText(CreditCard card, CardMonthUsage? usage) {
    final days = 'fecha dia ${card.closingDay} · vence dia ${card.dueDay}';
    if (usage == null) return days;
    final left = usage.left;
    final sobra = left.isNegative
        ? 'passou ${BrlFormatter.format(-left.cents)}'
        : 'sobra ${BrlFormatter.format(left.cents)}';
    return 'Usei ${BrlFormatter.format(usage.used.cents)} este mês · $sobra'
        ' · $days';
  }

  Widget _row(BuildContext context, CreditCard card, CardMonthUsage? usage) =>
      CajuiListRow(
        leading: const CajuiIcon(CajuiIconData.card),
        title: card.name,
        subtitle: _usageText(card, usage),
        trailing: const CajuiIcon(CajuiIconData.chevronRight),
        semanticLabel: '${card.name}, ver a fatura',
        onPressed: () => StatementPage.open(context, card),
      );
}
