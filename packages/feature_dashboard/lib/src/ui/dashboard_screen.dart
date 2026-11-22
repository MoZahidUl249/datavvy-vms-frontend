import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../data/dashboard_models.dart';
import 'dashboard_view_model.dart';

/// Only data the app really has: vehicle records. Optional cards are switched
/// on/off in Settings (no Customize button here).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.createViewModel,
    required this.preferences,
    required this.canManageFleet,
  });

  final DashboardViewModel Function() createViewModel;
  final UiPreferences preferences;
  final bool canManageFleet;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardViewModel _vm = widget.createViewModel()..load();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, widget.preferences]),
      builder: (context, _) => VmsPage(
        crumbs: const [Crumb('Dashboard')],
        title: 'Dashboard',
        subtitle: 'Your fleet at a glance.',
        actions: [
          if (widget.canManageFleet)
            VmsButton(label: 'Register vehicle', icon: Icons.add, onPressed: () => context.go(AppRoutes.vehicleNew)),
        ],
        body: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final s = _vm.summary;
    if (_vm.error != null && s == null) {
      return ErrorBanner(message: _vm.error!.message, actionLabel: 'Try again', onAction: _vm.load);
    }
    if (s != null && s.total == 0) {
      return VmsCard(
        child: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'Your dashboard fills in as you add vehicles',
          message: 'Register your first vehicle to see fleet totals, types, brands and what is in maintenance.',
          actionLabel: widget.canManageFleet ? 'Register vehicle' : null,
          onAction: () => context.go(AppRoutes.vehicleNew),
        ),
      );
    }
    final prefs = widget.preferences;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kpis(context, s),
        const SizedBox(height: VmsSpace.s4),
        _Grid(children: [
          if (prefs.showsCard(DashboardCard.byType)) _bars('Vehicles by type', s?.byType, VmsColors.nav),
          if (prefs.showsCard(DashboardCard.byBrand)) _bars('Vehicles by brand', s?.byBrand, VmsColors.primary),
          if (prefs.showsCard(DashboardCard.recentlyUpdated)) _recent(context, s),
          if (prefs.showsCard(DashboardCard.inMaintenance)) _inMaintenance(context, s),
        ]),
      ],
    );
  }

  Widget _kpis(BuildContext context, DashboardSummary? s) {
    Widget card(String label, int? value, String hint, VoidCallback onTap) => _KpiCard(
          label: label,
          value: value,
          hint: hint,
          onTap: onTap,
        );
    return _Grid(minWidth: 220, children: [
      card('Total vehicles', s?.total, 'Open the vehicle list', () => context.go(AppRoutes.vehicles)),
      card('Active', s?.active, 'Show active vehicles', () => context.go(AppRoutes.vehiclesWhere(status: 'ACTIVE'))),
      card('Inactive', s?.inactive, 'Show inactive vehicles',
          () => context.go(AppRoutes.vehiclesWhere(status: 'INACTIVE'))),
      card('In maintenance', s?.maintenance, 'Show vehicles in maintenance',
          () => context.go(AppRoutes.vehiclesWhere(status: 'MAINTENANCE'))),
    ]);
  }

  Widget _bars(String title, List<DashboardSlice>? slices, Color color) {
    final items = slices ?? const <DashboardSlice>[];
    final max = items.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    return VmsCard(
      title: title,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: slices == null
          ? const _ListSkeleton()
          : items.isEmpty
              ? const Text('Nothing to show yet.', style: VmsText.meta)
              : Column(
                  children: [
                    for (final t in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 104,
                              child: Text(t.name, style: VmsText.table, overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: max == 0 ? 0 : t.count / max,
                                  minHeight: 10,
                                  color: color,
                                  backgroundColor: VmsColors.track,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text('${t.count}',
                                  textAlign: TextAlign.right, style: VmsText.tabular(VmsText.table)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _recent(BuildContext context, DashboardSummary? s) {
    return VmsCard(
      title: 'Recently updated',
      trailing: TextButton(onPressed: () => context.go(AppRoutes.vehicles), child: const Text('View all')),
      child: s == null
          ? const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: _ListSkeleton())
          : Column(
              children: [
                for (final v in s.recentlyUpdated)
                  _VehicleRow(
                    vehicle: v,
                    trailing: Text(formatDate(v.updatedAt), style: VmsText.tabular(VmsText.meta)),
                    onTap: () => context.go(AppRoutes.vehicleEdit(v.id)),
                  ),
              ],
            ),
    );
  }

  Widget _inMaintenance(BuildContext context, DashboardSummary? s) {
    return VmsCard(
      title: 'In maintenance',
      trailing: s == null ? null : Text('${s.maintenance}', style: VmsText.tabular(VmsText.meta)),
      child: s == null
          ? const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: _ListSkeleton())
          : s.inMaintenance.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: VmsColors.success, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('No vehicles are in maintenance.',
                            style: TextStyle(fontSize: 14, color: VmsColors.successText)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final v in s.inMaintenance)
                      _VehicleRow(
                        vehicle: v,
                        trailing: Text(formatDate(v.updatedAt), style: VmsText.tabular(VmsText.meta)),
                        onTap: () => context.go(AppRoutes.vehicleEdit(v.id)),
                      ),
                  ],
                ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.hint, required this.onTap});

  final String label;
  final int? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: hint,
      child: Material(
        color: VmsColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VmsRadius.card),
          side: const BorderSide(color: VmsColors.borderCard),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VmsRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: VmsColors.textMeta)),
                const SizedBox(height: 8),
                if (value == null)
                  const Skeleton(width: 56, height: 34, radius: 8)
                else
                  Text('$value', style: VmsText.kpi),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle, required this.onTap, this.trailing, this.subtitle});

  final DashboardVehicle vehicle;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final line = subtitle ??
        [vehicle.company, '${vehicle.brand} ${vehicle.model}'.trim()].where((e) => e.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: VmsColors.divider))),
        child: Row(
          children: [
            PlateBadge(number: vehicle.vehicleNumber),
            const SizedBox(width: 12),
            Expanded(child: Text(line, style: VmsText.secondary, overflow: TextOverflow.ellipsis)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Skeleton(height: 16)),
      ),
    );
  }
}

/// Responsive grid: as many columns of at least [minWidth] as fit.
class _Grid extends StatelessWidget {
  const _Grid({required this.children, this.minWidth = 420});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = VmsSpace.s4;
      final columns = ((constraints.maxWidth + gap) / (minWidth + gap)).floor().clamp(1, 4);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    });
  }
}
