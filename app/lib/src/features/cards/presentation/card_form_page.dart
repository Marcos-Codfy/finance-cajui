import 'dart:async';

import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/cards/presentation/card_form_state.dart';
import 'package:cajui/src/features/cards/presentation/card_form_view_model.dart';
import 'package:cajui/src/features/ledger/presentation/ledger_coordinator.dart';
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

  @override
  ConsumerState<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends ConsumerState<CardFormPage> {
  final _name = TextEditingController();
  int? _closingDay;
  int? _dueDay;
  int _limitCents = 0;
  CajuiCardSkin _skin = CajuiCardSkin.cajui;

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
    return context
        .coordinator(ledgerCoordinatorProvider)
        .pick<int>(
          title: title,
          options: [for (var day = 1; day <= 31; day++) day],
          labelOf: (day) => 'dia $day',
          selected: selected,
        );
  }

  /// Entrega o que foi preenchido ao ViewModel, que grava.
  void _save(int closingDay, int dueDay) {
    unawaited(
      ref.read(cardFormProvider.notifier).save((
        id: widget.card?.id,
        name: _name.text,
        closingDay: closingDay,
        dueDay: dueDay,
        creditLimit: _limitCents > 0 ? Money.fromCents(_limitCents) : null,
        // O tom de sempre não se grava: o cartão viaja como antes.
        skin: _skin == CajuiCardSkin.cajui ? null : _skin.slug,
      )),
    );
  }

  void _closeWhenSaved(CardFormState? before, CardFormState now) {
    if (now is CardFormSaved) context.back();
  }

  Widget _footer({required bool saving}) {
    final (closing, due) = (_closingDay, _dueDay);
    final ready =
        _name.text.trim().isNotEmpty && closing != null && due != null;
    return CajuiButton(
      label: 'Guardar',
      expand: true,
      loading: saving,
      onPressed: ready && !saving ? () => _save(closing, due) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cardFormProvider, _closeWhenSaved);
    final form = ref.watch(cardFormProvider);
    return CajuiScreen(
      title: widget.card == null ? 'Novo cartão' : 'Alterar cartão',
      onBack: context.back,
      footer: _footer(saving: form is CardFormSaving),
      children: [
        CajuiTextField(
          label: 'Nome do cartão',
          hint: 'Como você chama: "Nubank", "Cartão da loja"',
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        ..._days(form is CardFormEditing ? form.dayProblem : null),
        const SizedBox(height: CajuiSpacing.lg),
        _limitField,
        const SizedBox(height: CajuiSpacing.lg),
        ..._skinField,
      ],
    );
  }

  Widget get _limitField => CajuiAmountField(
    label: 'Limite do cartão (opcional)',
    helper: 'Serve só para mostrar quanto do limite está tomado',
    initialCents: _limitCents,
    onChanged: (cents) => _limitCents = cents,
  );

  /// A cor do plástico, escolhida vendo: o cartão em 3D com o nome e os
  /// dias que já foram preenchidos, e as bolinhas dos tons do cerrado.
  List<Widget> get _skinField {
    final theme = CajuiTheme.of(context);
    final name = _name.text.trim();
    return [
      Text(
        'Cor do cartão',
        style: theme.typography.label.copyWith(color: theme.colors.text.muted),
      ),
      const SizedBox(height: CajuiSpacing.md),
      CajuiCreditCard3D(
        name: name.isEmpty ? 'Seu cartão' : name,
        detail: 'fecha dia ${_closingDay ?? '–'} · vence dia ${_dueDay ?? '–'}',
        usedCents: 0,
        limitCents: _limitCents > 0 ? _limitCents : 1,
        skin: _skin,
      ),
      const SizedBox(height: CajuiSpacing.lg),
      CajuiCardSkinPicker(
        selected: _skin,
        onChanged: (skin) => setState(() => _skin = skin),
      ),
    ];
  }

  List<Widget> _days(String? dayProblem) {
    const gap = SizedBox(height: CajuiSpacing.lg);
    return [
      gap,
      CajuiSelectField(
        label: 'Fecha em',
        value: _closingDay == null ? null : 'dia $_closingDay',
        helper: 'Compra feita a partir deste dia entra na fatura seguinte',
        error: dayProblem,
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
