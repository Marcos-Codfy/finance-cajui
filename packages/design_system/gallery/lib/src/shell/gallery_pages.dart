import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/alive/alive_page.dart';
import 'package:gallery/src/pages/components/action_page.dart';
import 'package:gallery/src/pages/components/content_page.dart';
import 'package:gallery/src/pages/components/field_page.dart';
import 'package:gallery/src/pages/components/state_page.dart';
import 'package:gallery/src/pages/depth/cinematic_page.dart';
import 'package:gallery/src/pages/depth/cover_flow_page.dart';
import 'package:gallery/src/pages/depth/depth_scroll_page.dart';
import 'package:gallery/src/pages/depth/wallet_page.dart';
import 'package:gallery/src/pages/screens/assistant/assistant_page.dart';
import 'package:gallery/src/pages/screens/capture/capture_page.dart';
import 'package:gallery/src/pages/screens/closing/closing_page.dart';
import 'package:gallery/src/pages/screens/dashboard/dashboard_page.dart';
import 'package:gallery/src/pages/screens/debts/debts_page.dart';
import 'package:gallery/src/pages/screens/shortfall/shortfall_compare_page.dart';
import 'package:gallery/src/pages/screens/statement/statement_page.dart';
import 'package:gallery/src/pages/senses/motion_desk_page.dart';
import 'package:gallery/src/pages/senses/sound_desk_page.dart';
import 'package:gallery/src/pages/tokens/colors_page.dart';
import 'package:gallery/src/pages/tokens/contrast_page.dart';
import 'package:gallery/src/pages/tokens/icons_page.dart';
import 'package:gallery/src/pages/tokens/layout_page.dart';
import 'package:gallery/src/pages/tokens/typography_page.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// A página de cada destino. O `switch` é exaustivo: destino novo sem página
/// não compila.
Widget galleryPageOf(GalleryDestination destination) => switch (destination) {
  GalleryDestination.colors => const ColorsPage(),
  GalleryDestination.contrast => const ContrastPage(),
  GalleryDestination.typography => const TypographyPage(),
  GalleryDestination.layout => const LayoutPage(),
  GalleryDestination.icons => const IconsPage(),
  GalleryDestination.action => const ActionPage(),
  GalleryDestination.content => const ContentPage(),
  GalleryDestination.fields => const FieldPage(),
  GalleryDestination.states => const StatePage(),
  GalleryDestination.alive => const AlivePage(),
  GalleryDestination.depthScroll => const DepthScrollPage(),
  GalleryDestination.coverFlow => const CoverFlowPage(),
  GalleryDestination.cinematic => const CinematicPage(),
  GalleryDestination.wallet => const WalletPage(),
  GalleryDestination.dashboard => const DashboardPage(),
  GalleryDestination.capture => const CapturePage(),
  GalleryDestination.statement => const StatementPage(),
  GalleryDestination.closing => const ClosingPage(),
  GalleryDestination.debts => const DebtsPage(),
  GalleryDestination.assistant => const AssistantPage(),
  GalleryDestination.shortfall => const ShortfallComparePage(),
  GalleryDestination.soundDesk => const SoundDeskPage(),
  GalleryDestination.motionDesk => const MotionDeskPage(),
};
