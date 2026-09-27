import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/presentation/date_section.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registrar uma renda recebida: o salário, o crédito do vale, uma entrada
/// avulsa.
///
/// Recebimento **não é lançamento** (RN-132): não tem categoria e nunca se
/// compensa com um gasto. E as duas moedas ficam separadas desde aqui — a
/// primeira escolha da tela é em qual delas o valor entrou (RN-111).
class IncomePage extends ConsumerStatefulWidget {
  /// Cria a tela. [tender] é a moeda que já vem marcada.
  const new({this.tender = Tender.cash, super.key});

  /// A moeda marcada ao abrir.
  final Tender tender;

  /// Abre a tela.
  static Future<void> open(
    BuildContext context, {
    Tender tender = Tender.cash,
  }) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => IncomePage(tender: tender)));
  }

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage> {
  late Tender _tender = widget.tender;
  late LocalDate _receivedOn = ref.read(clockProvider).today();
  int _cents = 0;
  bool _fromPlan = true;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final feedback = CajuiFeedbackScope.of(context);
    await ref
        .read(incomeServiceProvider)
        .receiveIncome(
          tender: _tender,
          amount: Money.fromCents(_cents),
          receivedOn: _receivedOn,
          fromPlan: _fromPlan,
        );
    feedback.saved();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: CajuiSpacing.lg);
    return CajuiScreen(
      title: 'Registrar recebimento',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Registrar',
        expand: true,
        loading: _saving,
        onPressed: _cents > 0 ? _save : null,
      ),
      children: [
        ..._whichTender(),
        gap,
        CajuiAmountField(
          label: 'Quanto entrou',
          onChanged: (cents) => setState(() => _cents = cents),
        ),
        if (_tender == Tender.cash) ...[gap, ..._whichKind()],
        gap,
        DateSection(
          selected: _receivedOn,
          today: ref.watch(clockProvider).today(),
          onChanged: (day) => setState(() => _receivedOn = day),
        ),
      ],
    );
  }

  List<Widget> _whichTender() => [
    Wrap(
      spacing: CajuiSpacing.sm,
      children: [
        CajuiChip(
          label: 'Em dinheiro',
          selected: _tender == Tender.cash,
          onSelected: (_) => setState(() => _tender = Tender.cash),
        ),
        CajuiChip(
          label: 'No vale alimentação',
          selected: _tender == Tender.mealVoucher,
          onSelected: (_) => setState(() => _tender = Tender.mealVoucher),
        ),
      ],
    ),
  ];

  /// Só em dinheiro: a renda do plano troca o valor esperado pelo recebido
  /// neste mês (RN-131); a entrada avulsa conta só agora, e nunca é projetada
  /// para os meses seguintes (RN-133).
  List<Widget> _whichKind() => [
    Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        CajuiChip(
          label: 'É a renda do mês',
          selected: _fromPlan,
          onSelected: (_) => setState(() => _fromPlan = true),
        ),
        CajuiChip(
          label: 'É uma entrada avulsa',
          selected: !_fromPlan,
          onSelected: (_) => setState(() => _fromPlan = false),
        ),
      ],
    ),
  ];
}
