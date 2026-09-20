import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// A página dos campos: texto, valor e escolha, cada um em todos os estados.
class FieldPage extends StatefulWidget {
  /// Cria a página de campos.
  const new({super.key});

  @override
  State<FieldPage> createState() => _FieldPageState();
}

class _FieldPageState extends State<FieldPage> {
  static const double _fieldWidth = 300;
  static const _methods = ['Pix', 'Débito', 'Crédito', 'Vale alimentação'];

  final _filled = TextEditingController(text: 'Mercado do bairro');
  int _cents = 3840;
  String? _method;
  bool _choosing = false;

  @override
  void dispose() {
    _filled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Campos',
      lead:
          'O rótulo fica sempre à vista, fora do campo. O erro aparece '
          'embaixo, fica até ser resolvido e diz o que fazer — nunca só '
          '"valor inválido".',
      sections: [_textFields(), _amountFields(), _selectFields()],
    );
  }

  Widget _specimen(String state, Widget field) =>
      GallerySpecimen(state: state, width: _fieldWidth, child: field);

  Widget _textFields() {
    return GallerySection(
      title: 'Campo de texto',
      child: GallerySpecimens(
        children: [
          _text('Vazio, com dica', hint: 'Mercado, farmácia…'),
          _text('Preenchido', controller: _filled),
          _text('Com ajuda', helper: 'Como aparece no comprovante.'),
          _text(
            'Com erro',
            error: 'Escreva onde foi a compra, como "Mercado".',
          ),
          _text('Inativo', enabled: false),
        ],
      ),
    );
  }

  Widget _text(
    String state, {
    TextEditingController? controller,
    String? hint,
    String? helper,
    String? error,
    bool enabled = true,
  }) {
    return _specimen(
      state,
      CajuiTextField(
        label: 'Onde foi',
        controller: controller,
        hint: hint,
        helper: helper,
        error: error,
        enabled: enabled,
      ),
    );
  }

  Widget _amountFields() {
    return GallerySection(
      title: 'Campo de valor',
      description:
          'Os centavos entram da direita para a esquerda, como em maquininha: '
          'não existe vírgula para errar. O valor guardado é inteiro, em '
          'centavos.',
      child: GallerySpecimens(
        children: [
          _amount(
            'Ao vivo · ${BrlFormatter.format(_cents)}',
            cents: _cents,
            onChanged: (cents) => setState(() => _cents = cents),
          ),
          _amount('Com erro', error: 'Digite um valor maior que zero.'),
          _amount('Inativo', cents: 19600, enabled: false),
        ],
      ),
    );
  }

  Widget _amount(
    String state, {
    int cents = 0,
    String? error,
    bool enabled = true,
    ValueChanged<int>? onChanged,
  }) {
    return _specimen(
      state,
      CajuiAmountField(
        label: 'Valor',
        initialCents: cents,
        error: error,
        enabled: enabled,
        onChanged: onChanged ?? (_) {},
      ),
    );
  }

  Widget _selectFields() {
    return GallerySection(
      title: 'Campo de escolha e lista de opções',
      description:
          'No app, a lista abre numa folha inferior. Aqui ela abre logo '
          'abaixo, para os dois aparecerem juntos.',
      child: GallerySpecimens(
        children: [
          _specimen(_method == null ? 'Vazio, ao vivo' : 'Escolhido', _live()),
          _specimen(
            'Com erro',
            CajuiSelectField(
              label: 'Por onde pagou',
              error: 'Escolha por onde saiu o dinheiro.',
              onPressed: () {},
            ),
          ),
          _specimen(
            'Inativo',
            const CajuiSelectField(
              label: 'Por onde pagou',
              value: 'Pix',
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _live() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CajuiSelectField(
          label: 'Por onde pagou',
          value: _method,
          onPressed: () => setState(() => _choosing = !_choosing),
        ),
        if (_choosing) ...[
          const SizedBox(height: CajuiSpacing.sm),
          CajuiOptionList<String>(
            options: _methods,
            labelOf: (method) => method,
            selected: _method,
            onSelected: _choose,
          ),
        ],
      ],
    );
  }

  void _choose(String method) {
    setState(() {
      _method = method;
      _choosing = false;
    });
  }
}
