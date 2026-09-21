import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// A faixa de um gasto variável: o mínimo que não dá para cortar e o máximo
/// que a pessoa aceita gastar.
///
/// Fecha devolvendo a faixa. O plano conta pelo **máximo** — o pior caso —,
/// e é por isso que a sobra do Cajui é uma sobra em que dá para confiar.
class VariableBudgetPage extends StatefulWidget {
  /// Cria a tela. Com [existing], edita a faixa; sem, cria uma entre as
  /// [categories] que ainda não têm.
  const new({required this.categories, this.existing, super.key});

  /// As categorias variáveis que podem receber a faixa.
  final List<Category> categories;

  /// A faixa em edição.
  final VariableBudget? existing;

  /// Abre a tela e espera a faixa.
  static Future<VariableBudget?> open(
    BuildContext context, {
    required List<Category> categories,
    VariableBudget? existing,
  }) {
    return Navigator.of(context).push<VariableBudget>(
      CajuiPageRoute(
        builder: (_) =>
            VariableBudgetPage(categories: categories, existing: existing),
      ),
    );
  }

  @override
  State<VariableBudgetPage> createState() => _VariableBudgetPageState();
}

class _VariableBudgetPageState extends State<VariableBudgetPage> {
  late Category? _category = _existingCategory();
  late int _minCents = widget.existing?.range.min.cents ?? 0;
  late int _maxCents = widget.existing?.range.max.cents ?? 0;
  String? _rangeError;

  Category? _existingCategory() {
    final id = widget.existing?.categoryId;
    for (final category in widget.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<void> _pickCategory() async {
    final picked = await OptionPickerPage.open<Category>(
      context,
      title: 'Categoria',
      options: widget.categories,
      labelOf: (category) => category.name,
      selected: _category,
    );
    if (picked != null) setState(() => _category = picked);
  }

  /// A regra é do domínio (RN-420): mínimo acima do máximo é recusado, e a
  /// tela só mostra o que ele respondeu, sob o campo.
  void _save(Category category) {
    final range = AmountRange.create(
      min: Money.fromCents(_minCents),
      max: Money.fromCents(_maxCents),
    );
    switch (range) {
      case Err(:final failure):
        final error = FailurePresenter.present(failure);
        setState(() => _rangeError = error.text.message);
      case Ok(:final value):
        Navigator.of(context).pop(
          VariableBudget(
            categoryId: category.id,
            range: value,
            voucherEligible: category.voucherEligible,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    return CajuiScreen(
      title: 'Gasto variável',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Guardar',
        expand: true,
        onPressed: category == null ? null : () => _save(category),
      ),
      children: [
        CajuiSelectField(
          label: 'Categoria',
          value: category?.name,
          helper: (category?.voucherEligible ?? false)
              ? 'O vale entra primeiro nesta categoria'
              : null,
          onPressed: widget.existing == null ? _pickCategory : null,
        ),
        ..._range(),
      ],
    );
  }

  /// O mínimo e o máximo. O erro da faixa fica sob o máximo, que é o campo
  /// que a pessoa costuma corrigir.
  List<Widget> _range() {
    const gap = SizedBox(height: CajuiSpacing.lg);
    return [
      gap,
      CajuiAmountField(
        label: 'Mínimo do mês',
        helper: 'O que não dá para cortar',
        initialCents: _minCents,
        onChanged: (cents) => _minCents = cents,
      ),
      gap,
      CajuiAmountField(
        label: 'Máximo do mês',
        helper: 'O plano conta por este valor: o pior caso',
        initialCents: _maxCents,
        error: _rangeError,
        onChanged: (cents) => _maxCents = cents,
      ),
    ];
  }
}
