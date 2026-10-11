import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/plan_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O salário de uma pessoa da casa: quem, quanto e em que dia cai (regra 4
/// da planilha). O recebido, quando registrado, substitui o esperado no mês.
class SalaryPage extends ConsumerStatefulWidget {
  /// Cria a tela do salário [salary]; `null` cria um novo.
  const new({this.salary, super.key});

  /// O salário que está sendo mudado, ou `null`.
  final IncomeSource? salary;

  /// Abre a tela.
  static Future<void> open(BuildContext context, {IncomeSource? salary}) =>
      Navigator.of(
        context,
      ).push<void>(CajuiPageRoute(builder: (_) => SalaryPage(salary: salary)));

  @override
  ConsumerState<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends ConsumerState<SalaryPage> {
  late final _name = TextEditingController(text: widget.salary?.name);
  late final _day = TextEditingController(
    text: '${widget.salary?.expectedDay ?? 5}',
  );
  late int _cents = widget.salary?.expectedAmount.cents ?? 0;

  @override
  void dispose() {
    _name.dispose();
    _day.dispose();
    super.dispose();
  }

  int? get _payDay {
    final day = int.tryParse(_day.text);
    return day == null || day < 1 || day > 31 ? null : day;
  }

  Future<void> _save(BudgetPlan plan, int payDay) async {
    final salary = IncomeSource(
      // A primeira renda guarda o identificador do plano antigo, para o
      // salário já registrado como recebido continuar valendo (RN-131).
      id:
          widget.salary?.id ??
          (plan.salaries.isEmpty
              ? BudgetPlan.firstSalaryId
              : ref.read(newIdProvider)()),
      name: _name.text.trim(),
      tender: Tender.cash,
      expectedAmount: Money.fromCents(_cents),
      expectedDay: payDay,
    );
    final navigator = Navigator.of(context);
    await ref.read(planServiceProvider).define(plan.withSalary(salary));
    navigator.pop();
  }

  Future<void> _remove(BudgetPlan plan, String id) async {
    final navigator = Navigator.of(context);
    await ref.read(planServiceProvider).define(plan.withoutSalary(id));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(financesProvider)?.plan ?? BudgetPlan.empty;
    return CajuiScreen(
      title: widget.salary?.name ?? 'Novo salário',
      onBack: Navigator.of(context).pop,
      footer: _footer(plan),
      children: _fields(),
    );
  }

  List<Widget> _fields() => [
    CajuiTextField(
      label: 'De quem',
      controller: _name,
      hint: 'Meu salário, salário da esposa',
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: CajuiSpacing.lg),
    CajuiAmountField(
      label: 'Quanto entra por mês',
      initialCents: _cents,
      helper: 'Só o que é certo receber',
      onChanged: (cents) => setState(() => _cents = cents),
    ),
    const SizedBox(height: CajuiSpacing.lg),
    CajuiTextField(
      label: 'Dia em que cai',
      controller: _day,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      error: _payDay == null ? 'Um dia de 1 a 31' : null,
      onChanged: (_) => setState(() {}),
    ),
  ];

  Widget _footer(BudgetPlan plan) {
    final salary = widget.salary;
    final day = _payDay;
    final canSave = _name.text.trim().isNotEmpty && day != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiButton(
          label: 'Salvar',
          expand: true,
          onPressed: canSave ? () => _save(plan, day) : null,
        ),
        if (salary != null)
          CajuiButton(
            label: 'Tirar este salário',
            variant: CajuiButtonVariant.ghost,
            expand: true,
            onPressed: () => _remove(plan, salary.id),
          ),
      ],
    );
  }
}
