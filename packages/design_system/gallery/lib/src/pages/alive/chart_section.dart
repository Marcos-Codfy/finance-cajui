import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// Mês a mês: seis meses fictícios, com sobra e com falta.
class ChartSection extends StatefulWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  State<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<ChartSection> {
  /// Seis meses de uma casa fictícia: dois em que faltou, quatro em que
  /// sobrou. Nenhum valor é de gente de verdade.
  static const _months = [
    CajuiChartBar(label: 'mai', title: 'Maio', cents: 18400, note: 'Sobrou'),
    CajuiChartBar(label: 'jun', title: 'Junho', cents: -9650, note: 'Faltou'),
    CajuiChartBar(label: 'jul', title: 'Julho', cents: 4200, note: 'Sobrou'),
    CajuiChartBar(label: 'ago', title: 'Agosto', cents: -2375, note: 'Faltou'),
    CajuiChartBar(
      label: 'set',
      title: 'Setembro',
      cents: 22110,
      note: 'Sobrou',
    ),
    CajuiChartBar(label: 'out', title: 'Outubro', cents: 31200, note: 'Sobrou'),
  ];

  int _run = 0;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Mês a mês',
      description:
          'As barras crescem com mola a partir da linha do zero: para cima o '
          'que sobrou, para baixo o que faltou — no tom neutro, nunca em '
          'vermelho. Um toque escolhe o mês, e o valor rola até o dele. Cada '
          'barra é um botão com o mês e o valor por extenso.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CajuiCard(child: _chart()),
            const SizedBox(height: CajuiSpacing.md),
            CajuiButton(
              label: 'Crescer de novo',
              size: CajuiButtonSize.compact,
              variant: CajuiButtonVariant.secondary,
              onPressed: () => setState(() => _run++),
            ),
          ],
        ),
      ),
    );
  }

  /// A chave nova a cada "crescer de novo" remonta o gráfico, e ele cresce
  /// outra vez desde a linha do zero.
  Widget _chart() => CajuiBarChart(
    key: ValueKey(_run),
    bars: _months,
    semanticLabel: 'Mês a mês: o que sobrou ou faltou',
  );
}
