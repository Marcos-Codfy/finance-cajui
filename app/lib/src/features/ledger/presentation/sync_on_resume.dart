import 'dart:async';

import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/sync_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manda o livro subir quando o app volta ao primeiro plano.
///
/// O que foi lançado sem rede — no subsolo do mercado, no ônibus — não sobe
/// na hora, e depois disso fica esperando o **próximo** lançamento para
/// pegar carona. Podia esperar dias.
///
/// Voltar ao app é o momento natural de tentar de novo, e não custa quase
/// nada: sem sessão aberta a subida silenciosa nem chega a falar com o
/// servidor, e com sessão aberta ela pergunta o que falta e manda só isso.
/// Nada disto aparece na tela.
class SyncOnResume extends ConsumerStatefulWidget {
  /// Envolve [child] com a tentativa de subida ao voltar.
  const new({required this.child, super.key});

  /// O que fica na tela; esta camada não desenha nada.
  final Widget child;

  @override
  ConsumerState<SyncOnResume> createState() => _SyncOnResumeState();
}

class _SyncOnResumeState extends ConsumerState<SyncOnResume> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_send()));
    // O arranque não é uma **volta**, e o ouvinte de ciclo de vida não
    // dispara nele: o app já nasce em primeiro plano. Sem esta linha, abrir
    // o app depois de um dia lançando offline não mandava nada.
    unawaited(_send());
  }

  Future<void> _send() async {
    // No arranque o livro ainda está abrindo quando o app resume. Esperar
    // por ele é o que faz a subida acontecer também na primeira abertura do
    // dia — que é justamente quando há mais coisa esperando.
    final book = await ref.read(ledgerProvider.future);
    if (!mounted) return;
    // Voltar ao app no dia seguinte é quando a liberação da chave pode ter
    // vencido: o aviso do painel confere de novo.
    ref.invalidate(quietSendProvider);
    ref.read(ledgerProvider.notifier).quietSync.schedule(book);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
