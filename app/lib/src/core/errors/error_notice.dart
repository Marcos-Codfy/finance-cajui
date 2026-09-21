import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Um erro do catálogo na tela: aviso persistente, com as saídas dentro dele
/// — a solução fica junto da explicação, e não do outro lado da tela.
class ErrorNotice extends StatelessWidget {
  /// Mostra [error]. [onAction] recebe o índice da saída tocada.
  const new({required this.error, required this.onAction, super.key});

  /// O erro, já com os valores no texto.
  final PresentedError error;

  /// Chamado com o índice da saída escolhida, na ordem do catálogo.
  final ValueChanged<int> onAction;

  /// As classes em que o código ajuda a procurar o motivo (catálogo, regra
  /// 7). Nas outras ele seria ruído: ninguém pesquisa "E-ENTRY-01".
  static const Set<ErrorClass> _classesThatShowCode = {
    ErrorClass.capture,
    ErrorClass.sync,
    ErrorClass.data,
    ErrorClass.server,
    ErrorClass.app,
  };

  CajuiNoticeAction? _action(int index) {
    final labels = error.text.actions;
    if (index >= labels.length) return null;
    return CajuiNoticeAction(
      label: labels[index],
      onPressed: () => onAction(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final showsCode = _classesThatShowCode.contains(error.code.errorClass);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CajuiNotice(
          what: error.text.message,
          primaryAction: _action(0),
          secondaryAction: _action(1),
        ),
        if (showsCode)
          Padding(
            padding: const EdgeInsets.only(top: CajuiSpacing.xs),
            child: Text(
              'Código ${error.code.code}',
              style: theme.typography.caption.copyWith(
                color: theme.colors.text.faint,
              ),
            ),
          ),
      ],
    );
  }
}
