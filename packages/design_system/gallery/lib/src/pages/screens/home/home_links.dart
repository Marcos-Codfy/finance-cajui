import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';

/// As portas do Início para o resto do app, as mesmas abas da planilha do
/// dono. Cada uma diz numa frase o que tem lá dentro — o número já à vista
/// poupa um toque.
///
/// Os textos são os do app; os números, os do mês de [HomeNumbers].
abstract final class HomeLinks {
  /// O que as dívidas somam: 16 parcelas de R$ 212,00 do empréstimo e 6 de
  /// R$ 150,00 da geladeira, as mesmas da tela de dívidas.
  static const int owed = 429200;

  static String _brl(int cents) => BrlFormatter.format(cents);

  /// As linhas da seção "Seu dinheiro". [outOfPocket] e [income] vão para a
  /// linha do Meu mês; [entries] é quantos lançamentos o mês tem; sem
  /// [voucher], a linha do vale some, como some no app para quem não tem.
  static List<Widget> of({
    int income = HomeNumbers.income,
    int outOfPocket = HomeNumbers.outOfPocket,
    int entries = 47,
    bool voucher = true,
    bool debts = true,
  }) => [
    const CajuiSectionTitle('Seu dinheiro'),
    _row(
      'Meu mês',
      'Entra ${_brl(income)} · sai do bolso ${_brl(outOfPocket)}',
    ),
    _row('Lançamentos', entries == 1 ? '1 este mês' : '$entries este mês'),
    _row('Minhas contas', 'O que entra, o que sai todo mês e o dízimo'),
    if (voucher)
      _row(
        'Vale',
        'Vale do mês ${_brl(HomeNumbers.voucher)} · conferir com a operadora',
      ),
    _row('Cartões', 'Quanto do limite já foi usado no mês'),
    _row(
      'Dívidas',
      debts ? 'Ainda devo ${_brl(owed)}' : 'Nenhuma dívida cadastrada',
    ),
    _row('Mês a mês', 'Quanto entrou, saiu e sobrou em cada mês'),
    _spreadsheet,
  ];

  /// A planilha não abre tela, vai direto para o compartilhar: por isso o
  /// ícone é o de compartilhar, e não a seta das outras portas (RN-1090).
  static Widget get _spreadsheet => _row(
    'Planilha do mês',
    'Leva outubro para o Excel ou o Planilhas Google',
    icon: CajuiIconData.share,
  );

  static Widget _row(
    String title,
    String subtitle, {
    CajuiIconData icon = CajuiIconData.chevronRight,
  }) => CajuiListRow(
    title: title,
    subtitle: subtitle,
    trailing: CajuiIcon(icon),
    semanticLabel: title,
    onPressed: () {},
  );
}
