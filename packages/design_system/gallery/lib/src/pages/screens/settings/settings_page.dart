import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/settings/help_texts.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// Os Ajustes e a ajuda "Como o Cajui conta", em todos os estados.
class SettingsPage extends StatelessWidget {
  /// Cria a página dos ajustes, aberta no estado [initialIndex].
  const new({this.initialIndex = 0, super.key});

  /// O estado aberto ao entrar.
  final int initialIndex;

  /// O nome da tela, o mesmo do menu e o do alto da tela no app.
  static const title = 'Ajustes';

  /// O papel da tela no app.
  static const lead =
      'O que se cadastra uma vez e se revisita de vez em quando, e a ajuda: '
      '"Como o Cajui conta" explica cada número do app em poucas linhas, '
      'com exemplo inventado. Cada assunto abre sozinho.';

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
    ScreenVariant(
      label: 'No celular',
      note:
          'A ajuda vem primeiro. A chave de API aparece só no celular, que '
          'é de onde se lança.',
      builder: (context) =>
          MockScreen(title: title, children: _rows(phone: true)),
    ),
    ScreenVariant(
      label: 'Na consulta pela web',
      note:
          'A web só lê: no lugar da chave, o "Sair", que esquece a entrada '
          'deste navegador.',
      builder: (context) =>
          MockScreen(title: title, children: _rows(phone: false)),
    ),
    ScreenVariant(
      label: 'Como o Cajui conta',
      note:
          'A ajuda (heurística de ajuda e documentação de Nielsen). O vale '
          'aberto mostra como cada assunto se lê.',
      builder: (context) => MockScreen(
        title: 'Como o Cajui conta',
        children: HelpTexts.screen(context, open: 'Vale alimentação'),
      ),
    ),
  ];

  static List<Widget> _rows({required bool phone}) => [
    _opens(
      'Como o Cajui conta',
      'O que é cada número: renda, gastos, vale e cartão',
    ),
    _access(phone: phone),
    ..._registrations,
    _toggle('Tema escuro', 'O app abre no claro; o escuro fica se você ligar'),
    _toggle('Sons', 'Toques suaves ao tocar, salvar e confirmar', on: true),
    _toggle('Vibração', 'Um toque leve junto de cada ação', on: true),
  ];

  /// A chave de API no celular; na web, que só lê, o "Sair".
  static Widget _access({required bool phone}) => phone
      ? _opens(
          'Chave de API',
          'Para entrar na consulta pela web de outro computador',
        )
      : CajuiListRow(
          title: 'Sair',
          subtitle:
              'Este navegador esquece a entrada; para voltar, o código do '
              'autenticador',
          semanticLabel: 'Sair deste navegador',
          onPressed: () {},
        );

  /// O que se cadastra uma vez e se revisita de vez em quando.
  static List<Widget> get _registrations => [
    _opens(
      'Lançar pelas notificações do banco',
      'Compra e Pix avisados pelo banco entram sozinhos',
    ),
    _opens(
      'Nomes da casa',
      'Para Pix entre contas da casa não contar como gasto',
    ),
    _toggle(
      'Lembrar das contas a vencer',
      'Dois dias antes e no dia, às 9h: contas, parcelas e faturas em aberto',
      on: true,
    ),
    _opens(
      'Widget na tela inicial',
      'A sobra do mês na tela do celular, sem abrir o app.',
    ),
  ];

  static Widget _opens(String title, String subtitle) => CajuiListRow(
    title: title,
    subtitle: subtitle,
    trailing: const CajuiIcon(CajuiIconData.chevronRight),
    semanticLabel: '$title, abrir',
    onPressed: () {},
  );

  static Widget _toggle(String title, String subtitle, {bool on = false}) =>
      CajuiListRow(
        title: title,
        subtitle: subtitle,
        trailing: CajuiSwitch(
          value: on,
          onChanged: (_) {},
          semanticLabel: title,
        ),
      );
}
