import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/budget/presentation/week_effect_line.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/presentation/date_section.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_state.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:cajui/src/features/ledger/presentation/payment_section.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Troca o rascunho do formulário a partir de fora dele.
typedef EntryFormEdit = void Function(
  EntryDraft Function(EntryDraft draft) change,
);

/// Lançar uma despesa à mão (UC-ENTRY-01 e UC-ENTRY-02).
///
/// A ordem dos campos é a da lembrança: quanto foi, o que foi, de que tipo,
/// por onde saiu, quando.
class EntryFormPage extends ConsumerStatefulWidget {
  /// Cria a tela de lançar.
  ///
  /// Os parâmetros existem para a conferência de um comprovante reaproveitar
  /// este formulário inteiro — mesmos campos, mesmas regras, mesmos erros —
  /// mudando só a moldura: [title], o que vai acima dos campos ([header]), as
  /// ações a mais no pé ([extraActions]) e o que acontece depois de gravar.
  const new({
    this.title = 'Nova despesa',
    this.header,
    this.extraActions = const [],
    this.onSaved,
    this.onBack,
    super.key,
  });

  /// O título da tela.
  final String title;

  /// O que aparece acima dos campos. Recebe [EntryFormEdit], para trocar o
  /// rascunho **e** fazer os campos de valor mostrarem o número novo.
  final Widget Function(BuildContext context, EntryFormEdit edit)? header;

  /// As ações abaixo de "Lançar".
  final List<Widget> extraActions;

  /// Chamado com o lançamento gravado. Sem isto, a tela só fecha.
  final ValueChanged<Entry>? onSaved;

  /// O que o botão de voltar faz. Sem isto, fecha a tela.
  final VoidCallback? onBack;

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const EntryFormPage()));
  }

  @override
  ConsumerState<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends ConsumerState<EntryFormPage> {
  /// Sobe quando o app troca os valores das linhas de pagamento.
  int _revision = 0;

  EntryFormViewModel get _form => ref.read(entryFormProvider.notifier);

  static const Map<Block, String> _blockHelpers = {
    Block.fixed: 'Entra nos gastos fixos do mês',
    Block.variable: 'Entra nos gastos variáveis do mês',
    Block.debt: 'Entra nas dívidas do mês',
  };

  Future<void> _pickCategory(LedgerBook book, EntryDraft draft) async {
    final picked = await OptionPickerPage.open<Category>(
      context,
      title: 'Categoria',
      options: book.categories,
      labelOf: (category) => category.name,
      selected: draft.category,
    );
    if (picked != null) _form.edit((d) => d.copyWith(category: picked));
  }

  Future<void> _pickMethod(LedgerBook book, {required bool second}) async {
    final draft = ref.read(entryFormProvider).draft;
    final taken = second ? draft.method : draft.secondMethod;
    final picked = await OptionPickerPage.open<PaymentMethod>(
      context,
      title: 'Por onde foi pago',
      // A mesma forma duas vezes não é dividir: é uma linha só.
      options: [...book.methods.where((method) => method != taken)],
      labelOf: (method) => method.name,
      selected: second ? draft.secondMethod : draft.method,
    );
    if (picked == null) return;
    _form.edit(
      (d) => second
          ? d.copyWith(secondMethod: picked)
          : d.copyWith(method: picked),
    );
  }

  /// Em quantas vezes, no cartão. Até doze: mais que isso é raro, e lista
  /// comprida esconde o "à vista", que é o caso comum.
  Future<void> _pickInstallments() async {
    final draft = ref.read(entryFormProvider).draft;
    final total = Money.fromCents(draft.amountCents);
    final picked = await OptionPickerPage.open<int>(
      context,
      title: 'Em quantas vezes',
      options: [for (var count = 1; count <= _maxInstallments; count++) count],
      labelOf: (count) => _installmentLabel(count, total),
      selected: draft.installmentCount,
    );
    if (picked != null) _form.edit((d) => d.copyWith(installments: picked));
  }

  static const _maxInstallments = 12;

  static String _installmentLabel(int count, Money total) {
    if (count == 1) return 'À vista';
    if (!total.isPositive) return '${count}x';
    final each = total.split(count).first;
    return '${count}x de ${BrlFormatter.format(each.cents)}';
  }

  /// Troca o rascunho por iniciativa do app — um candidato de valor tocado,
  /// por exemplo — e faz os campos de valor renascerem com o número novo.
  void _editByApp(EntryDraft Function(EntryDraft draft) change) {
    _form.edit(change);
    setState(() => _revision++);
  }

  Future<void> _byApp(Future<void> Function() change) async {
    await change();
    if (mounted) setState(() => _revision++);
  }

  void _closeWhenSaved(EntryFormState? _, EntryFormState next) {
    if (next is! EntryFormSaved) return;
    CajuiFeedbackScope.of(context).saved();
    final onSaved = widget.onSaved;
    onSaved == null ? Navigator.of(context).pop() : onSaved(next.entry);
  }

  /// A descrição que já vem preenchida, quando o rascunho nasce de uma
  /// captura. Criado uma vez: o campo é de quem digita dali em diante.
  late final _description = TextEditingController(
    text: ref.read(entryFormProvider).draft.description,
  );

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(entryFormProvider, _closeWhenSaved);
    final state = ref.watch(entryFormProvider);
    final book = ref.watch(ledgerProvider).value;
    if (book == null) return const SizedBox.shrink();
    final problem = switch (state) {
      EntryFormEditing(:final problem) => problem,
      EntryFormSaving() || EntryFormSaved() => null,
    };
    final header = widget.header;
    return CajuiScreen(
      title: widget.title,
      onBack: widget.onBack ?? Navigator.of(context).pop,
      footer: _footer(state, problem),
      children: [
        if (header != null) ...[header(context, _editByApp), _gap],
        ..._fields(book, state.draft, problem),
      ],
    );
  }

  /// O erro de valor zerado fica sob o campo, que já é a saída; os outros
  /// viram aviso com as saídas do catálogo.
  bool _isFieldError(PresentedError? problem) =>
      problem?.code == ErrorCode.entry03;

  List<Widget> _fields(
    LedgerBook book,
    EntryDraft draft,
    PresentedError? problem,
  ) {
    final fieldError = _isFieldError(problem) ? problem!.text.message : null;
    return [
      ..._whatWasBought(book, draft, fieldError),
      _gap,
      _howItWasPaid(book, draft, fieldError),
      _gap,
      DateSection(
        selected: draft.occurredOn,
        today: ref.watch(clockProvider).today(),
        onChanged: (day) => _form.edit((d) => d.copyWith(occurredOn: day)),
      ),
    ];
  }

  static const _gap = SizedBox(height: CajuiSpacing.lg);

  /// O "o quê": valor, descrição e categoria.
  List<Widget> _whatWasBought(
    LedgerBook book,
    EntryDraft draft,
    String? fieldError,
  ) {
    return [
      CajuiAmountField(
        key: ValueKey(('amount', _revision)),
        label: 'Valor',
        initialCents: draft.amountCents,
        error: draft.amountCents <= 0 ? fieldError : null,
        onChanged: (cents) => _form.edit((d) => d.copyWith(amountCents: cents)),
      ),
      _gap,
      CajuiTextField(
        label: 'O que foi',
        controller: _description,
        hint: 'Mercado, ônibus, farmácia',
        onChanged: (text) => _form.edit((d) => d.copyWith(description: text)),
      ),
      _gap,
      CajuiSelectField(
        label: 'Categoria',
        value: draft.category?.name,
        helper: _blockHelpers[draft.category?.block],
        onPressed: () => _pickCategory(book, draft),
      ),
    ];
  }

  /// O "por onde": separado do "o quê" até no código da tela.
  Widget _howItWasPaid(LedgerBook book, EntryDraft draft, String? fieldError) {
    return PaymentSection(
      draft: draft,
      voucherBalance: book.voucher.balance,
      revision: _revision,
      lineError: draft.amountCents > 0 ? fieldError : null,
      onPickMethod: ({required second}) => _pickMethod(book, second: second),
      onToggleSplit: () => _byApp(_form.toggleSplit),
      onPickInstallments: _pickInstallments,
      onLineCents: (cents, {required second}) => _form.edit(
        (d) => second
            ? d.copyWith(secondCents: cents)
            : d.copyWith(firstCents: cents),
      ),
    );
  }

  Widget _footer(EntryFormState state, PresentedError? problem) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null && !_isFieldError(problem)) ...[
          ErrorNotice(
            error: problem,
            onAction: (index) =>
                _byApp(() => _form.resolve(problem.code, index)),
          ),
          const SizedBox(height: CajuiSpacing.md),
        ],
        WeekEffectLine(draft: state.draft),
        CajuiButton(
          label: 'Lançar',
          expand: true,
          loading: state is EntryFormSaving,
          onPressed: state.draft.isComplete ? _form.submit : null,
        ),
        for (final action in widget.extraActions) ...[
          const SizedBox(height: CajuiSpacing.sm),
          action,
        ],
      ],
    );
  }
}
