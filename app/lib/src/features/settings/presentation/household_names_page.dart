import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/settings/application/household_names_service.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os nomes de quem divide o orçamento, como aparecem no banco (RN-1070).
///
/// Pix e transferência entre estes nomes é dinheiro mudando de conta dentro
/// da casa: a notificação não lança como gasto, o recebimento não vira
/// renda, e a conferência do comprovante avisa (RN-1072 a RN-1074).
class HouseholdNamesPage extends ConsumerStatefulWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela, a partir de Ajustes.
  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push<void>(CajuiPageRoute(builder: (_) => const HouseholdNamesPage()));

  @override
  ConsumerState<HouseholdNamesPage> createState() => _HouseholdNamesPageState();
}

class _HouseholdNamesPageState extends ConsumerState<HouseholdNamesPage> {
  final _name = TextEditingController();

  HouseholdNamesService get _service => ref.read(householdNamesServiceProvider);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text;
    _name.clear();
    setState(() {});
    await _service.add(name);
  }

  /// O primeiro nome que o salário sugere vai para o campo, com o cursor
  /// no fim: falta o sobrenome, como o banco escreve.
  void _suggest(String name) {
    final text = '$name ';
    _name.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final names =
        ref.watch(ledgerProvider).value?.householdNames ?? HouseholdNames.empty;
    final salaries = ref.watch(financesProvider)?.plan.salaries ?? const [];
    final suggestions = names.suggestedBy(salaries.map((s) => s.name));
    return CajuiScreen(
      title: 'Nomes da casa',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Incluir',
        expand: true,
        onPressed: names.canAdd(_name.text) ? _add : null,
      ),
      children: [
        _intro(context),
        const SizedBox(height: CajuiSpacing.xl),
        for (final name in names.names) _row(name),
        if (names.names.isNotEmpty) const SizedBox(height: CajuiSpacing.lg),
        _field(names),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: CajuiSpacing.md),
          _suggestions(context, suggestions),
        ],
      ],
    );
  }

  Widget _intro(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'Pix e transferência entre estes nomes é dinheiro mudando de conta '
      'dentro da casa: não entra como gasto nem como renda.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  /// O leitor de tela ouve o nome e, logo depois, "Tirar": o botão fica na
  /// mesma linha do nome que ele tira.
  Widget _row(String name) => CajuiListRow(
    title: name,
    trailing: CajuiButton(
      label: 'Tirar',
      variant: CajuiButtonVariant.ghost,
      size: CajuiButtonSize.compact,
      onPressed: () => _service.remove(name),
    ),
  );

  /// Sem sobrenome, "Incluir" fica apagado, e o apoio diz por quê: só o
  /// primeiro nome casaria com qualquer pessoa de mesmo nome.
  Widget _field(HouseholdNames names) => CajuiTextField(
    label: 'Nome completo',
    controller: _name,
    hint: 'Como aparece no banco',
    helper: names.names.length < HouseholdNames.maxNames
        ? 'Nome e sobrenome. O banco abrevia e corta, e o Cajui entende.'
        : 'Cabem ${HouseholdNames.maxNames} nomes. Tire um para incluir outro.',
    maxLength: HouseholdNames.maxLength,
    textInputAction: TextInputAction.done,
    onChanged: (_) => setState(() {}),
    onSubmitted: (_) async {
      if (names.canAdd(_name.text)) await _add();
    },
  );

  Widget _suggestions(BuildContext context, List<String> names) {
    final theme = CajuiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dos salários do plano:',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Wrap(
          spacing: CajuiSpacing.sm,
          runSpacing: CajuiSpacing.sm,
          children: [
            for (final name in names)
              CajuiChip(
                label: name,
                selected: false,
                onSelected: (_) => _suggest(name),
              ),
          ],
        ),
      ],
    );
  }
}
