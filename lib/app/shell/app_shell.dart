import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

/// Signed-in frame: deep-blue sidebar + content. On narrow screens the
/// sidebar moves into a drawer. Knows nothing about individual features —
/// it renders whatever [NavItem]s the modules contribute.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.session,
    required this.navItems,
    required this.location,
    required this.child,
  });

  final AuthSession session;
  final List<NavItem> Function() navItems;
  final String location;
  final Widget child;

  static const _breakpoint = 960.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _breakpoint;
    final sidebar = _Sidebar(session: session, items: navItems(), location: location, inDrawer: !wide);
    if (wide) {
      return Scaffold(
        backgroundColor: VmsColors.page,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: VmsSize.sidebar, child: sidebar),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: VmsColors.page,
      appBar: AppBar(
        backgroundColor: VmsColors.nav,
        foregroundColor: Colors.white,
        title: const Text('Fleet Console', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      drawer: Drawer(width: VmsSize.sidebar, backgroundColor: VmsColors.nav, child: sidebar),
      body: child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.session, required this.items, required this.location, required this.inDrawer});

  final AuthSession session;
  final List<NavItem> items;
  final String location;
  final bool inDrawer;

  /// Longest matching path wins (`/vehicles/new` beats `/vehicles`); `/` only exact.
  NavItem? get _selected {
    NavItem? best;
    for (final item in items) {
      final match = item.path == '/'
          ? location == '/'
          : location == item.path || location.startsWith('${item.path}/');
      if (match && (best == null || item.path.length > best.path.length)) best = item;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final sections = <String?, List<NavItem>>{};
    for (final item in items) {
      sections.putIfAbsent(item.section, () => []).add(item);
    }
    final user = session.user;

    return Container(
      color: VmsColors.nav,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final entry in sections.entries) ...[
                    if (entry.key != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
                        child: Text(
                          entry.key!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: Color(0x99FFFFFF),
                          ),
                        ),
                      ),
                    for (final item in entry.value)
                      _NavTile(
                        item: item,
                        selected: identical(item, selected) || item == selected,
                        onTap: () {
                          if (inDrawer) Navigator.of(context).pop();
                          context.go(item.path);
                        },
                      ),
                  ],
                ],
              ),
            ),
            if (user != null) _UserBlock(user: user, onSignOut: session.signOut),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fleet Console', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              Text('Datavvy VMS', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = item.badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(VmsRadius.control),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(VmsRadius.control),
            hoverColor: Colors.white.withValues(alpha: 0.08),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: selected ? Colors.white : const Color(0xCCFFFFFF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xCCFFFFFF),
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (badge != null)
                      ValueListenableBuilder<int?>(
                        valueListenable: badge,
                        builder: (context, count, _) => count == null
                            ? const SizedBox.shrink()
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(VmsRadius.pill),
                                ),
                                child: Text('$count',
                                    style: VmsText.tabular(const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBlock extends StatelessWidget {
  const _UserBlock({required this.user, required this.onSignOut});

  final SessionUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VmsRadius.group),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: VmsColors.primary,
            child: Text(user.initials,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(user.roleLabel, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              ],
            ),
          ),
          Tooltip(
            message: 'Sign out',
            child: IconButton(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
