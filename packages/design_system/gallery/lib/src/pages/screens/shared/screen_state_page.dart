import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/shared/variant_slug.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_pager.dart';

/// A página de uma tela de estado: o aparelho e o seletor de estados.
///
/// Todas as telas usam esta mesma página, para que conferir um estado seja
/// sempre o mesmo gesto: escolher o estado, olhar o aparelho, ler a nota.
/// Em tela larga, os estados ficam ao lado do aparelho, na área que antes
/// sobrava vazia; em tela estreita, viram uma linha só, para o aparelho
/// aparecer logo abaixo do título.
class ScreenStatePage extends StatefulWidget {
  /// Cria a página da tela [title] com os estados [variants], aberta no
  /// estado [initialIndex].
  const new({
    required this.title,
    required this.lead,
    required this.variants,
    this.initialIndex = 0,
    super.key,
  });

  /// O nome da tela.
  final String title;

  /// O papel da tela no app.
  final String lead;

  /// Os estados, na ordem do seletor.
  final List<ScreenVariant> variants;

  /// O estado aberto ao entrar. Quem chega pela vitrine de estados cai
  /// direto no que tocou, e não no primeiro da lista.
  final int initialIndex;

  /// A chave do seletor: com ela o teste separa os chips de estado dos
  /// chips que a própria tela mostra, como as sugestões da Juju.
  static const ValueKey<String> selectorKey = ValueKey('screen-variants');

  /// A chave da linha de estado da tela estreita: anterior, o estado e
  /// próximo.
  static const ValueKey<String> stepperKey = ValueKey('screen-stepper');

  /// A partir desta largura, o aparelho (390) e uma coluna de chips com
  /// folga cabem lado a lado. Abaixo dela, os chips iriam para baixo do
  /// aparelho, onde ninguém os acha.
  static const double wideFrom = 760;

  @override
  State<ScreenStatePage> createState() => _ScreenStatePageState();
}

class _ScreenStatePageState extends State<ScreenStatePage> {
  late int _index = widget.initialIndex;

  /// A mesma página pedida de novo em outro estado — outro toque na
  /// vitrine — troca o estado; sem isto, o estado antigo ficaria preso.
  @override
  void didUpdateWidget(ScreenStatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _index = widget.initialIndex;
    }
  }

  ScreenVariant get _variant => widget.variants[_index];

  int get _count => widget.variants.length;

  /// Mostra o estado [index] e avisa a casca, para o endereço acompanhar
  /// (`?estado=sem-rede`): o link copiado abre a tela no mesmo estado.
  void _show(int index) {
    setState(() => _index = index);
    GalleryPager.maybeOf(context)?.onState
        ?.call(variantSlug(widget.variants[index].label));
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: widget.title,
      lead: widget.lead,
      sections: [
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= ScreenStatePage.wideFrom
              ? _wide(context)
              : _narrow(context),
        ),
      ],
    );
  }

  /// O aparelho à esquerda e, à direita, os estados e a nota: escolher e
  /// olhar acontecem na mesma altura, sem rolar.
  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _phone(),
        const SizedBox(width: CajuiSpacing.section),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _selector(),
              const SizedBox(height: CajuiSpacing.lg),
              _note(context, '${_index + 1} de $_count · ${_variant.note}'),
            ],
          ),
        ),
      ],
    );
  }

  /// No celular, os chips de dezoito estados enchiam a tela antes do
  /// aparelho aparecer. A linha de estado ocupa a altura de um botão; a
  /// nota vai para baixo do aparelho, sem a posição, que já está na linha.
  Widget _narrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepper(context),
        const SizedBox(height: CajuiSpacing.lg),
        _phone(),
        const SizedBox(height: CajuiSpacing.lg),
        _note(context, _variant.note),
      ],
    );
  }

  Widget _phone() => PhoneFrame(
    child: KeyedSubtree(
      key: ValueKey(_index),
      child: Builder(builder: _variant.builder),
    ),
  );

  Widget _selector() {
    return Wrap(
      key: ScreenStatePage.selectorKey,
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final (index, variant) in widget.variants.indexed)
          CajuiChip(
            label: variant.label,
            selected: index == _index,
            onSelected: (_) => _show(index),
          ),
      ],
    );
  }

  /// Anterior, o estado e próximo, numa linha. Dá a volta nas pontas: do
  /// último, o próximo é o primeiro — com dezoito estados, voltar um a um
  /// até o começo cansaria, e a posição diz onde se está.
  Widget _stepper(BuildContext context) {
    return Row(
      key: ScreenStatePage.stepperKey,
      children: [
        CajuiIconButton(
          icon: CajuiIconData.chevronLeft,
          semanticLabel: 'Estado anterior',
          variant: CajuiButtonVariant.secondary,
          onPressed: () => _show((_index - 1 + _count) % _count),
        ),
        Expanded(child: _position(context)),
        CajuiIconButton(
          icon: CajuiIconData.chevronRight,
          semanticLabel: 'Próximo estado',
          variant: CajuiButtonVariant.secondary,
          onPressed: () => _show((_index + 1) % _count),
        ),
      ],
    );
  }

  /// O nome do estado e onde ele está na lista. É região viva: quem usa
  /// leitor de tela ouve o estado novo a cada toque, sem procurar.
  Widget _position(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(
            _variant.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.label.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
          Text(
            '${_index + 1} de $_count',
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(BuildContext context, String text) {
    final theme = CajuiTheme.of(context);
    return Text(
      text,
      style: theme.typography.caption.copyWith(color: theme.colors.text.muted),
    );
  }
}
