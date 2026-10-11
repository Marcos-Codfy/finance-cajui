import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
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
  // Começa em "dinheiro extra": a tela abre pelo botão do extra, e o
  // salário é um toque. Começar num salário trocava o esperado dele pelo
  // extra, e o que entra no mês caía em vez de subir (RN-1006).
  String? _salaryId;
  bool _saving = false;

  List<IncomeSource> get _salaries =>
      ref.read(financesProvider)?.plan.salaries ?? const [];

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
          salaryId: _salaryId,
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
          today: ref.watch(todayProvider),
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

  /// Só em dinheiro: o salário de alguém troca o valor esperado pelo
  /// recebido neste mês (RN-131); a entrada avulsa — o extra do mês — conta
  /// só agora, e nunca é projetada para os meses seguintes (RN-133).
  List<Widget> _whichKind() => [
    Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final salary in _salaries)
          CajuiChip(
            label: 'Salário · ${salary.name}',
            selected: _salaryId == salary.id,
            onSelected: (_) => setState(() => _salaryId = salary.id),
          ),
        CajuiChip(
          label: 'Dinheiro extra',
          selected: _salaryId == null,
          onSelected: (_) => setState(() => _salaryId = null),
        ),
      ],
    ),
  ];
}
