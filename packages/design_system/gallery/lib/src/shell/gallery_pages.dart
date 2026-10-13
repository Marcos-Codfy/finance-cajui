import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/alive/alive_page.dart';
import 'package:gallery/src/pages/components/action_page.dart';
import 'package:gallery/src/pages/components/content_page.dart';
import 'package:gallery/src/pages/components/conversation_page.dart';
import 'package:gallery/src/pages/components/field_page.dart';
import 'package:gallery/src/pages/components/state_page.dart';
import 'package:gallery/src/pages/depth/camera_page.dart';
import 'package:gallery/src/pages/depth/cinematic_page.dart';
import 'package:gallery/src/pages/depth/cover_flow_page.dart';
import 'package:gallery/src/pages/depth/depth_scroll_page.dart';
import 'package:gallery/src/pages/depth/wallet_page.dart';
import 'package:gallery/src/pages/overview/overview_page.dart';
import 'package:gallery/src/pages/screens/assistant/assistant_page.dart';
import 'package:gallery/src/pages/screens/capture/capture_page.dart';
import 'package:gallery/src/pages/screens/closing/closing_page.dart';
import 'package:gallery/src/pages/screens/debts/debts_page.dart';
import 'package:gallery/src/pages/screens/home/home_page.dart';
import 'package:gallery/src/pages/screens/overview/screen_states_route.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/shared/variant_slug.dart';
import 'package:gallery/src/pages/screens/shortfall/shortfall_compare_page.dart';
import 'package:gallery/src/pages/screens/statement/statement_page.dart';
import 'package:gallery/src/pages/screens/widget/home_widget_page.dart';
import 'package:gallery/src/pages/senses/motion_desk_page.dart';
import 'package:gallery/src/pages/senses/sound_desk_page.dart';
import 'package:gallery/src/pages/tokens/colors_page.dart';
import 'package:gallery/src/pages/tokens/contrast_page.dart';
import 'package:gallery/src/pages/tokens/do_dont_page.dart';
import 'package:gallery/src/pages/tokens/icons_page.dart';
import 'package:gallery/src/pages/tokens/layout_page.dart';
import 'package:gallery/src/pages/tokens/typography_page.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// A página do destino [destination]; numa tela do app, aberta no estado
/// [state] do endereço (`sem-rede`), se ele existir nela.
Widget galleryPageOf(GalleryDestination destination, {String? state}) =>
    _pages[destination]!(state);

/// Se o destino tem página. Um teste passa por todos os destinos: destino
/// novo sem página reprova ali, antes de chegar ao navegador.
bool galleryHasPage(GalleryDestination destination) =>
    _pages.containsKey(destination);

/// O estado [state] entre os de [variants], pela posição.
int? _at(List<ScreenVariant> Function() variants, String? state) =>
    variantIndexOf(variants(), state);

/// Um mapa, e não um `switch`: com uma linha por página, a função passava
/// do limite de tamanho, e partir o `switch` em dois tirava a garantia de
/// que ele cobre tudo. Quem garante agora é o teste de [galleryHasPage].
final Map<GalleryDestination, Widget Function(String? state)> _pages = {
  GalleryDestination.overview: (_) => const OverviewPage(),
  GalleryDestination.screenStates: (_) => const ScreenStatesRoute(),
  GalleryDestination.home: (state) =>
      HomePage(initialIndex: _at(HomePage.variants, state) ?? 0),
  GalleryDestination.assistant: (state) =>
      AssistantPage(initialIndex: _at(AssistantPage.variants, state) ?? 0),
  GalleryDestination.capture: (state) =>
      CapturePage(initialIndex: _at(CapturePage.variants, state)),
  GalleryDestination.statement: (state) =>
      StatementPage(initialIndex: _at(StatementPage.variants, state) ?? 0),
  GalleryDestination.closing: (state) =>
      ClosingPage(initialIndex: _at(ClosingPage.variants, state) ?? 0),
  GalleryDestination.debts: (state) =>
      DebtsPage(initialIndex: _at(DebtsPage.variants, state) ?? 0),
  GalleryDestination.homeWidget: (state) =>
      HomeWidgetPage(initialIndex: _at(HomeWidgetPage.variants, state) ?? 0),
  GalleryDestination.depthScroll: (_) => const DepthScrollPage(),
  GalleryDestination.coverFlow: (_) => const CoverFlowPage(),
  GalleryDestination.cinematic: (_) => const CinematicPage(),
  GalleryDestination.wallet: (_) => const WalletPage(),
  GalleryDestination.camera: (_) => const CameraPage(),
  GalleryDestination.alive: (_) => const AlivePage(),
  GalleryDestination.motionDesk: (_) => const MotionDeskPage(),
  GalleryDestination.soundDesk: (_) => const SoundDeskPage(),
  GalleryDestination.action: (_) => const ActionPage(),
  GalleryDestination.content: (_) => const ContentPage(),
  GalleryDestination.fields: (_) => const FieldPage(),
  GalleryDestination.states: (_) => const StatePage(),
  GalleryDestination.conversation: (_) => const ConversationPage(),
  GalleryDestination.doDont: (_) => const DoDontPage(),
  GalleryDestination.colors: (_) => const ColorsPage(),
  GalleryDestination.shortfall: (_) => const ShortfallComparePage(),
  GalleryDestination.contrast: (_) => const ContrastPage(),
  GalleryDestination.typography: (_) => const TypographyPage(),
  GalleryDestination.layout: (_) => const LayoutPage(),
  GalleryDestination.icons: (_) => const IconsPage(),
};
