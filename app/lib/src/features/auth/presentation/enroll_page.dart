import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cadastrar este aparelho no servidor (ADR-008) — ou, na web, entrar com o
/// código que o celular mostrou (ADR-013).
///
/// No celular, o código vem do servidor e vale dez minutos, uma vez só. Ele
/// não é senha: é a prova de que quem está cadastrando tem acesso à máquina.
/// Quem prova o aparelho daqui em diante é a chave do Keystore, que nunca
/// sai dele.
///
/// Na web não nasce aparelho nenhum: o código vem do **celular**, vale dois
/// minutos, e abre uma leitura que dura enquanto a aba viver. A tela é a
/// mesma de propósito — só o que ela diz muda, porque dizer "peça um código
/// ao servidor" a quem precisa pegá-lo no celular mandava a pessoa pelo
/// caminho errado.
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

  /// Se esta é a consulta pela web: sem identidade de aparelho.
  bool get _consulta => !ref.read(ledgerUplinkProvider).isPaired;

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
    if (failure != null) return _refused(failure);
    // Na web o livro é o que o servidor tem, e foi lido antes de haver
    // sessão — vazio. Sem reler, a página continuava em "nada por aqui"
    // depois de entrar, e recarregar a página perdia a sessão.
    if (_consulta) ref.invalidate(ledgerProvider);
    feedback.saved();
    navigator.pop(true);
  }

  /// Sem preencher, a tela mostrava a chave crua: "{recurso} só funciona
  /// com internet". Aqui o recurso é o cadastro — ou a consulta.
  void _refused(ErrorCode failure) => setState(() {
    _saving = false;
    _problem = (
      code: failure,
      text: ErrorTexts.of(
        failure,
      ).fill({'recurso': _consulta ? 'A consulta' : 'O cadastro do aparelho'}),
    );
  });

  static const _deviceExplanation =
      'No computador, peça um código ao servidor. Ele vale dez minutos e '
      'serve uma vez só.\n\nDepois disso este aparelho se identifica sozinho, '
      'por uma chave que fica guardada nele e nunca sai daqui.';

  static const _webExplanation =
      'No celular: Ajustes, Aparelhos com acesso, Abrir no computador. O '
      'código vale dois minutos e serve uma vez só.\n\nA consulta dura '
      'enquanto esta aba ficar aberta: fechar a aba é sair.';

  @override
  Widget build(BuildContext context) {
    final consulta = _consulta;
    return CajuiScreen(
      title: consulta
          ? 'Entrar com o código do celular'
          : 'Cadastrar este aparelho',
      onBack: Navigator.of(context).pop,
      footer: _footer(consulta),
      children: _fields(CajuiTheme.of(context), consulta),
    );
  }

  List<Widget> _fields(CajuiThemeData theme, bool consulta) => [
    Text(
      consulta ? _webExplanation : _deviceExplanation,
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    ),
    const SizedBox(height: CajuiSpacing.xl),
    CajuiTextField(
      label: consulta ? 'Código do celular' : 'Código do servidor',
      controller: _code,
      hint: consulta ? 'as oito letras e números' : 'as dez letras e números',
      onChanged: (_) => setState(() {}),
    ),
    // O nome é o que a lista de aparelhos mostra depois. Antes vinha fixo
    // em "Celular", e dois aparelhos ficavam indistinguíveis na hora de
    // descadastrar um deles. A web não entra na lista: não tem nome.
    if (!consulta) ...[
      const SizedBox(height: CajuiSpacing.lg),
      CajuiTextField(
        label: 'Nome deste aparelho',
        controller: _name,
        hint: 'como ele aparece na lista',
      ),
    ],
  ];

  Widget _footer(bool consulta) {
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
          label: consulta ? 'Entrar' : 'Cadastrar',
          expand: true,
          loading: _saving,
          onPressed: _code.text.trim().length >= 6 ? _enroll : null,
        ),
      ],
    );
  }
}
