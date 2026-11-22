import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import 'shell/app_shell.dart';

/// Builds the router from the feature modules.
///
/// * Public routes (sign-in) render without the shell.
/// * Everything else renders inside [AppShell] and requires a session;
///   signed-out users go to `/login?from=<where they were going>`.
GoRouter buildRouter({required AuthSession session, required List<FeatureModule> features}) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: session,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == AppRoutes.login;
      if (!session.isSignedIn) {
        if (atLogin) return null;
        final from = state.uri.toString();
        return from == AppRoutes.dashboard
            ? AppRoutes.login
            : Uri(path: AppRoutes.login, queryParameters: {'from': from}).toString();
      }
      if (atLogin) return state.uri.queryParameters['from'] ?? AppRoutes.dashboard;
      return null;
    },
    routes: [
      for (final f in features) ...f.publicRoutes,
      ShellRoute(
        builder: (context, state, child) => AppShell(
          session: session,
          navItems: () => [for (final f in features) ...f.navItems]..sort((a, b) => a.order.compareTo(b.order)),
          location: state.uri.path,
          child: child,
        ),
        routes: [for (final f in features) ...f.shellRoutes],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message: "There's nothing at ${state.uri.path}.",
        actionLabel: 'Go to dashboard',
        onAction: () => context.go(AppRoutes.dashboard),
      ),
    ),
  );
}
