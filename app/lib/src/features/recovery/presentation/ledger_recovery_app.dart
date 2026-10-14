import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/core/errors/open_failure.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';

/// O que aparece quando o registro do aparelho não abre ao abrir o app.
///
/// O registro é aberto antes da primeira tela. Até aqui, uma falha nessa
/// hora deixava o app numa tela preta para sempre — sem frase, sem saída, e
/// reabrir dava no mesmo. Agora a falha vira o aviso do catálogo: com o
/// registro quebrado (`E-DATA-03`), dá para recomeçar com os dados do
/// servidor, guardando o antigo de lado; com outra falha (`E-APP-01`), dá
/// para tentar abrir de novo.
class LedgerRecoveryApp extends StatefulWidget {
  /// Cria a tela para a falha [error].
  const new({
    required this.error,
    required this.onRetry,
    required this.onStartOver,
    super.key,
  });

  /// O que impediu o registro de abrir.
  final Object error;

  /// Tenta abrir o registro de novo, como está.
  final Future<void> Function() onRetry;

  /// Guarda o registro de lado e abre um novo, que se enche pelo servidor.
  final Future<void> Function() onStartOver;

  /// O código do catálogo para [error]: o registro que não confere é o
  /// `E-DATA-03`; o resto, a falha sem nome (`E-APP-01`).
  static ErrorCode codeOf(Object error) =>
      OpenFailure.codeOf(error) == ErrorCode.data01
      ? ErrorCode.data03
      : ErrorCode.app01;

  @override
  State<LedgerRecoveryApp> createState() => _LedgerRecoveryAppState();
}

class _LedgerRecoveryAppState extends State<LedgerRecoveryApp> {
  /// Um toque por vez: recomeçar duas vezes guardaria de lado o registro
  /// novo, recém-criado.
  bool _busy = false;

  ErrorCode get _code => LedgerRecoveryApp.codeOf(widget.error);

  Future<void> _act(int index) async {
    if (index == 1) {
      unawaited(Clipboard.setData(ClipboardData(text: _code.code)));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final step = _code == ErrorCode.data03
        ? widget.onStartOver
        : widget.onRetry;
    await step();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Cajui',
      color: CajuiThemeData.light().colors.surface.base,
      debugShowCheckedModeBanner: false,
      builder: (context, _) => CajuiAppSurface(
        theme: CajuiAppSurface.themeOf(context),
        feedback: const SilentFeedback(),
        child: _page(),
      ),
    );
  }

  Widget _page() => Builder(
    builder: (context) {
      final theme = CajuiTheme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CajuiSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CajuiSpacing.lg,
            children: [
              Text(
                'Cajui',
                style: theme.typography.headline.copyWith(
                  color: theme.colors.text.primary,
                ),
              ),
              if (_busy)
                Center(child: CajuiLoadingDots(color: theme.colors.text.muted)),
              ErrorNotice(error: _presented(), onAction: _act),
            ],
          ),
        ),
      );
    },
  );

  /// O texto do catálogo, com a fila vazia: na abertura nada ficou na fila.
  PresentedError _presented() =>
      (code: _code, text: ErrorTexts.of(_code).fill(const {'fila': ''}));
}
