import 'package:design_system/design_system.dart';

/// As duas áreas do app (sugestão 5 do dono, 11/10/2026): a conversa com a
/// Juju, que é a tela principal, e o Painel, com o mês e as portas para o
/// resto. Lançamentos, cartões, dívidas e ajustes abrem a partir do Painel.
enum HomeTab {
  /// A conversa: lançar, perguntar, mandar foto ou extrato.
  conversar(CajuiIconData.chat, 'Conversar'),

  /// O mês da planilha e as portas para o resto.
  inicio(CajuiIconData.wallet, 'Painel');

  new(this.icon, this.label);

  /// O ícone na barra.
  final CajuiIconData icon;

  /// O nome na barra.
  final String label;

  /// O destino da barra de navegação.
  CajuiNavDestination get destination =>
      CajuiNavDestination(icon: icon, label: label);
}
