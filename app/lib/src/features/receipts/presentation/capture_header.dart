import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/presentation/read_text_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O que a conferência mostra acima dos campos: de onde veio a proposta, com
/// que certeza, e os candidatos dos campos em que o app ficou em dúvida.
///
/// A confiança nunca é dita só por cor: leva rótulo em texto e ícone
/// (RN-671). E campo em dúvida não vem preenchido — vem com os candidatos,
/// nenhum marcado, para a escolha ser da pessoa.
class CaptureHeader extends StatelessWidget {
  /// Cria o cabeçalho de [capture].
  const new({
    required this.capture,
    required this.book,
    required this.edit,
    super.key,
  });

  /// A captura em conferência.
  final Capture capture;

  /// O livro, de onde saem os nomes das categorias candidatas.
  final LedgerBook book;

  /// Troca o rascunho do formulário.
  final EntryFormEdit edit;

  static const Map<Confidence, CajuiConfidenceLevel> _levels = {
    Confidence.high: CajuiConfidenceLevel.high,
    Confidence.medium: CajuiConfidenceLevel.medium,
    Confidence.low: CajuiConfidenceLevel.low,
  };

  @override
  Widget build(BuildContext context) {
    final proposal = capture.proposal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CajuiNotice(
          intent: CajuiNoticeIntent.info,
          what: 'Li o comprovante aqui no aparelho, só com as regras locais.',
          meaning:
              'Confira a categoria antes de lançar. Nada é gravado sem '
              'o seu toque.',
        ),
        const SizedBox(height: CajuiSpacing.lg),
        CajuiConfidenceIndicator(_levels[proposal.category.confidence]!),
        if (proposal.amount.candidates.length > 1) ...[
          const SizedBox(height: CajuiSpacing.md),
          _amountCandidates(context, proposal.amount.candidates),
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
      onPressed: () => ReadTextPage.open(context, capture.source.text),
    ),
  );

  /// Mais de um número sem rótulo: o app mostra os candidatos, do maior para
  /// o menor, e não escolhe nenhum (RN-753).
  Widget _amountCandidates(BuildContext context, List<Money> candidates) {
    final theme = CajuiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achei mais de um valor. Qual é o da compra?',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Wrap(
          spacing: CajuiSpacing.sm,
          runSpacing: CajuiSpacing.sm,
          children: [
            for (final amount in candidates.take(3))
              CajuiChip(
                label: BrlFormatter.format(amount.cents),
                selected: false,
                onSelected: (_) =>
                    edit((draft) => draft.copyWith(amountCents: amount.cents)),
              ),
          ],
        ),
      ],
    );
  }
}
