import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// A página dos componentes de ação: botão, botão de ícone, chip e chave.
class ActionPage extends StatefulWidget {
  /// Cria a página de ação.
  const new({super.key});

  @override
  State<ActionPage> createState() => _ActionPageState();
}

class _ActionPageState extends State<ActionPage> {
  static const _categories = ['Mercado', 'Transporte', 'Lazer', 'Saúde'];

  static const Map<CajuiButtonVariant, String> _variantLabels = {
    CajuiButtonVariant.primary: 'Salvar lançamento',
    CajuiButtonVariant.secondary: 'Editar',
    CajuiButtonVariant.ghost: 'Agora não',
    CajuiButtonVariant.destructive: 'Apagar lançamento',
  };

  static const _areas = [
    CajuiNavDestination(icon: CajuiIconData.chart, label: 'Painel'),
    CajuiNavDestination(icon: CajuiIconData.receipt, label: 'Lançamentos'),
    CajuiNavDestination(icon: CajuiIconData.chat, label: 'Assistente'),
    CajuiNavDestination(icon: CajuiIconData.sliders, label: 'Ajustes'),
  ];

  String _category = _categories.first;
  bool _soundsOn = true;
  int _area = 0;

  void _nothing() {}

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Ação',
      lead:
          'Tudo o que se toca nasce da mesma base: responde em menos de '
          '100 ms, tem alvo de 48, anel de foco no teclado e nome para o '
          'leitor de tela. Passe o mouse, aperte e navegue com Tab.',
      sections: [
        _buttonVariants(),
        _buttonStates(),
        _iconButtons(),
        _chips(),
        _switches(),
        _navBar(),
      ],
    );
  }

  Widget _navBar() {
    return GallerySection(
      title: 'Barra de navegação',
      description:
          'As áreas do app, no pé da tela, onde o polegar alcança. A área em '
          'vigor é marcada pela pílula e pelo peso do nome, não só pela cor. '
          'Toda área tem nome à vista: ícone sozinho obriga a adivinhar.',
      child: GallerySpecimen(
        state: 'Ao vivo',
        width: 390,
        child: CajuiNavBar(
          destinations: _areas,
          selectedIndex: _area,
          onSelected: (index) => setState(() => _area = index),
        ),
      ),
    );
  }

  Widget _buttonVariants() {
    return GallerySection(
      title: 'Botão · variantes',
      description:
          'Uma ação principal por tela. A destrutiva só aparece depois de '
          'uma pergunta, nunca como primeira opção.',
      child: GallerySpecimens(
        children: [
          for (final MapEntry(key: variant, value: label)
              in _variantLabels.entries)
            GallerySpecimen(
              state: variant.name,
              child: CajuiButton(
                label: label,
                variant: variant,
                onPressed: _nothing,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buttonStates() {
    return GallerySection(
      title: 'Botão · estados',
      description:
          'Carregando mantém a largura e continua dizendo o que faz; '
          'inativo perde o contraste de propósito, e o motivo fica escrito '
          'perto dele.',
      child: GallerySpecimens(
        children: [
          _button('Repouso'),
          _button('Com ícone', icon: CajuiIconData.plus),
          _button('Carregando', loading: true),
          _button('Inativo', enabled: false),
          _button('Compacto', size: CajuiButtonSize.compact),
        ],
      ),
    );
  }

  Widget _button(
    String state, {
    CajuiIconData? icon,
    bool loading = false,
    bool enabled = true,
    CajuiButtonSize size = CajuiButtonSize.regular,
  }) {
    return GallerySpecimen(
      state: state,
      child: CajuiButton(
        label: 'Confirmar',
        icon: icon,
        loading: loading,
        size: size,
        onPressed: enabled ? _nothing : null,
      ),
    );
  }

  Widget _iconButtons() {
    return GallerySection(
      title: 'Botão de ícone',
      description:
          'O desenho tem 24, o alvo tem 48. O nome para o leitor de tela é '
          'obrigatório: ícone sozinho não diz nada a quem não vê.',
      child: GallerySpecimens(
        children: [
          for (final variant in CajuiButtonVariant.values)
            _iconButton(variant.name, variant: variant),
          _iconButton('Inativo', enabled: false),
        ],
      ),
    );
  }

  Widget _iconButton(
    String state, {
    CajuiButtonVariant variant = CajuiButtonVariant.ghost,
    bool enabled = true,
  }) {
    return GallerySpecimen(
      state: state,
      child: CajuiIconButton(
        icon: CajuiIconData.share,
        semanticLabel: 'Compartilhar',
        variant: variant,
        onPressed: enabled ? _nothing : null,
      ),
    );
  }

  Widget _chips() {
    return GallerySection(
      title: 'Chip',
      description:
          'O selecionado muda de cor e ganha o ícone de visto: cor nunca é '
          'o único sinal.',
      child: GallerySpecimens(
        children: [
          GallerySpecimen(state: 'Escolha única, ao vivo', child: _liveChips()),
          const GallerySpecimen(
            state: 'Inativo',
            child: CajuiChip(
              label: 'Assinaturas',
              selected: false,
              onSelected: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveChips() {
    return Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final category in _categories)
          CajuiChip(
            label: category,
            selected: category == _category,
            onSelected: (_) => setState(() => _category = category),
          ),
      ],
    );
  }

  Widget _switches() {
    return GallerySection(
      title: 'Chave',
      description: 'Liga e desliga na hora, sem botão de salvar.',
      child: GallerySpecimens(
        children: [
          _switch(
            _soundsOn ? 'Ligada, ao vivo' : 'Desligada, ao vivo',
            value: _soundsOn,
            onChanged: (value) => setState(() => _soundsOn = value),
          ),
          _switch('Inativa, ligada', value: true),
          _switch('Inativa, desligada', value: false),
        ],
      ),
    );
  }

  Widget _switch(
    String state, {
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return GallerySpecimen(
      state: state,
      child: CajuiSwitch(
        value: value,
        semanticLabel: 'Sons do app',
        onChanged: onChanged,
      ),
    );
  }
}
