import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// A página dos componentes de estado: aviso, vazio, esqueleto, carregando e
/// o ícone-herói.
class StatePage extends StatefulWidget {
  /// Cria a página de estados.
  const new({super.key});

  @override
  State<StatePage> createState() => _StatePageState();
}

class _StatePageState extends State<StatePage> {
  static const double _wide = 440;

  bool _dismissed = false;

  void _nothing() {}

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Estados',
      lead:
          'O que a tela mostra quando não tem o dado: porque está vindo, '
          'porque não existe ainda, ou porque algo falhou. Nenhum desses é '
          'uma tela em branco.',
      sections: [_notices(), _dismissible(), _empty(), _loading(context)],
    );
  }

  Widget _notices() {
    return GallerySection(
      title: 'Aviso',
      description:
          'Fica na tela até ser resolvido — não some sozinho como um balão. '
          'Sempre diz o que aconteceu, o que isso significa e o que fazer.',
      child: GallerySpecimens(
        children: [..._calmNotices(), ..._urgentNotices()],
      ),
    );
  }

  List<Widget> _calmNotices() => [
    _notice(
      CajuiNoticeIntent.info,
      'A fatura de outubro fecha em 3 dias.',
      'O que for comprado depois disso entra na de novembro.',
    ),
    _notice(
      CajuiNoticeIntent.positive,
      'Lançamento salvo.',
      'Já conta no Meu mês de outubro.',
    ),
  ];

  List<Widget> _urgentNotices() => [
    _notice(
      CajuiNoticeIntent.attention,
      'Sem conexão agora.',
      'O lançamento ficou guardado no aparelho e sobe sozinho quando a '
          'internet voltar.',
      action: 'Tentar de novo',
    ),
    _notice(
      CajuiNoticeIntent.danger,
      'Não consegui ler este comprovante.',
      'A imagem veio escura demais para o texto aparecer.',
      action: 'Digitar à mão',
      secondary: 'Tentar outra foto',
    ),
  ];

  Widget _notice(
    CajuiNoticeIntent intent,
    String what,
    String meaning, {
    String? action,
    String? secondary,
  }) {
    return GallerySpecimen(
      state: intent.name,
      width: _wide,
      child: CajuiNotice(
        intent: intent,
        what: what,
        meaning: meaning,
        primaryAction: action == null
            ? null
            : CajuiNoticeAction(label: action, onPressed: _nothing),
        secondaryAction: secondary == null
            ? null
            : CajuiNoticeAction(label: secondary, onPressed: _nothing),
      ),
    );
  }

  Widget _dismissible() {
    return GallerySection(
      title: 'Aviso dispensável',
      description: 'Só quem lê dispensa. O app nunca tira o aviso por conta.',
      child: GallerySpecimen(
        state: _dismissed ? 'Dispensado' : 'Com botão de fechar',
        width: _wide,
        child: _dismissed
            ? CajuiButton(
                label: 'Mostrar de novo',
                variant: CajuiButtonVariant.secondary,
                size: CajuiButtonSize.compact,
                onPressed: () => setState(() => _dismissed = false),
              )
            : CajuiNotice(
                intent: CajuiNoticeIntent.info,
                what: 'Dá para ligar os sons do app.',
                meaning: 'São curtos e baixos. Ficam em Ajustes.',
                onDismiss: () => setState(() => _dismissed = true),
              ),
      ),
    );
  }

  Widget _empty() {
    return GallerySection(
      title: 'Estado vazio',
      description:
          'Primeiro uso não é erro: a tela explica o que vai aparecer ali e '
          'oferece o primeiro passo.',
      child: GallerySpecimens(
        children: [
          _firstUse(),
          const GallerySpecimen(
            state: 'Só texto',
            width: _wide,
            child: CajuiEmptyState(
              title: 'Nenhuma dívida cadastrada',
              message: 'Se aparecer alguma, é aqui que ela fica à vista.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _firstUse() {
    return GallerySpecimen(
      state: 'Com ilustração e ação',
      width: _wide,
      child: CajuiEmptyState(
        illustration: const CajuiHeroFruit(size: 120),
        title: 'Nenhum lançamento em outubro',
        message:
            'Compartilhe um comprovante de qualquer app, ou anote à mão. '
            'Leva uns dez segundos.',
        action: CajuiNoticeAction(
          label: 'Anotar o primeiro',
          onPressed: _nothing,
        ),
      ),
    );
  }

  Widget _loading(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return GallerySection(
      title: 'Esqueleto, carregando e ícone-herói',
      description:
          'O esqueleto tem a forma do que vem. Os três pontos respiram, não '
          'giram. Com movimento reduzido, tudo isso fica parado.',
      child: GallerySpecimens(
        children: [
          const GallerySpecimen(
            state: 'Esqueleto de cartão',
            width: 280,
            child: _CardSkeleton(),
          ),
          GallerySpecimen(
            state: 'Carregando',
            child: CajuiLoadingDots(color: colors.text.muted, dotSize: 8),
          ),
          const GallerySpecimen(
            state: 'Ícone-herói',
            child: CajuiHeroFruit(semanticLabel: 'Cajuí maduro'),
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const CajuiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CajuiSkeleton.line(width: 120),
          SizedBox(height: CajuiSpacing.md),
          CajuiSkeleton(height: 32, width: 180),
          SizedBox(height: CajuiSpacing.lg),
          CajuiSkeleton.line(),
        ],
      ),
    );
  }
}
