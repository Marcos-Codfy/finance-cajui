import 'package:cajui/src/core/format/date_labels.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Um gasto na revisão da semana: o que foi, quanto, quando — e as
/// categorias, a um toque cada (RN-871).
///
/// A categoria que ele já tem vem marcada: tocar nela confirma, e o gasto
/// sai da lista. Não há tela de edição no meio: a revisão é para caber em
/// um minuto.
class ReviewEntryCard extends StatelessWidget {
  /// Cria o cartão de [entry], que está em [categoryName].
  const new({
    required this.entry,
    required this.categoryName,
    required this.categories,
    required this.today,
    required this.onChoose,
    super.key,
  });

  /// O gasto.
  final Entry entry;

  /// O nome da categoria em que ele está.
  final String categoryName;

  /// As categorias oferecidas.
  final List<Category> categories;

  /// O dia de hoje, para dizer "hoje" e "ontem".
  final LocalDate today;

  /// Chamado com a categoria tocada.
  final ValueChanged<Category> onChoose;

  String get _subtitle {
    final day = DateLabels.day(entry.occurredOn, today: today);
    final automatic = entry.origin == EntryOrigin.notification
        ? ' · lançado pela notificação do banco'
        : '';
    return '$day · $categoryName$automatic';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.description, style: theme.typography.title),
              ),
              CajuiAmountText(entry.amount.cents),
            ],
          ),
          const SizedBox(height: CajuiSpacing.xs),
          Text(
            _subtitle,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
          const SizedBox(height: CajuiSpacing.md),
          _chips(),
        ],
      ),
    );
  }

  Widget _chips() => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final category in categories)
        CajuiChip(
          label: category.name,
          selected: category.id == entry.categoryId,
          onSelected: (_) => onChoose(category),
        ),
    ],
  );
}
