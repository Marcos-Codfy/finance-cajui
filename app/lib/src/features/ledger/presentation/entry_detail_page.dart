import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/core/presentation/loading_page.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:cajui/src/features/ledger/presentation/entry_detail_sections.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:cajui/src/features/ledger/presentation/reversal_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um lançamento por inteiro, e o que dá para fazer com ele: corrigir,
/// registrar que o dinheiro voltou, cancelar (RN-208 a RN-211).
///
/// Nenhuma das três ações reescreve o que foi gravado. Cada uma acrescenta
/// um fato ao registro, e esta tela mostra sempre o estado mais recente.
/// Cancelar é aqui mesmo, em dois toques no mesmo botão — sem tela própria
/// e sem explicação: o lançamento sai das contas e o registro guarda que
/// ele existiu (RN-995).
class EntryDetailPage extends ConsumerStatefulWidget {
  /// Cria a tela do lançamento [entryId].
  const new({required this.entryId, super.key});

  /// O lançamento à vista.
  final String entryId;

  /// Abre a tela.
  static Future<void> open(BuildContext context, String entryId) {
    return Navigator.of(context).push<void>(
      CajuiPageRoute(builder: (_) => EntryDetailPage(entryId: entryId)),
    );
  }

  /// Abre a correção de [entry] — daqui e do deslizar da lista. Reaproveita
  /// o formulário de lançar inteiro — mesmos campos, mesmas regras, mesmos
  /// erros — aberto com o que já está gravado.
  static Future<void> correct(
    BuildContext context,
    LedgerBook book,
    Entry entry,
  ) {
    final draft = EntryDraft.correcting(
      entry,
      category: book.categoryOf(entry.categoryId),
      methodOf: book.methodOf,
    );
    return Navigator.of(context).push<void>(
      CajuiPageRoute(
        builder: (_) => ProviderScope(
          overrides: [initialDraftProvider.overrideWithValue(draft)],
          child: const EntryFormPage(
            title: 'Corrigir despesa',
            submitLabel: 'Guardar correção',
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends ConsumerState<EntryDetailPage> {
  /// O primeiro toque em "Cancelar lançamento" só arma o botão: o segundo
  /// cancela. É a confirmação sem tela.
  bool _confirmingCancel = false;

  static const _gap = SizedBox(height: CajuiSpacing.sm);

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(ledgerProvider).value;
    final entry = book?.entryOf(widget.entryId);
    if (book == null) return const LoadingPage(title: 'Despesa');
    // Cancelado: não há mais o que mostrar, e a tela já está fechando.
    if (entry == null) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    final category = book.categoryOf(entry.categoryId).name;
    final day = DateLabels.day(entry.occurredOn, today: today);
    return CajuiScreen(
      title: 'Despesa',
      onBack: Navigator.of(context).pop,
      children: [
        CajuiStatCard(
          label: entry.description,
          cents: entry.amount.cents,
          large: true,
          caption: '$category · $day',
        ),
        ...EntryDetailSections.payment(book, entry),
        ...EntryDetailSections.reversals(book, entry, today),
        const SizedBox(height: CajuiSpacing.section),
        ..._actions(context, book, entry),
      ],
    );
  }

  /// Compra parcelada ainda não tem estorno: como a devolução encerra as
  /// parcelas que faltam não está decidido, e o app não inventa a regra.
  static bool _canReverse(LedgerBook book, Entry entry) =>
      entry.installmentPlan == null &&
      entry.paymentLines.any(
        (line) => book.reversibleOn(entry, line.paymentMethodId).isPositive,
      );

  List<Widget> _actions(BuildContext context, LedgerBook book, Entry entry) => [
    CajuiButton(
      label: 'Corrigir',
      expand: true,
      onPressed: () => EntryDetailPage.correct(context, book, entry),
    ),
    if (_canReverse(book, entry)) ...[
      _gap,
      CajuiButton(
        label: 'Registrar estorno',
        variant: CajuiButtonVariant.secondary,
        expand: true,
        onPressed: () => ReversalPage.open(context, entry),
      ),
    ],
    _gap,
    ..._cancelButtons(entry),
  ];

  /// Armado, o botão muda de cara e ganha um "Manter" ao lado: desistir é
  /// tão fácil quanto confirmar.
  List<Widget> _cancelButtons(Entry entry) => [
    CajuiButton(
      label: _confirmingCancel
          ? 'Confirmar o cancelamento'
          : 'Cancelar lançamento',
      variant: _confirmingCancel
          ? CajuiButtonVariant.destructive
          : CajuiButtonVariant.ghost,
      expand: true,
      onPressed: _confirmingCancel
          ? () => _cancel(entry)
          : () => setState(() => _confirmingCancel = true),
    ),
    if (_confirmingCancel) ...[
      _gap,
      CajuiButton(
        label: 'Manter',
        variant: CajuiButtonVariant.ghost,
        expand: true,
        onPressed: () => setState(() => _confirmingCancel = false),
      ),
    ],
  ];

  Future<void> _cancel(Entry entry) async {
    final navigator = Navigator.of(context);
    final feedback = CajuiFeedbackScope.of(context);
    await ref
        .read(ledgerProvider.notifier)
        .cancel(entry.id, reason: 'Cancelado pela pessoa');
    feedback.saved();
    navigator.pop();
  }
}
