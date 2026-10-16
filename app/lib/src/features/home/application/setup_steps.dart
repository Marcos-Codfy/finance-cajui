import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/home_widget/application/widget_placement.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que ainda falta configurar para o Cajui render tudo o que pode — o
/// cartão "Primeiros passos" do Início (16/10/2026). Antes, cada um morava
/// num canto dos Ajustes, e a lista de pendências do dono mostrava que eles
/// ficavam esquecidos.
enum SetupStep {
  /// Os nomes da casa, para o Pix entre vocês não contar como gasto.
  names,

  /// O acesso às notificações, para lançar pelo aviso do banco.
  notifications,

  /// O widget na tela inicial, quando o aparelho deixa pôr por pedido.
  widget,

  /// O limite de algum cartão, para ver quanto dele já foi usado.
  cardLimits,
}

/// Os passos que faltam, na ordem do cartão; vazio quando está tudo pronto.
final FutureProvider<List<SetupStep>> setupStepsProvider =
    FutureProvider.autoDispose<List<SetupStep>>((ref) async {
      final book = await ref.watch(ledgerProvider.future);
      final granted = await ref.read(notificationAccessProvider).isGranted();
      final placement = await ref.read(homeScreenProvider).placement();
      return [
        if (book.householdNames.names.isEmpty) SetupStep.names,
        if (!granted) SetupStep.notifications,
        if (placement == WidgetPlacement.absent) SetupStep.widget,
        if (book.cards.any((card) => card.creditLimit == null))
          SetupStep.cardLimits,
      ];
    });
