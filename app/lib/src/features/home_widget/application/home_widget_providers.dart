import 'package:cajui/src/features/home_widget/application/home_screen.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot_publisher.dart';
import 'package:cajui/src/features/home_widget/application/widget_placement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tela inicial do celular. A raiz do app liga ao canal nativo no
/// Android; sem ligação, o retrato não vai a lugar nenhum.
final homeScreenProvider = Provider<HomeScreen>((ref) => const _Nowhere());

/// Quem leva o retrato até lá. Um por app: é ele que lembra o último.
final homeSnapshotPublisherProvider = Provider<HomeSnapshotPublisher>(
  (ref) => HomeSnapshotPublisher(ref.watch(homeScreenProvider)),
);

final class _Nowhere implements HomeScreen {
  const new();

  @override
  Future<void> publish(HomeSnapshot snapshot) async {}

  @override
  Future<WidgetPlacement> placement() async => WidgetPlacement.unavailable;

  @override
  Future<void> pin() async {}
}
