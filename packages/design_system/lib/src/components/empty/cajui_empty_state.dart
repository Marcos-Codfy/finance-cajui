import 'package:design_system/src/components/button/cajui_button.dart';
import 'package:design_system/src/components/notice/cajui_notice_action.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O estado vazio: a tela antes de existir qualquer dado.
///
/// É o primeiro contato com cada área do app, então recebe o mesmo cuidado de
/// uma tela cheia: ilustração, uma frase na voz da marca e o próximo passo.
/// Nunca "Nenhum dado encontrado" — o vazio convida, não constata.
class CajuiEmptyState extends StatelessWidget {
  /// Cria o estado vazio.
  const new({
    required this.title,
    required this.message,
    this.illustration,
    this.action,
    super.key,
  });

  /// A frase principal: "Nada lançado ainda."
  final String title;

  /// O convite: "Compartilhe um comprovante de qualquer app, ou lance o
  /// primeiro à mão."
  final String message;

  /// A ilustração — em geral, o ícone-herói.
  final Widget? illustration;

  /// O próximo passo.
  final CajuiNoticeAction? action;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final picture = illustration;
    final next = action;
    return Padding(
      padding: const EdgeInsets.all(CajuiSpacing.section),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (picture != null) ...[
            picture,
            const SizedBox(height: CajuiSpacing.xxl),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.typography.headline.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
          const SizedBox(height: CajuiSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.typography.body.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: CajuiSpacing.xxl),
            CajuiButton(label: next.label, onPressed: next.onPressed),
          ],
        ],
      ),
    );
  }
}
