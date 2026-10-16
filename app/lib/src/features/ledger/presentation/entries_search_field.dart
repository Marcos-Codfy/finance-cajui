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
class EntriesSearchField extends ConsumerStatefulWidget {
  /// Cria o campo de busca.
  const new({super.key});

  @override
  ConsumerState<EntriesSearchField> createState() => _EntriesSearchFieldState();
}

class _EntriesSearchFieldState extends ConsumerState<EntriesSearchField> {
  /// Começa com o que já estava buscado: a lista é preguiçosa, e o campo é
  /// refeito quando volta à vista depois de uma rolagem longa.
  late final TextEditingController _text = TextEditingController(
    text: ref.read(entriesViewModelProvider).text,
  );

  @override
  void dispose() {
    _text.dispose();
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
    return CajuiTextField(
      label: 'Buscar',
      hint: 'Mercado, padaria, farmácia…',
      controller: _text,
      textInputAction: TextInputAction.search,
      onChanged: ref.read(entriesViewModelProvider.notifier).search,
    );
  }
}
