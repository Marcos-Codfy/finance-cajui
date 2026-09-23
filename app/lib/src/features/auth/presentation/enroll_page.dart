import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cadastrar este aparelho no servidor (ADR-008).
///
/// O código vem do servidor e vale dez minutos, uma vez só. Ele não é senha:
/// é a prova de que quem está cadastrando tem acesso à máquina. Quem prova o
/// aparelho daqui em diante é a chave do Keystore, que nunca sai dele.
class EnrollPage extends ConsumerStatefulWidget {
  /// Cria a tela de cadastro.
  const new({super.key});

  /// Abre a tela. Devolve `true` quando o aparelho foi cadastrado.
  static Future<bool?> open(BuildContext context) {
    return Navigator.of(context)
        .push<bool>(CajuiPageRoute(builder: (_) => const EnrollPage()));
  }

  @override
  ConsumerState<EnrollPage> createState() => _EnrollPageState();
}

class _EnrollPageState extends ConsumerState<EnrollPage> {
  final _code = TextEditingController();
  final _name = TextEditingController(text: 'Celular');
  PresentedError? _problem;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  /// Nome vazio vira "Celular": a lista de aparelhos não pode ter uma linha
  /// sem nome, e escolher o nome é conveniência, não obrigação.
  String get _deviceName =>
      _name.text.trim().isEmpty ? 'Celular' : _name.text.trim();

  Future<void> _enroll() async {
    setState(() {
      _saving = true;
      _problem = null;
    });
    final navigator = Navigator.of(context);
    final feedback = CajuiFeedbackScope.of(context);
    final failure = await ref
        .read(deviceEnrollmentProvider)
        .enroll(_code.text, name: _deviceName);
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        // Sem preencher, a tela mostrava a chave crua: "{recurso} só
        // funciona com internet". Aqui o recurso é o cadastro.
        _problem = (
          code: failure,
          text: ErrorTexts.of(failure)
              .fill(const {'recurso': 'O cadastro do aparelho'}),
        );
      });
      return;
    }
    feedback.saved();
    navigator.pop(true);
  }

  static const _explanation =
      'No computador, peça um código ao servidor. Ele vale dez minutos e '
      'serve uma vez só.\n\nDepois disso este aparelho se identifica sozinho, '
      'por uma chave que fica guardada nele e nunca sai daqui.';

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Cadastrar este aparelho',
      onBack: Navigator.of(context).pop,
      footer: _footer(),
      children: [
        Text(
          _explanation,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        CajuiTextField(
          label: 'Código do servidor',
          controller: _code,
          hint: 'as dez letras e números',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: CajuiSpacing.lg),
        // O nome é o que a lista de aparelhos mostra depois. Antes vinha
        // fixo em "Celular", e dois aparelhos ficavam indistinguíveis na
        // hora de descadastrar um deles.
        CajuiTextField(
          label: 'Nome deste aparelho',
          controller: _name,
          hint: 'como ele aparece na lista',
        ),
      ],
    );
  }

  Widget _footer() {
    final problem = _problem;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null) ...[
          ErrorNotice(
            error: problem,
            onAction: (_) => setState(() => _problem = null),
          ),
          const SizedBox(height: CajuiSpacing.md),
        ],
        CajuiButton(
          label: 'Cadastrar',
          expand: true,
          loading: _saving,
          onPressed: _code.text.trim().length >= 6 ? _enroll : null,
        ),
      ],
    );
  }
}
