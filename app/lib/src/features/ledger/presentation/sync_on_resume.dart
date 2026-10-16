import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/live_sync.dart';
import 'package:cajui/src/features/ledger/application/server_head.dart';
import 'package:cajui/src/features/ledger/application/sync_now.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mantém o livro em dia com o servidor enquanto o app está na frente.
///
/// Três momentos. **Ao abrir e ao voltar ao app**, o celular sobe o que
/// foi lançado sem rede — no subsolo do mercado, no ônibus — e traz o que
/// o outro fez. **Enquanto está na frente**, pergunta a cada 20 segundos
/// se o servidor mudou, e só desce o livro quando mudou (ADR-024). **No
/// fundo**, para de perguntar.
///
/// Na web, que só consulta, não há o que subir: quando o servidor muda,
/// o livro é relido no lugar. Nada disto aparece na tela.
class SyncOnResume extends ConsumerStatefulWidget {
  /// Envolve [child] com a sincronização ao vivo.
  const new({required this.child, super.key});

  /// O que fica na tela; esta camada não desenha nada.
  final Widget child;

  @override
  ConsumerState<SyncOnResume> createState() => _SyncOnResumeState();
}

class _SyncOnResumeState extends ConsumerState<SyncOnResume> {
  AppLifecycleListener? _lifecycle;
  late final LiveSync _live = LiveSync(
    head: ref.read(serverHeadProvider),
    refresh: _refresh,
  );

  /// O celular tem livro próprio para subir; a web, não.
  bool get _onPhone => ref.read(ledgerUplinkProvider).isPaired;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _resume, onHide: _live.pause);
    // O arranque não é uma **volta**, e o ouvinte de ciclo de vida não
    // dispara nele: o app já nasce em primeiro plano. Sem esta linha, abrir
    // o app depois de um dia lançando offline não mandava nada.
    _resume();
  }

  void _resume() {
    // A volta ao app confere o dia na hora: quem deixou o app no dia 30 e
    // volta no dia 1 vê o mês novo, sem esperar o minuto seguinte.
    ref.read(todayProvider.notifier).check();
    _live.resume(force: _onPhone);
  }

  /// No celular, a sincronização de sempre, na mesma fila da que acontece
  /// depois de cada lançamento. Na web, o livro relido no lugar.
  Future<bool> _refresh() async {
    final done = await ref.read(syncNowProvider)();
    return mounted && done;
  }

  @override
  void dispose() {
    _live.pause();
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
