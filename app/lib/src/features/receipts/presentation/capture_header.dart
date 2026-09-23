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
    required this.today,
    super.key,
  });

  /// A captura em conferência.
  final Capture capture;

  /// O livro, de onde saem os nomes das categorias candidatas.
  final LedgerBook book;

  /// Troca o rascunho do formulário.
  final EntryFormEdit edit;

  /// O dia de hoje, para o aviso de repetido dizer "hoje" em vez da data.
  final LocalDate today;

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
        _readHere,
        if (_alreadyThere case final existing?) ...[
          const SizedBox(height: CajuiSpacing.lg),
          _duplicateNotice(existing),
        ],
        const SizedBox(height: CajuiSpacing.lg),
        CajuiConfidenceIndicator(_levels[proposal.category.confidence]!),
        if (proposal.amount.candidates.length > 1) ...[
          const SizedBox(height: CajuiSpacing.md),
          _amountCandidates(context, proposal.amount.candidates),
        ],
        if (proposal.category.candidates.isNotEmpty) ...[
          const SizedBox(height: CajuiSpacing.md),
          _categoryCandidates(context, proposal.category.candidates),
        ],
        const SizedBox(height: CajuiSpacing.sm),
        _seeWhatWasRead(context),
      ],
    );
  }

  /// De onde veio a proposta: daqui, e não da nuvem (RN-780).
  static const Widget _readHere = CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: 'Li o comprovante aqui no aparelho, só com as regras locais.',
    meaning:
        'Confira a categoria antes de lançar. Nada é gravado sem o seu toque.',
  );

  /// O lançamento que já existe e **parece** ser este comprovante: mesmo
  /// valor, mesma data e mesmo lugar (RN-221).
  ///
  /// A regra vivia no domínio desde a Fase 6 e nenhuma tela a chamava: o app
  /// deixava lançar o mesmo comprovante duas vezes sem dizer nada.
  Entry? get _alreadyThere {
    final proposal = capture.proposal;
    final merchant = proposal.merchant;
    final amount = proposal.amount.value;
    final on = proposal.occurredOn.value;
    // Comprovante em que a leitura não resolveu valor, data ou lugar não dá
    // para comparar com nada: aí não há aviso, e a pessoa confere como já
    // conferia.
    if (merchant == null || amount == null || on == null) return null;
    return PossibleDuplicate.among(
      book.entries,
      amount: amount,
      occurredOn: on,
      description: merchant,
    );
  }

  /// **Aviso, e não bloqueio.** Dois cafés de R$ 8,50 no mesmo dia são
  /// legítimos: quem decide é quem está olhando (RN-221).
  ///
  /// O texto é o do estado "Parece repetido" da gallery, aprovado na Fase 3:
  /// o desenho existia desde lá, e era o app que ainda não o tinha.
  Widget _duplicateNotice(Entry existing) => CajuiNotice(
    what:
        'Já existe um lançamento de ${MoneyFormat.brl(existing.amount)} '
        'em ${existing.description}, '
        '${_when(existing.occurredOn)}.',
    meaning: 'É outro?',
  );

  /// "hoje", quando for hoje; no dia tal, quando não.
  String _when(LocalDate day) => day == today
      ? 'hoje'
      : 'no dia ${day.day} de ${CalendarWords.month(day.budgetMonth)}';

  /// A porta para a transparência do fluxo (RN-735).
  Widget _seeWhatWasRead(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: CajuiButton(
      label: 'Ver o que foi lido',
      variant: CajuiButtonVariant.ghost,
      size: CajuiButtonSize.compact,
      onPressed: () => ReadTextPage.open(
        context,
        capture.source.text,
        proposal: capture.proposal,
      ),
    ),
  );

  /// O palpite de categoria, vindo do ramo do estabelecimento ou da IA: vem
  /// como chip para tocar, e **nunca marcado** (RN-744 e RN-782).
  ///
  /// Sem isto, a leitura do ramo não chegaria à pessoa: um cupom de
  /// supermercado sabe que é compra de mercado, e ficava calado.
  Widget _categoryCandidates(BuildContext context, List<String> candidates) {
    final named = [for (final id in candidates.take(3)) ?_categoryOf(id)];
    if (named.isEmpty) return const SizedBox.shrink();
    return _suggestion(
      context,
      named.length == 1
          ? 'Pelo nome do lugar, parece ${named.single.name.toLowerCase()}.'
          : 'Pode ser uma destas:',
      [
        for (final category in named)
          CajuiChip(
            label: category.name,
            selected: false,
            onSelected: (_) =>
                edit((draft) => draft.copyWith(category: category)),
          ),
      ],
    );
  }

  Category? _categoryOf(String id) =>
      book.categories.where((category) => category.id == id).firstOrNull;

  /// Uma pergunta com as respostas em chips, nenhuma marcada.
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
  /// o menor, e não escolhe nenhum (RN-753).
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
