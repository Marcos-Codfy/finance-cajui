import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart'
    show EntryFormEdit;
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/presentation/capture_warnings.dart';
import 'package:cajui/src/features/receipts/presentation/receipts_coordinator.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O que a conferência mostra acima dos campos: os avisos de repetido e de
/// transferência dentro da casa ([CaptureWarnings]), com que certeza a
/// leitura veio, e as alternativas dos campos em que o app ficou em
/// dúvida — a um toque de trocar.
///
/// A confiança nunca é dita só por cor: leva rótulo em texto e ícone
/// (RN-671). O campo já vem com o candidato mais provável; o que aparece
/// aqui são os **outros**, para quem quiser trocar sem abrir a lista.
class CaptureHeader extends StatelessWidget {
  /// Cria o cabeçalho de [capture]; [selectedCategoryId] é a categoria que
  /// está no campo agora.
  const new({
    required this.capture,
    required this.book,
    required this.edit,
    required this.today,
    this.selectedCategoryId,
    super.key,
  });

  /// A captura em conferência.
  final Capture capture;

  /// O livro, de onde saem os nomes das categorias candidatas.
  final LedgerBook book;

  /// Troca o rascunho do formulário.
  final EntryFormEdit edit;

  /// O dia de hoje, para os avisos dizerem "hoje" e "ontem" em vez da data.
  final LocalDate today;

  /// A categoria que está no campo, para não a oferecer de novo.
  final String? selectedCategoryId;

  static const Map<Confidence, CajuiConfidenceLevel> _levels = {
    Confidence.high: CajuiConfidenceLevel.high,
    Confidence.medium: CajuiConfidenceLevel.medium,
    Confidence.low: CajuiConfidenceLevel.low,
  };

  @override
  Widget build(BuildContext context) {
    final proposal = capture.proposal;
    final others = [
      for (final id in proposal.category.candidates.take(4))
        if (id != selectedCategoryId) ?_categoryOf(id),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CaptureWarnings(capture: capture, book: book, today: today),
        CajuiConfidenceIndicator(_levels[proposal.category.confidence]!),
        if (proposal.amount.candidates.length > 1) ...[
          const SizedBox(height: CajuiSpacing.md),
          _amountCandidates(context, proposal.amount.candidates),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: CajuiSpacing.md),
          _categoryAlternatives(context, others),
        ],
        const SizedBox(height: CajuiSpacing.sm),
        _seeWhatWasRead(context),
      ],
    );
  }

  /// A porta para a transparência do fluxo (RN-735).
  Widget _seeWhatWasRead(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: CajuiButton(
      label: 'Ver o que foi lido',
      variant: CajuiButtonVariant.ghost,
      size: CajuiButtonSize.compact,
      onPressed: () => context
          .coordinator(receiptsCoordinatorProvider)
          .openReadText(capture.source.text, proposal: capture.proposal),
    ),
  );

  /// As outras categorias que o lugar sugere, para trocar em um toque.
  Widget _categoryAlternatives(BuildContext context, List<Category> others) =>
      _suggestion(context, 'Pode ser também:', [
        for (final category in others)
          CajuiChip(
            label: category.name,
            selected: false,
            onSelected: (_) =>
                edit((draft) => draft.copyWith(category: category)),
          ),
      ]);

  Category? _categoryOf(String id) =>
      book.categories.where((category) => category.id == id).firstOrNull;

  /// Uma pergunta com as respostas em chips.
  Widget _suggestion(
    BuildContext context,
    String question,
    List<Widget> chips,
  ) {
    final theme = CajuiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Wrap(
          spacing: CajuiSpacing.sm,
          runSpacing: CajuiSpacing.sm,
          children: chips,
        ),
      ],
    );
  }

  /// Mais de um número sem rótulo: o app mostra os candidatos, do maior para
  /// o menor, e quem escolhe é a pessoa (RN-753).
  Widget _amountCandidates(BuildContext context, List<Money> candidates) {
    return _suggestion(context, 'Achei mais de um valor. Qual é o da compra?', [
      for (final amount in candidates.take(3))
        CajuiChip(
          label: BrlFormatter.format(amount.cents),
          selected: false,
          onSelected: (_) =>
              edit((draft) => draft.copyWith(amountCents: amount.cents)),
        ),
    ]);
  }
}
