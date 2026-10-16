import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O cadastro de um cartão de crédito (RN-302): nome, dia de fechamento, dia
/// de vencimento e, se a pessoa quiser, o limite. Aberta com [card], é a
/// mesma tela para alterar um cartão que já existe — o limite muda com o
/// banco, e o dono pediu para poder acompanhar.
///
/// **Não há campo de número de cartão, e não vai haver.** O app calcula a
/// fatura pelas compras lançadas; o número não serve para nada disso.
class CardFormPage extends ConsumerStatefulWidget {
  /// Cria a tela de cadastro.
  const new({this.card, super.key});

  /// O cartão que está sendo alterado; nulo num cadastro novo.
  final CreditCard? card;

  /// Abre a tela; com [card], para alterá-lo.
  static Future<void> open(BuildContext context, {CreditCard? card}) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => CardFormPage(card: card)));
  }

  @override
  ConsumerState<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends ConsumerState<CardFormPage> {
  final _name = TextEditingController();
  int? _closingDay;
  int? _dueDay;
  int _limitCents = 0;
  CajuiCardSkin _skin = CajuiCardSkin.cajui;
  String? _dayError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    if (card == null) return;
    _name.text = card.name;
    _closingDay = card.closingDay;
    _dueDay = card.dueDay;
    _limitCents = card.creditLimit?.cents ?? 0;
    _skin = CajuiCardSkin.of(card.skin);
  }

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
          id: widget.card?.id,
          name: _name.text,
          closingDay: closingDay,
          dueDay: dueDay,
          creditLimit: _limitCents > 0 ? Money.fromCents(_limitCents) : null,
          // O tom de sempre não se grava: o cartão viaja como antes.
          skin: _skin == CajuiCardSkin.cajui ? null : _skin.slug,
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
      title: widget.card == null ? 'Novo cartão' : 'Alterar cartão',
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
        _limitField,
        const SizedBox(height: CajuiSpacing.lg),
        _skinField,
      ],
    );
  }

  Widget get _limitField => CajuiAmountField(
    label: 'Limite do cartão (opcional)',
    helper: 'Serve só para mostrar quanto do limite está tomado',
    initialCents: _limitCents,
    onChanged: (cents) => _limitCents = cents,
  );

  /// A cor do plástico, entre os tons do cerrado (pedido do dono).
  Widget get _skinField => CajuiSelectField(
    label: 'Cor do cartão',
    value: _skin.label,
    helper: 'Só a aparência do cartão em 3D, sem efeito nas contas',
    onPressed: () async {
      final picked = await OptionPickerPage.open<CajuiCardSkin>(
        context,
        title: 'Cor do cartão',
        options: CajuiCardSkin.values,
        labelOf: (skin) => skin.label,
        selected: _skin,
      );
      if (picked != null) setState(() => _skin = picked);
    },
  );

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
