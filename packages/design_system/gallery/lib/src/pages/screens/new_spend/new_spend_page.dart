import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/new_spend/new_spend_parts.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// O "Novo gasto", em todos os estados da matriz de telas.
///
/// Os gastos de sempre do exemplo são inventados, como os valores.
class NewSpendPage extends StatelessWidget {
  /// Cria a página do novo gasto, aberta no estado [initialIndex].
  const new({this.initialIndex = 0, super.key});

  /// O estado aberto ao entrar.
  final int initialIndex;

  /// O nome da tela, o mesmo do menu e o do alto da tela no app.
  static const title = 'Novo gasto';

  /// O papel da tela no app.
  static const lead =
      'Lançar à mão pede só o valor. Os gastos que se repetem aparecem no '
      'alto e preenchem tudo com um toque; o botão diz o que falta, em vez '
      'de ficar cinza e mudo; e um valor muito acima do normal pergunta '
      'antes de gravar.';

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: title,
      lead: lead,
      variants: variants(),
      initialIndex: initialIndex,
    );
  }

  /// Os estados, na ordem do seletor.
  static List<ScreenVariant> variants() => [
    _blank(),
    _filled(),
    _unusual(),
    _first(),
  ];

  static ScreenVariant _blank() => _variant(
    'Em branco',
    'Os gastos de sempre vêm do domínio (FrequentSpend): os repetidos dos '
        'últimos 60 dias, o mais frequente primeiro.',
    habits: true,
    cents: 0,
    footer: NewSpendParts.submit('Falta o valor', enabled: false),
  );

  static ScreenVariant _filled() => _variant(
    'Preenchido pelo gasto de sempre',
    'Um toque no chip preencheu valor, descrição, categoria e forma de '
        'pagamento da última vez. A data continua a de hoje.',
    habits: true,
    cents: 1250,
    description: 'Padaria Pão Quente',
    category: 'Padaria',
    footer: NewSpendParts.submit('Lançar'),
  );

  static ScreenVariant _unusual() => _variant(
    'Valor fora do comum',
    'Dez vezes a mediana da categoria (UnusualAmount): é o zero a mais. '
        'Não é recusa — compra grande existe —, é um "confere?".',
    cents: 150000,
    description: 'Mercado Boa Compra',
    category: 'Mercado',
    footer: NewSpendParts.confirm(
      amount: BrlFormatter.format(150000),
      typical: BrlFormatter.format(15000),
    ),
  );

  static ScreenVariant _first() => _variant(
    'Primeiro gasto',
    'Sem nada repetido, a sugestão é repetir o último lançamento; sem '
        'lançamento nenhum, a seção nem aparece.',
    repeatLast: true,
    cents: 0,
    footer: NewSpendParts.submit('Falta o valor', enabled: false),
  );

  static ScreenVariant _variant(
    String label,
    String note, {
    required int cents,
    required Widget footer,
    bool habits = false,
    bool repeatLast = false,
    String description = '',
    String? category,
  }) => ScreenVariant(
    label: label,
    note: note,
    builder: (context) => MockScreen(
      title: title,
      footer: footer,
      children: [
        if (habits) ...NewSpendParts.habits(context),
        if (repeatLast) ...NewSpendParts.repeatLast(context),
        ...NewSpendParts.fields(
          cents: cents,
          description: description,
          category: category,
        ),
      ],
    ),
  );
}
