import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mandar o livro para o servidor, quando a pessoa quiser.
///
/// Antes a subida só acontecia de carona numa pergunta ao assistente — e
/// quem lançava e nunca perguntava nada ficava com o servidor vazio, sem
/// saber por quê. A consulta pela web dependia disso e não dizia.
///
/// Continua não acontecendo a cada lançamento, de propósito: a subida abre
/// a sessão, e a sessão pede a digital. Uma vez por dia basta, e quem manda
/// é quem está com o celular na mão.
class SyncPage extends ConsumerStatefulWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const SyncPage()));

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  bool _sending = false;
  int? _sent;
  ErrorCode? _problem;

  Future<void> _send() async {
    final book = ref.read(ledgerProvider).value;
    if (book == null || _sending) return;
    setState(() {
      _sending = true;
      _problem = null;
      _sent = null;
    });
    final (enviados, erro) = await LedgerSync(ref.read(ledgerUplinkProvider))
        .run(book);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = enviados;
      _problem = erro;
    });
  }

  @override
  Widget build(BuildContext context) => CajuiScreen(
    title: 'Enviar ao servidor',
    onBack: Navigator.of(context).pop,
    footer: CajuiButton(
      label: 'Enviar agora',
      expand: true,
      loading: _sending,
      onPressed: _sending ? null : _send,
    ),
    children: [_explicacao(context), ..._resultado()],
  );

  Widget _explicacao(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'Os seus lançamentos ficam neste aparelho. O servidor recebe uma '
      'cópia para o assistente responder com os seus números e para você '
      'consultar do computador. Nada é apagado daqui, e o envio pede a sua '
      'digital uma vez por dia.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  List<Widget> _resultado() {
    final code = _problem;
    final enviados = _sent;
    return [
      const SizedBox(height: CajuiSpacing.xl),
      if (code != null)
        ErrorNotice(
          error: (code: code, text: AssistantReplyView.textOf(code)),
          onAction: (_) => setState(() => _problem = null),
        )
      else if (enviados != null)
        CajuiEmptyState(
          title: enviados == 0 ? 'Já estava tudo lá' : 'Enviado',
          message: enviados == 0
              ? 'O servidor já tinha todos os lançamentos deste aparelho.'
              : 'Foram $enviados lançamentos. O assistente e a consulta na '
                    'web já enxergam.',
        ),
    ];
  }
}
