import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_missing.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_state.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O pé do formulário de lançar: o aviso, se houver, e o botão de gravar.
///
/// O aviso fica aqui, junto do botão, e não no alto da tela: quem tocou em
/// "Salvar" está olhando para baixo.
class EntryFormFooter extends ConsumerWidget {
  /// Cria o pé do formulário no estado [state].
  const new({
    required this.state,
    required this.submitLabel,
    required this.onResolve,
    this.extraActions = const [],
    super.key,
  });

  /// O estado da tela.
  final EntryFormState state;

  /// O texto do botão quando nada falta: "Salvar", "Guardar correção".
  final String submitLabel;

  /// Executa uma saída de um erro do catálogo e refaz os campos.
  final void Function(ErrorCode code, int index) onResolve;

  /// Botões a mais, embaixo do principal.
  final List<Widget> extraActions;

  /// O erro de valor zerado fica sob o campo, que já é a saída; os outros
  /// viram aviso com as saídas do catálogo.
  static bool isFieldError(PresentedError? problem) =>
      problem?.code == ErrorCode.entry03;

  /// A recusa a resolver, quando o estado tem uma.
  static PresentedError? problemOf(EntryFormState state) => switch (state) {
    EntryFormEditing(:final problem) => problem,
    EntryFormConfirming() || EntryFormSaving() || EntryFormSaved() => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.read(entryFormProvider.notifier);
    final problem = problemOf(state);
    final current = state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null && !isFieldError(problem)) ...[
          ErrorNotice(
            error: problem,
            onAction: (index) => onResolve(problem.code, index),
          ),
          const SizedBox(height: CajuiSpacing.md),
        ],
        if (current is EntryFormConfirming)
          _confirm(current, form)
        else
          _submit(form),
        for (final action in extraActions) ...[
          const SizedBox(height: CajuiSpacing.sm),
          action,
        ],
      ],
    );
  }

  Widget _submit(EntryFormViewModel form) => CajuiButton(
    label: EntryFormMissing.of(state.draft) ?? submitLabel,
    expand: true,
    loading: state is EntryFormSaving,
    // Mudo: o toque abafaria a semente, que soa logo depois.
    silent: true,
    onPressed: state.draft.isComplete ? form.submit : null,
  );

  /// A pergunta do valor fora do comum. O zero a mais é o erro mais comum
  /// de quem digita valor, e o mais caro de achar depois na lista.
  static Widget _confirm(EntryFormConfirming state, EntryFormViewModel form) {
    final amount = BrlFormatter.format(state.draft.amountCents);
    final typical = BrlFormatter.format(state.typical.cents);
    return CajuiNotice(
      what: 'Confere o valor: $amount?',
      meaning: 'Nessa categoria, o normal fica perto de $typical.',
      primaryAction: CajuiNoticeAction(
        label: 'Está certo, salvar',
        onPressed: () => form.submit(confirmed: true),
      ),
      secondaryAction: CajuiNoticeAction(
        label: 'Corrigir o valor',
        onPressed: form.reviewAmount,
      ),
    );
  }
}
