import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:go_router/go_router.dart';

/// One entry in the sidebar.
@immutable
class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.path,
    this.section,
    this.order = 0,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String path;

  /// Sidebar group label (`Fleet`, `Workspace`); null = top group.
  final String? section;

  /// Lower comes first.
  final int order;

  /// Optional live count shown as a badge (e.g. number of vehicles).
  final ValueListenable<int?>? badge;
}

/// Contract every feature package implements.
///
/// The app shell knows nothing about individual features: it asks each module
/// for its routes and sidebar entries. A team adds a feature by implementing
/// this class and registering it in `lib/main.dart` — no shell changes.
abstract class FeatureModule {
  const FeatureModule();

  /// Routes shown without the app shell (e.g. sign-in). Public.
  List<RouteBase> get publicRoutes => const [];

  /// Routes rendered inside the signed-in shell (sidebar + content).
  List<RouteBase> get shellRoutes => const [];

  List<NavItem> get navItems => const [];
}
