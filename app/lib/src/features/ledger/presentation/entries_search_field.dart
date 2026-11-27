import 'package:cajui/src/features/ledger/presentation/entries_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A busca pela descrição: o que se digita filtra a lista na hora.
///
/// O texto mora no ViewModel, e não só no campo: o chip da busca também o
/// apaga, e o campo precisa acompanhar — senão a lista volta inteira com a
/// palavra ainda escrita ali.
///
/// O campo só existe enquanto a busca está aberta, e nasce com o foco:
/// quem tocou na lupa quer digitar.
class EntriesSearchField extends ConsumerStatefulWidget {
  /// Cria o campo de busca.
  const new({required this.onClose, super.key});

  /// Fecha a busca: apaga o texto e devolve a lupa.
  final VoidCallback onClose;

  @override
  ConsumerState<EntriesSearchField> createState() => _EntriesSearchFieldState();
}

class _EntriesSearchFieldState extends ConsumerState<EntriesSearchField> {
  /// Começa com o que já estava buscado: a lista é preguiçosa, e o campo é
  /// refeito quando volta à vista depois de uma rolagem longa.
  late final TextEditingController _text = TextEditingController(
    text: ref.read(entriesViewModelProvider).text,
  );

  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Depois do primeiro quadro: antes dele, o campo ainda não está na
    // árvore de foco e o pedido se perde.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _text.text.isEmpty) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// O texto mudou por fora — o chip da busca, "Tirar os filtros": o campo
  /// mostra o que vale agora.
  void _follow(String? _, String text) {
    if (_text.text != text) _text.text = text;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(entriesViewModelProvider.select((f) => f.text), _follow);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CajuiTextField(
            label: 'Buscar',
            hint: 'Mercado, padaria, farmácia…',
            controller: _text,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onChanged: ref.read(entriesViewModelProvider.notifier).search,
          ),
        ),
        const SizedBox(width: CajuiSpacing.sm),
        CajuiIconButton(
          icon: CajuiIconData.close,
          semanticLabel: 'Fechar a busca',
          onPressed: widget.onClose,
        ),
      ],
    );
  }
}
