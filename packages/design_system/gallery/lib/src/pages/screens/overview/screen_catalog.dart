import 'package:gallery/src/pages/screens/assistant/assistant_page.dart';
import 'package:gallery/src/pages/screens/capture/capture_page.dart';
import 'package:gallery/src/pages/screens/closing/closing_page.dart';
import 'package:gallery/src/pages/screens/debts/debts_page.dart';
import 'package:gallery/src/pages/screens/home/home_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/shared/variant_slug.dart';
import 'package:gallery/src/pages/screens/statement/statement_page.dart';
import 'package:gallery/src/pages/screens/widget/home_widget_page.dart';

/// Uma tela do app na vitrine de estados.
///
/// O `id` é o nome do destino do menu que abre a tela grande — o texto, e
/// não o destino, para a vitrine não depender da casca que a monta.
typedef CatalogScreen = ({
  String id,
  String title,
  List<ScreenVariant> Function() variants,
});

/// As telas do app, na ordem do menu, com os estados que cada página já
/// mostra. A vitrine lê daqui, e não de uma cópia: um estado novo numa
/// página aparece na vitrine sem ninguém lembrar de acrescentá-lo.
abstract final class ScreenCatalog {
  /// Todas as telas, na ordem do menu.
  static const List<CatalogScreen> screens = [
    (id: 'home', title: HomePage.title, variants: HomePage.variants),
    (
      id: 'homeWidget',
      title: HomeWidgetPage.title,
      variants: HomeWidgetPage.variants,
    ),
    (id: 'capture', title: CapturePage.title, variants: CapturePage.variants),
    (
      id: 'statement',
      title: StatementPage.title,
      variants: StatementPage.variants,
    ),
    (id: 'closing', title: ClosingPage.title, variants: ClosingPage.variants),
    (id: 'debts', title: DebtsPage.title, variants: DebtsPage.variants),
    (
      id: 'assistant',
      title: AssistantPage.title,
      variants: AssistantPage.variants,
    ),
  ];

  /// Se a tela [id] tem o estado [state] (`sem-rede`). O endereço só guarda
  /// estado que existe: nome errado ou página sem estados viram o estado de
  /// sempre, e o endereço é corrigido em vez de propagar o erro.
  static bool hasState(String id, String state) {
    for (final screen in screens) {
      if (screen.id == id) {
        return variantIndexOf(screen.variants(), state) != null;
      }
    }
    return false;
  }
}
