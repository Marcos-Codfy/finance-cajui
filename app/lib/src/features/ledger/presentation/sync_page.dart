import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/sync_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sincronizar o livro com o servidor, quando a pessoa quiser: sobe o que
/// falta lá e traz o que outro aparelho fez (BL-062).
///
/// Depois do primeiro envio do dia, cada lançamento sobe sozinho — é o que
/// a `QuietSync` faz. Esta tela continua existindo porque **o primeiro** não
/// sobe: abrir a sessão pede a digital, e pedir a digital no meio de um
/// lançamento é pior do que esperar. Aqui é onde se dá esse primeiro passo,
/// de propósito e com a pessoa olhando.
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
  int _received = 0;
  ErrorCode? _problem;

  Future<void> _send() async {
    final book = ref.read(ledgerProvider).value;
    if (book == null || _sending) return;
    setState(() {
      _sending = true;
      _problem = null;
      _sent = null;
    });
    try {
      final outcome = await ref.read(ledgerSyncProvider).run(book);
      if (!mounted) return;
      setState(() {
        _sent = outcome.sent;
        _received = outcome.received;
        _problem = outcome.error;
      });
    } finally {
      // Aconteça o que acontecer, o botão volta: preso em "enviando" ele
      // não serve para tentar de novo.
      if (mounted) setState(() => _sending = false);
    }
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
      'consultar do computador. Nada é apagado daqui. O envio pede a sua '
      'digital uma vez por dia; depois dele, o que você lançar sobe sozinho '
      'até o dia acabar.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  /// O que subiu e o que desceu, cada um só quando houve.
  String _summary(int enviados) {
    final partes = [
      if (enviados > 0) 'Foram $enviados lançamentos para o servidor.',
      if (_received > 0) 'Chegaram $_received novidades do outro aparelho.',
    ];
    if (partes.isEmpty) {
      return 'Este aparelho e o servidor têm exatamente as mesmas coisas.';
    }
    return '${partes.join(' ')} O assistente e a consulta na web já enxergam.';
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
          title: enviados == 0 && _received == 0
              ? 'Já estava tudo em dia'
              : 'Sincronizado',
          message: _summary(enviados),
        ),
    ];
  }
}
