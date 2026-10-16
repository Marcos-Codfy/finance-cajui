import 'dart:async';

import 'package:cajui/src/features/home_widget/application/home_snapshot_provider.dart';
import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/home_widget/presentation/new_entry_shortcut.dart';
import 'package:cajui/src/features/home_widget/presentation/widget_arrival.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:cajui/src/features/reminders/application/due_reminders_provider.dart';
import 'package:cajui/src/features/reminders/application/reminders_providers.dart';
import 'package:cajui/src/features/reminders/presentation/reminder_pages.dart';
import 'package:cajui/src/features/review/presentation/review_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que liga o app aberto ao que acontece fora dele (ADR-025): a fila das
/// notificações do banco, o widget da tela inicial e as telas que um aviso
/// do Cajui pede para abrir.
///
/// Fica em volta da casca, abaixo do navegador: é dali que a revisão da
/// semana se abre por cima do que estiver na tela.
class NotificationsHost extends ConsumerStatefulWidget {
  /// Envolve [child].
  const new({required this.child, super.key});

  /// A casca do app.
  final Widget child;

  /// O pedido que abre a revisão da semana — o contrato com o lado nativo.
  static const reviewRoute = 'review';

  @override
  ConsumerState<NotificationsHost> createState() => _NotificationsHostState();
}

class _NotificationsHostState extends ConsumerState<NotificationsHost> {
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(
        ref
            .read(bankNoticeDeviceProvider)
            .arrivals
            .listen((_) => unawaited(_drain())),
      )
      ..add(ref.read(launchRequestsProvider).requests.listen(_open));
    // O retrato vai para o widget a cada mudança do livro — e já agora,
    // com o que o livro tem ao abrir.
    ref.listenManual(
      homeSnapshotProvider,
      (_, snapshot) =>
          unawaited(ref.read(homeSnapshotPublisherProvider).publish(snapshot)),
      fireImmediately: true,
    );
    _publishReminders();
    unawaited(_start());
  }

  /// Os lembretes de vencimento vão para o aparelho a cada mudança do livro,
  /// do dia ou da chave em Ajustes (RN-1081, RN-1088).
  void _publishReminders() => ref.listenManual(
    dueRemindersProvider,
    (_, reminders) =>
        unawaited(ref.read(remindersPublisherProvider).publish(reminders)),
    fireImmediately: true,
  );

  /// O que chegou com o app fechado — inclusive o que a leitura em segundo
  /// plano deixou pela metade — e a tela que o aviso tocado pediu.
  Future<void> _start() async {
    await _drain();
    final pending = await ref.read(launchRequestsProvider).takePending();
    if (pending != null) _open(pending);
  }

  Future<void> _drain() => ref.read(bankNoticeServiceProvider).drain();

  void _open(String route) {
    if (!mounted || ReminderPages.open(context, route)) return;
    if (WidgetArrival.open(ref, route)) return;
    if (NewEntryShortcut.open(context, route)) return;
    if (route != NotificationsHost.reviewRoute) return;
    unawaited(ReviewPage.open(context));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
