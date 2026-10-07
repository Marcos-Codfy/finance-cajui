import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A consulta pela web antes de o servidor ter o mês (ADR-013).
///
/// O celular manda tudo sozinho (ADR-020); se não chegou, foi agora. O
/// botão relê o que o servidor tem **sem perder a chave**, que fica no
/// navegador.
class WebEmptyState extends ConsumerWidget {
  /// Cria o vazio da consulta.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CajuiEmptyState(
    illustration: const CajuiHeroFruit(),
    title: 'Ainda não chegou nada deste mês',
    message:
        'O celular manda os lançamentos sozinho assim que você lança. Se '
        'acabou de lançar, atualize.',
    action: CajuiNoticeAction(
      label: 'Atualizar',
      onPressed: () => ref.invalidate(ledgerProvider),
    ),
  );
}
