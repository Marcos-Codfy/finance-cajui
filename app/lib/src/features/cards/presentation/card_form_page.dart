import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O cadastro de um cartão de crédito (RN-302): nome, dia de fechamento, dia
/// de vencimento e, se a pessoa quiser, o limite.
///
/// **Não há campo de número de cartão, e não vai haver.** O app calcula a
/// fatura pelas compras lançadas; o número não serve para nada disso.
class CardFormPage extends ConsumerStatefulWidget {
  /// Cria a tela de cadastro.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const CardFormPage()));
  }

  @override
  ConsumerState<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends ConsumerState<CardFormPage> {
  final _name = TextEditingController();
  int? _closingDay;
  int? _dueDay;
  int _limitCents = 0;
  String? _dayError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Os dias saem de uma lista de 1 a 31: dia que não existe não é
  /// oferecido. A regra continua no domínio (`E-CARD-01`), e é ele que
  /// responde se um dia errado chegar por outro caminho.
  Future<int?> _pickDay(String title, int? selected) {
    return OptionPickerPage.open<int>(
      context,
      title: title,
      options: [for (var day = 1; day <= 31; day++) day],
      labelOf: (day) => 'dia $day',
      selected: selected,
    );
  }

  /// Grava o cartão. A trava existe porque o identificador é sorteado a cada
  /// chamada: dois toques em "Guardar" antes de a tela fechar cadastravam
  /// **dois cartões iguais**, e o segundo `pop` ainda derrubava a tela de
  /// trás junto.
  Future<void> _save(int closingDay, int dueDay) async {
    if (_saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final result = await ref
        .read(ledgerProvider.notifier)
        .defineCard(
          name: _name.text,
          closingDay: closingDay,
          dueDay: dueDay,
          creditLimit: _limitCents > 0 ? Money.fromCents(_limitCents) : null,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        navigator.pop();
      case Err(:final failure):
        final error = FailurePresenter.present(failure);
        setState(() {
          _saving = false;
          _dayError = error.text.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final (closing, due) = (_closingDay, _dueDay);
    final ready =
        _name.text.trim().isNotEmpty && closing != null && due != null;
    return CajuiScreen(
      title: 'Novo cartão',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Guardar',
        expand: true,
        loading: _saving,
        onPressed: ready && !_saving ? () => _save(closing, due) : null,
      ),
      children: [
        CajuiTextField(
          label: 'Nome do cartão',
          hint: 'Como você chama: "Nubank", "Cartão da loja"',
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        ..._days(),
        const SizedBox(height: CajuiSpacing.lg),
        CajuiAmountField(
          label: 'Limite do cartão (opcional)',
          helper: 'Serve só para mostrar quanto do limite está tomado',
          onChanged: (cents) => _limitCents = cents,
        ),
      ],
    );
  }

  List<Widget> _days() {
    const gap = SizedBox(height: CajuiSpacing.lg);
    return [
      gap,
      CajuiSelectField(
        label: 'Fecha em',
        value: _closingDay == null ? null : 'dia $_closingDay',
        helper: 'Compra feita a partir deste dia entra na fatura seguinte',
        error: _dayError,
        onPressed: () async {
          final picked = await _pickDay('Dia do fechamento', _closingDay);
          if (picked != null) setState(() => _closingDay = picked);
        },
      ),
      gap,
      CajuiSelectField(
        label: 'Vence em',
        value: _dueDay == null ? null : 'dia $_dueDay',
        helper:
            'Se o cartão fecha no fim do mês, o vencimento é no mês seguinte',
        onPressed: () async {
          final picked = await _pickDay('Dia do vencimento', _dueDay);
          if (picked != null) setState(() => _dueDay = picked);
        },
      ),
    ];
  }
}
