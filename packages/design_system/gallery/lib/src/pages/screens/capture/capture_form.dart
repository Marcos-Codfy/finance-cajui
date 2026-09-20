import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Os campos da confirmação de captura, já preenchidos pela leitura.
///
/// São campos de verdade, e não texto: nada é lançado sem conferência, e
/// tudo o que a leitura preencheu pode ser corrigido ali mesmo.
class CaptureForm extends StatefulWidget {
  /// Cria o formulário. Sem [category], a categoria fica para quem confere.
  const new({required this.confidence, this.category, super.key});

  /// O quanto a leitura confia na categoria.
  final CajuiConfidenceLevel confidence;

  /// A categoria proposta, quando a leitura chegou a uma.
  final String? category;

  @override
  State<CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends State<CaptureForm> {
  final _place = TextEditingController(text: 'Mercado Boa Compra');

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: CajuiSpacing.lg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiAmountField(
          label: 'Valor',
          initialCents: 18640,
          helper: 'Comprado em 12/09',
          onChanged: (_) {},
        ),
        gap,
        CajuiTextField(label: 'Onde foi', controller: _place),
        gap,
        CajuiSelectField(
          label: 'O que foi comprado',
          value: widget.category,
          placeholder: 'Escolher a categoria',
          onPressed: () {},
        ),
        const SizedBox(height: CajuiSpacing.sm),
        CajuiConfidenceIndicator(widget.confidence),
        gap,
        CajuiSelectField(
          label: 'Por onde pagou',
          value: 'Vale alimentação',
          helper: 'Saldo do vale depois: ${BrlFormatter.format(22620)}',
          onPressed: () {},
        ),
      ],
    );
  }
}
