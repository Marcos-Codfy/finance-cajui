import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O rodapé da conversa enquanto o extrato está aberto (RN-1115): no lugar
/// do campo de pergunta, "Pode lançar (N)" e "Conferir depois".
///
/// Fica sempre à mão, e não só no fim: dá para lançar o que já está certo
/// sem responder todas as dúvidas — as sem resposta simplesmente não entram.
class StatementFooter extends ConsumerWidget {
  /// Cria o rodapé da conversa [talk].
  const new(this.talk, {super.key});

  /// A conversa aberta.
  final StatementTalkOpen talk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.read(statementTalkProvider.notifier);
    final ready = talk.digest.ready.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiButton(
          label: StatementWords.launch(ready),
          icon: CajuiIconData.check,
          expand: true,
          onPressed: ready == 0 ? null : model.launch,
        ),
        const SizedBox(height: CajuiSpacing.sm),
        _secondary(model),
      ],
    );
  }

  /// "Descartar" tira o extrato de "Para conferir" sem gravar nada: sem
  /// ele, um extrato que não tem o que lançar ficava lá para sempre.
  static Widget _secondary(StatementTalkViewModel model) => Row(
    children: [
      Expanded(
        child: CajuiButton(
          label: 'Conferir depois',
          variant: CajuiButtonVariant.ghost,
          expand: true,
          onPressed: model.close,
        ),
      ),
      Expanded(
        child: CajuiButton(
          label: 'Descartar',
          variant: CajuiButtonVariant.ghost,
          expand: true,
          onPressed: model.discard,
        ),
      ),
    ],
  );
}
