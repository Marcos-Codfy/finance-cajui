import 'package:cajui/src/app/home_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qual aba está à vista.
///
/// Fica num provider, e não no estado de um widget, porque telas de dentro
/// também trocam de aba: o painel vazio leva a "Lançamentos", por exemplo.
class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.dashboard;

  /// Vai para [tab].
  // Método, e não setter: quem lê `select(HomeTab.entries)` numa tela entende
  // que a pessoa vai ser levada a outro lugar.
  // ignore: use_setters_to_change_properties
  void select(HomeTab tab) => state = tab;
}

/// A aba em vigor.
final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(
  HomeTabController.new,
);
