import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma tela para escolher um item de uma lista: categoria, forma de
/// pagamento, dia.
///
/// É tela cheia, e não menu suspenso: em celular, lista comprida dentro de
/// um balão é difícil de rolar e de ler com fonte ampliada. Fecha devolvendo
/// o item escolhido; voltar sem escolher devolve `null`.
class OptionPickerPage<T> extends StatelessWidget {
  /// Cria a tela [title] com as opções [options].
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

  /// Abre a tela e espera a escolha.
  static Future<T?> open<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T option) labelOf,
    T? selected,
  }) {
    return Navigator.of(context).push<T>(
      CajuiPageRoute(
        builder: (_) => OptionPickerPage<T>(
          title: title,
          options: options,
          labelOf: labelOf,
          selected: selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return CajuiScreen(
      title: title,
      onBack: navigator.pop,
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
