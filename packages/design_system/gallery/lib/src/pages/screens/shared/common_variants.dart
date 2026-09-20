import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// Os três estados que toda tela tem, além de "com dados": carregando, erro
/// do servidor e sem rede.
///
/// Ficam num lugar só para que o texto e a forma sejam os mesmos no app
/// inteiro — quem aprendeu a ler o aviso numa tela já sabe ler nas outras.
abstract final class CommonVariants {
  /// Carregando: o esqueleto tem a forma do que vem.
  static ScreenVariant loading(String title) => ScreenVariant(
    label: 'Carregando',
    note: 'Esqueleto com a forma do conteúdo. Nada de tela em branco.',
    builder: (_) => MockScreen(
      title: title,
      children: const [_SkeletonCard(), _SkeletonCard(), _SkeletonCard()],
    ),
  );

  /// Erro interno do servidor, com o identificador para achar no log.
  static ScreenVariant serverError(String title) => ScreenVariant(
    label: 'Erro',
    note: 'E-SRV-01: erro interno do servidor, com identificador para o log.',
    builder: (_) => MockScreen(
      title: title,
      children: [
        CajuiNotice(
          intent: CajuiNoticeIntent.danger,
          what: 'O servidor falhou ao montar esta tela.',
          meaning:
              'Seus dados estão guardados; foi só esta consulta que não '
              'voltou. Se repetir, o código E-SRV-01 · 7f3a9c acha o motivo '
              'no registro do servidor.',
          primaryAction: CajuiNoticeAction(
            label: 'Tentar de novo',
            onPressed: () {},
          ),
        ),
      ],
    ),
  );

  /// Sem rede: o que estava guardado continua à vista, com a hora da cópia.
  static ScreenVariant offline(String title, List<Widget> cached) {
    return ScreenVariant(
      label: 'Sem rede',
      note: 'E-NET-02. Mostra a última cópia guardada, com a hora dela.',
      builder: (_) => MockScreen(
        title: title,
        children: [
          CajuiNotice(
            what: 'Sem conexão agora.',
            meaning:
                'Estes são os números de hoje às 14:32, guardados no '
                'aparelho. Atualizo sozinho quando a rede voltar.',
            primaryAction: CajuiNoticeAction(
              label: 'Tentar de novo',
              onPressed: () {},
            ),
          ),
          const SizedBox(height: CajuiSpacing.lg),
          ...cached,
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: CajuiSpacing.lg),
      child: CajuiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CajuiSkeleton.line(width: 120),
            SizedBox(height: CajuiSpacing.md),
            CajuiSkeleton(height: 32, width: 180),
          ],
        ),
      ),
    );
  }
}
