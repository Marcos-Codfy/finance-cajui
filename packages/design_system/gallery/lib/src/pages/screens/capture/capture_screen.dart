import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/capture/capture_form.dart';
import 'package:gallery/src/pages/screens/capture/capture_kind.dart';
import 'package:gallery/src/pages/screens/capture/capture_state.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';

/// A tela de captura num estado: o comprovante chegou pelo compartilhamento
/// e está sendo guardado, lido, conferido — ou algo impediu a leitura.
class CaptureScreen extends StatelessWidget {
  /// Cria a tela no estado [state].
  const new(this.state, {super.key});

  /// O estado desenhado.
  final CaptureState state;

  static const _title = 'Comprovante';
  static const _candidates = ['Remédio', 'Higiene e beleza', 'Mercado'];

  @override
  Widget build(BuildContext context) {
    return switch (state.kind) {
      CaptureKind.progress => _progress(context),
      CaptureKind.form => _form(),
      CaptureKind.question => _question(context),
      CaptureKind.notice => _notice(context),
    };
  }

  Widget _progress(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final detail = state.meaning;
    final muted = theme.colors.text.muted;
    return MockScreen(
      title: _title,
      footer: _actions(),
      children: [
        const SizedBox(height: CajuiSpacing.hero),
        Center(child: CajuiLoadingDots(color: muted, dotSize: 10)),
        const SizedBox(height: CajuiSpacing.xl),
        Text(
          state.what ?? '',
          textAlign: TextAlign.center,
          style: theme.typography.title.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
        if (detail != null)
          Text(
            detail,
            textAlign: TextAlign.center,
            style: theme.typography.caption.copyWith(color: muted),
          ),
      ],
    );
  }

  /// Sem rede e sem IA, a categoria fica em branco e a confiança cai: o app
  /// não finge uma certeza que as regras locais não têm.
  Widget _form() {
    final degraded =
        state == CaptureState.offline || state == CaptureState.aiDown;
    final what = state.what;
    return MockScreen(
      title: 'Confere se é isso?',
      overline: state.overline,
      footer: _actions(),
      children: [
        if (what != null) ...[
          CajuiNotice(intent: state.intent, what: what, meaning: state.meaning),
          const SizedBox(height: CajuiSpacing.lg),
        ],
        CaptureForm(
          category: degraded ? null : 'Mercado',
          confidence: degraded
              ? CajuiConfidenceLevel.low
              : CajuiConfidenceLevel.high,
        ),
      ],
    );
  }

  Widget _question(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return MockScreen(
      title: 'Uma dúvida só',
      footer: _actions(),
      children: [
        const CajuiConfidenceIndicator(CajuiConfidenceLevel.medium),
        const SizedBox(height: CajuiSpacing.md),
        Text(
          state.what ?? '',
          style: theme.typography.body.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
        const SizedBox(height: CajuiSpacing.lg),
        CajuiOptionList<String>(
          options: _candidates,
          labelOf: (candidate) => candidate,
          onSelected: (_) {},
        ),
      ],
    );
  }

  /// Nos avisos, as ações ficam dentro do próprio aviso: a saída está junto
  /// da explicação, e não do outro lado da tela.
  Widget _notice(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final code = state.code;
    final [first, ...rest] = state.actions;
    return MockScreen(
      title: _title,
      children: [
        CajuiNotice(
          intent: state.intent,
          what: state.what ?? '',
          meaning: state.meaning,
          primaryAction: CajuiNoticeAction(label: first, onPressed: () {}),
          secondaryAction: rest.isEmpty
              ? null
              : CajuiNoticeAction(label: rest.first, onPressed: () {}),
        ),
        if (code != null) ...[
          const SizedBox(height: CajuiSpacing.md),
          Text(
            'Código $code',
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
        ],
      ],
    );
  }

  /// As ações do pé da tela: a primeira é a principal; as outras perdem peso
  /// na ordem, até a de descarte, que é só texto.
  Widget? _actions() {
    if (state.actions.isEmpty) return null;
    const weights = [
      CajuiButtonVariant.primary,
      CajuiButtonVariant.secondary,
      CajuiButtonVariant.ghost,
    ];
    final lone = state.actions.length == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, label) in state.actions.indexed)
          Padding(
            padding: const EdgeInsets.only(top: CajuiSpacing.sm),
            child: CajuiButton(
              label: label,
              expand: true,
              variant: lone ? CajuiButtonVariant.ghost : weights[index],
              onPressed: () {},
            ),
          ),
      ],
    );
  }
}
