import 'package:cajui/src/features/auth/presentation/enroll_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A consulta pela web sem mês para mostrar (ADR-013).
///
/// São dois vazios diferentes. Antes de entrar, o caminho é o código do
/// celular. Depois de entrar, o servidor é que ainda não tem o mês — o
/// celular não enviou —, e "Atualizar" relê o que ele tem **sem perder a
/// sessão**, que vive só nesta aba. "Recarregue a página", que era o
/// conselho de antes, a perdia.
class WebEmptyState extends ConsumerWidget {
  /// Cria o vazio da consulta; [entered] diz se a pessoa já entrou.
  const new({required this.entered, super.key});

  /// Se a sessão de consulta já está aberta.
  final bool entered;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CajuiEmptyState(
    illustration: const CajuiHeroFruit(),
    title: entered
        ? 'O servidor ainda não tem nada deste mês'
        : 'Nada deste mês por aqui ainda',
    message: entered
        ? 'No celular, toque em Ajustes, Enviar ao servidor. Depois, '
              'atualize aqui.'
        : 'Esta é a consulta: o plano e os lançamentos ficam no celular '
              'e chegam aqui pelo servidor. Entre com o código que o '
              'celular mostra em Ajustes, Aparelhos com acesso, Abrir no '
              'computador.',
    action: CajuiNoticeAction(
      label: entered ? 'Atualizar' : 'Entrar com o código',
      onPressed: () =>
          entered ? ref.invalidate(ledgerProvider) : EnrollPage.open(context),
    ),
  );
}
