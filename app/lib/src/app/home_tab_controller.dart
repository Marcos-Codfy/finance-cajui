import 'package:cajui/src/app/home_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qual aba está à vista.
///
/// Fica num provider, e não no estado de um widget, porque telas de dentro
/// também trocam de aba. O app abre na conversa: a Juju é a tela principal
/// (sugestão 3 do dono, 11/10/2026).
class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.conversar;

  /// Vai para [tab].
  // Método, e não setter: quem lê `select(HomeTab.inicio)` numa tela entende
  // que a pessoa vai ser levada a outro lugar.
  // ignore: use_setters_to_change_properties
  void select(HomeTab tab) => state = tab;
}

/// A aba em vigor.
final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(
  HomeTabController.new,
);
