import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/presentation/cancel_entry_page.dart';
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
class EntryDetailPage extends ConsumerWidget {
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

  static const _gap = SizedBox(height: CajuiSpacing.sm);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(ledgerProvider).value;
    final entry = book?.entryOf(entryId);
    // Cancelado: não há mais o que mostrar, e a tela já está fechando.
    if (book == null || entry == null) return const SizedBox.shrink();
    final today = ref.watch(clockProvider).today();
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
      onPressed: () => _correct(context, book, entry),
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
    CajuiButton(
      label: 'Cancelar lançamento',
      variant: CajuiButtonVariant.ghost,
      expand: true,
      onPressed: () => _cancel(context, entry),
    ),
  ];

  /// A correção reaproveita o formulário de lançar inteiro — mesmos campos,
  /// mesmas regras, mesmos erros — aberto com o que já está gravado.
  static Future<void> _correct(
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

  static Future<void> _cancel(BuildContext context, Entry entry) async {
    final navigator = Navigator.of(context);
    final cancelled = await CancelEntryPage.open(context, entry);
    if (cancelled ?? false) navigator.pop();
  }
}
