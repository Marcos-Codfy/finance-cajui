import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os avisos da conferência sobre o comprovante **já estar no livro** ou
/// **não ser gasto**: a notificação do banco já lançou este Pix (RN-1076),
/// o Pix foi para alguém da casa (RN-1074), ou parece repetido (RN-221).
///
/// Todos são aviso, nunca bloqueio: "Lançar" continua no pé da tela, e
/// quem decide é quem está olhando. O que cada aviso oferece é o caminho
/// curto para a resposta mais provável.
class CaptureWarnings extends ConsumerStatefulWidget {
  /// Cria os avisos de [capture], comparada com [book].
  const new({
    required this.capture,
    required this.book,
    required this.today,
    super.key,
  });

  /// A captura em conferência.
  final Capture capture;

  /// O livro, com os lançamentos e os nomes da casa.
  final LedgerBook book;

  /// O dia de hoje, para dizer "hoje" e "ontem" em vez da data.
  final LocalDate today;

  @override
  ConsumerState<CaptureWarnings> createState() => _CaptureWarningsState();
}

class _CaptureWarningsState extends ConsumerState<CaptureWarnings> {
  /// A pessoa disse que é outro: nenhum aviso de repetido volta.
  bool _another = false;

  EntryProposal get _proposal => widget.capture.proposal;

  @override
  Widget build(BuildContext context) {
    final twin = _another ? null : _twin;
    final notices = [
      if (twin != null) _twinNotice(twin),
      ?_householdNotice(),
      if (twin == null && !_another) ?_duplicateNotice(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final notice in notices) ...[
          notice,
          const SizedBox(height: CajuiSpacing.lg),
        ],
      ],
    );
  }

  /// O lançamento que a notificação do banco já fez deste comprovante.
  Entry? get _twin {
    final amount = _proposal.amount.value;
    final on = _proposal.occurredOn.value;
    if (amount == null || on == null) return null;
    return NoticeTwin.ofReceipt(
      widget.book.entries,
      amount: amount,
      occurredOn: on,
      name: _proposal.merchant,
    );
  }

  /// "A notificação do banco já lançou R$ 150,00: Joana P Lima, ontem, em
  /// Outros." (RN-1076). "É o mesmo" descarta sem gravar nada (RN-723).
  Widget _twinNotice(Entry existing) {
    final category = widget.book.categoriesById[existing.categoryId]?.name;
    return CajuiNotice(
      what:
          'A notificação do banco já lançou '
          '${MoneyFormat.brl(existing.amount)}: ${existing.description}, '
          '${_when(existing.occurredOn)}'
          '${category == null ? '' : ', em $category'}.',
      meaning: 'Se for o mesmo, lançar de novo conta o dinheiro duas vezes.',
      primaryAction: CajuiNoticeAction(
        label: 'É o mesmo — não lançar',
        onPressed: _discard,
      ),
      secondaryAction: CajuiNoticeAction(
        label: 'É outro — lançar',
        onPressed: _launchAnother,
      ),
    );
  }

  /// "R$ 500,00 para Marcos Arruda parece transferência entre contas da
  /// casa." (RN-1074). Não lançar descarta; lançar continua possível.
  Widget? _householdNotice() {
    final merchant = _proposal.merchant;
    if (widget.book.householdNames.whoIs(merchant) == null) return null;
    final amount = _proposal.amount.value;
    final to = MerchantName.pretty(merchant) ?? merchant;
    return CajuiNotice(
      what:
          '${amount == null ? 'O comprovante' : MoneyFormat.brl(amount)} '
          'para $to parece transferência entre contas da casa.',
      meaning: 'Dinheiro mudando de conta dentro da casa não é gasto.',
      intent: CajuiNoticeIntent.info,
      primaryAction: CajuiNoticeAction(
        label: 'Não lançar',
        onPressed: _discard,
      ),
    );
  }

  /// O lançamento que **parece** ser este comprovante: mesmo valor, mesma
  /// data e mesmo lugar (RN-221). Dois cafés de R$ 8,50 no mesmo dia são
  /// legítimos: o aviso pergunta.
  Widget? _duplicateNotice() {
    final merchant = _proposal.merchant;
    final amount = _proposal.amount.value;
    final on = _proposal.occurredOn.value;
    // Comprovante em que a leitura não resolveu valor, data ou lugar não dá
    // para comparar com nada: aí não há aviso.
    if (merchant == null || amount == null || on == null) return null;
    final existing = PossibleDuplicate.among(
      widget.book.entries,
      amount: amount,
      occurredOn: on,
      description: merchant,
    );
    if (existing == null) return null;
    return CajuiNotice(
      what:
          'Já existe um lançamento de ${MoneyFormat.brl(existing.amount)} '
          'em ${existing.description}, ${_when(existing.occurredOn)}.',
      meaning: 'É outro?',
    );
  }

  /// "hoje", "ontem", ou o dia por extenso.
  String _when(LocalDate day) => switch (day.daysUntil(widget.today)) {
    0 => 'hoje',
    1 => 'ontem',
    _ => 'no dia ${day.day} de ${CalendarWords.month(day.budgetMonth)}',
  };

  Future<void> _discard() =>
      ref.read(captureProvider.notifier).discard(widget.capture);

  /// "É outro": o aviso sai e o lançamento segue pelo mesmo caminho do
  /// botão "Lançar" — mesmas regras, mesmos erros. Faltando algum campo,
  /// só o aviso sai, e o formulário mostra o que falta.
  Future<void> _launchAnother() async {
    setState(() => _another = true);
    final form = ref.read(entryFormProvider);
    if (form.draft.isComplete) {
      await ref.read(entryFormProvider.notifier).submit();
    }
  }
}
