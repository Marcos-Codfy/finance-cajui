import 'package:cajui/src/features/ledger/presentation/entries_filter_chips.dart';
import 'package:cajui/src/features/ledger/presentation/entries_search_field.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:cajui/src/features/ledger/presentation/entries_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A busca e os filtros da lista. A busca fica atrás da lupa: o campo
/// aberto o tempo todo empurrava a lista para baixo, e a lista é o assunto
/// da tela (27/11/2026).
///
/// Aberta ou fechada é estado **desta** barra, e não do texto: se fosse
/// "aberta enquanto houver texto", apagar a última letra trocaria o campo
/// pela lupa no meio da digitação, e o foco ia junto (BL-127).
class EntriesFiltersBar extends ConsumerStatefulWidget {
  /// Cria a barra dos filtros de [state].
  const new({required this.state, super.key});

  /// A tela pronta, com o filtro em vigor.
  final EntriesReady state;

  @override
  ConsumerState<EntriesFiltersBar> createState() => _EntriesFiltersBarState();
}

class _EntriesFiltersBarState extends ConsumerState<EntriesFiltersBar> {
  /// Volta aberta se já havia busca: a lista é preguiçosa, e a barra é
  /// refeita quando volta à vista depois de uma rolagem longa.
  late bool _open = widget.state.filter.text.isNotEmpty;

  void _close() {
    ref.read(entriesViewModelProvider.notifier).search('');
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final chips = EntriesFilterChips(state: widget.state);
    if (_open) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntriesSearchField(onClose: _close),
          const SizedBox(height: CajuiSpacing.md),
          chips,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CajuiIconButton(
          icon: CajuiIconData.search,
          caption: 'Buscar',
          semanticLabel: 'Buscar nos lançamentos',
          variant: CajuiButtonVariant.secondary,
          onPressed: () => setState(() => _open = true),
        ),
        const SizedBox(width: CajuiSpacing.md),
        Expanded(child: chips),
      ],
    );
  }
}
