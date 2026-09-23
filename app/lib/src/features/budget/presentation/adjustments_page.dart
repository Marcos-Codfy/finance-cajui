import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Como fechar o mês mexendo só nos variáveis (RN-662 e RN-663).
///
/// O domínio já sabia dizer isto desde a Fase 6 — `adjustmentOptions` e
/// `adjustableSlack` estavam prontos e testados —, e **nenhuma tela
/// perguntava**. O painel dizia que faltava dinheiro e parava aí.
///
/// Nada é aplicado sozinho (RN-663): cada corte é um toque, e muda o plano
/// do mês como fato registrado, igual a qualquer outra alteração de plano.
class AdjustmentsPage extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const AdjustmentsPage()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(monthOverviewProvider);
    if (overview == null) {
      return const CajuiScreen(title: 'Ajustes', children: []);
    }
    return CajuiScreen(
      title: 'Ajustes possíveis',
      onBack: Navigator.of(context).pop,
      children: [
        _summary(overview),
        const SizedBox(height: CajuiSpacing.xl),
        ..._options(ref, overview),
      ],
    );
  }

  /// A frase da RN-662: ou os variáveis cobrem, ou o app diz com todas as
  /// letras quanto eles cobrem e que o resto depende de outra coisa.
  Widget _summary(MonthOverview overview) {
    final indicators = overview.indicators;
    final needed = MoneyFormat.brl(indicators.requiredAdjustment);
    final slack = MoneyFormat.brl(indicators.adjustableSlack);
    if (indicators.requiredAdjustment.isZero) {
      return const CajuiNotice(
        intent: CajuiNoticeIntent.positive,
        what: 'O mês já fecha como está.',
        meaning: 'Não há nada a ajustar por enquanto.',
      );
    }
    return CajuiNotice(
      intent: indicators.closesByAdjustingVariables
          ? CajuiNoticeIntent.info
          : CajuiNoticeIntent.attention,
      what: indicators.closesByAdjustingVariables
          ? 'Dá para cobrir sem mexer nos fixos.'
          : 'Os variáveis cobrem $slack dos $needed que faltam.',
      meaning: indicators.closesByAdjustingVariables
          ? 'Faltam $needed, e há $slack de folga nos variáveis.'
          : 'O resto depende da renda, de um fixo ou de uma dívida — e '
                'isso não se resolve nesta tela.',
    );
  }

  /// As categorias em que dá para cortar, da maior folga para a menor
  /// (RN-662). Cada uma mostra quanto a sua faixa cairia.
  List<Widget> _options(WidgetRef ref, MonthOverview overview) {
    final indicators = overview.indicators;
    final options = indicators.adjustmentOptions;
    if (options.isEmpty) {
      return const [
        CajuiEmptyState(
          title: 'Nenhuma folga nos variáveis',
          message:
              'Todas as faixas já estão no mínimo, ou o gasto do mês '
              'já passou delas.',
        ),
      ];
    }
    var left = indicators.requiredAdjustment;
    final rows = <Widget>[];
    for (final line in options) {
      final cut = _cutFor(indicators.slackOf(line), left);
      rows.add(_row(ref, line, cut));
      left -= cut;
    }
    return rows;
  }

  /// Quanto cortar nesta categoria: o que falta, até onde a folga dela vai.
  /// Cortar mais do que falta seria o app decidindo economizar por conta
  /// própria, e isso não é dele.
  static Money _cutFor(Money slack, Money left) =>
      left.isPositive && left < slack ? left : slack;

  Widget _row(WidgetRef ref, PlannedVariable line, Money cut) {
    final category = _nameOf(ref, line.budget.categoryId);
    final novo = line.budget.range.max - cut;
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.sm),
      child: CajuiListRow(
        title: category,
        subtitle:
            'De ${MoneyFormat.brl(line.budget.range.max)} para '
            '${MoneyFormat.brl(novo)}',
        trailing: CajuiButton(
          label: 'Usar ${MoneyFormat.brl(cut)}',
          variant: CajuiButtonVariant.secondary,
          size: CajuiButtonSize.compact,
          onPressed: cut.isZero ? null : () => _apply(ref, line, novo),
        ),
        semanticLabel:
            'Baixar a faixa de $category para '
            '${MoneyFormat.brl(novo)}',
      ),
    );
  }

  String _nameOf(WidgetRef ref, String id) =>
      ref.read(ledgerProvider).value?.categoriesById[id]?.name ?? id;

  /// Aceitar é uma ação explícita, e vira fato no registro (RN-663).
  Future<void> _apply(WidgetRef ref, PlannedVariable line, Money max) async {
    final book = ref.read(ledgerProvider).value;
    if (book == null) return;
    final range = AmountRange.create(
      min: line.budget.range.min,
      max: max,
    ).valueOrNull;
    // Faixa que não fecha — cortar abaixo do mínimo — é recusada pelo
    // domínio, e aqui não se insiste: o botão some no próximo quadro.
    if (range == null) return;
    await ref
        .read(ledgerProvider.notifier)
        .definePlan(
          book.setup.withBudget(
            VariableBudget(
              categoryId: line.budget.categoryId,
              range: range,
              voucherEligible: line.budget.voucherEligible,
            ),
          ),
        );
  }
}
