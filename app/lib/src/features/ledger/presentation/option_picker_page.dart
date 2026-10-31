import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Escolher um item de uma lista: categoria, forma de pagamento, dia.
///
/// Abre num painel que sobe de baixo (`CajuiSheet`), e não em menu
/// suspenso: lista comprida dentro de um balão é difícil de rolar e de ler
/// com fonte ampliada, e o painel rola com até quatro quintos da tela. Fecha
/// devolvendo o item escolhido; tocar fora, ou voltar, devolve `null`.
class OptionPickerPage<T> extends StatelessWidget {
  /// Cria a escolha [title] com as opções [options].
  const new({
    required this.title,
    required this.options,
    required this.labelOf,
    this.selected,
    super.key,
  });

  /// O que está sendo escolhido: "Categoria", "Por onde foi pago".
  final String title;

  /// As opções, na ordem em que aparecem.
  final List<T> options;

  /// O nome de cada opção.
  final String Function(T option) labelOf;

  /// A opção já escolhida, se houver.
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final navigator = context.navigator;
    return CajuiSheet(
      title: title,
      children: [
        CajuiOptionList<T>(
          options: options,
          labelOf: labelOf,
          selected: selected,
          onSelected: navigator.pop,
        ),
      ],
    );
  }
}
