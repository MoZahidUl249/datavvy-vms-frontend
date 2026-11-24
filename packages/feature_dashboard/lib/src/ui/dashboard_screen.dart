import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import '../data/dashboard_models.dart';
import 'dashboard_view_model.dart';

/// Fleet at a glance: vehicle KPIs, then documents, maintenance and drivers.
/// Every number links to the list behind it. Optional cards are switched
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
        _operationsKpis(context, s),
        const SizedBox(height: VmsSpace.s4),
        _Grid(children: [
          if (prefs.showsCard(DashboardCard.documentAlerts)) _documentAlerts(context, s),
          if (prefs.showsCard(DashboardCard.maintenanceCost)) _maintenanceCost(context, s),
          if (prefs.showsCard(DashboardCard.byType)) _bars('Vehicles by type', s?.byType, VmsColors.nav),
          if (prefs.showsCard(DashboardCard.byBrand)) _bars('Vehicles by brand', s?.byBrand, VmsColors.primary),
          if (prefs.showsCard(DashboardCard.recentMaintenance)) _recentMaintenance(context, s),
          if (prefs.showsCard(DashboardCard.drivers)) _drivers(context, s),
          if (prefs.showsCard(DashboardCard.recentlyUpdated)) _recent(context, s),
          if (prefs.showsCard(DashboardCard.inMaintenance)) _inMaintenance(context, s),
        ]),
      ],
    );
  }

  Widget _kpis(BuildContext context, DashboardSummary? s) {
    Widget card(String label, int? value, String hint, VoidCallback onTap) => _KpiCard(
          label: label,
          value: value?.toString(),
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
                    onTap: () => context.go(AppRoutes.vehicleDetail(v.id)),
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
                        onTap: () => context.go(AppRoutes.vehicleDetail(v.id)),
                      ),
                  ],
                ),
    );
  }

  /// Documents, maintenance and drivers in numbers; each opens its list.
  Widget _operationsKpis(BuildContext context, DashboardSummary? s) {
    final docs = s?.documents;
    final m = s?.maintenanceStats;
    final d = s?.drivers;
    final loaded = s != null;
    return _Grid(minWidth: 220, children: [
      _KpiCard(
        label: 'Documents expired',
        value: loaded ? '${docs?.expired ?? 0}' : null,
        note: docs == null ? null : 'of ${docs.total} documents',
        alert: (docs?.expired ?? 0) > 0,
        hint: 'Show expired documents',
        onTap: () => context.go(AppRoutes.documentsWhere(expiry: 'EXPIRED')),
      ),
      _KpiCard(
        label: 'Expiring in ${docs?.expiringSoonDays ?? 30} days',
        value: loaded ? '${docs?.expiringSoon ?? 0}' : null,
        note: 'renew before they lapse',
        hint: 'Show documents expiring soon',
        onTap: () => context.go(AppRoutes.documentsWhere(expiry: 'EXPIRING_SOON')),
      ),
      _KpiCard(
        label: 'Maintenance this month',
        value: loaded ? formatTaka(m?.costThisMonth ?? 0) : null,
        note: m == null ? null : '${m.recordsThisMonth} record${m.recordsThisMonth == 1 ? '' : 's'} · ${formatTaka(m.totalCost)} all time',
        hint: 'Open the maintenance log',
        onTap: () => context.go(AppRoutes.maintenance),
      ),
      _KpiCard(
        label: 'Drivers available',
        value: loaded ? '${d?.available ?? 0}' : null,
        note: d == null ? null : '${d.assigned} of ${d.total} on a vehicle',
        hint: 'Show active drivers without a vehicle',
        onTap: () => context.go(AppRoutes.driversWhere(assigned: false, status: 'ACTIVE')),
      ),
    ]);
  }

  Widget _documentAlerts(BuildContext context, DashboardSummary? s) {
    final docs = s?.documents;
    return VmsCard(
      title: 'Documents needing attention',
      trailing: TextButton(
        onPressed: () => context.go(AppRoutes.documentsWhere(expiry: 'attention')),
        child: Text(docs == null || docs.needingAttention == 0 ? 'View all' : 'View all ${docs.needingAttention}'),
      ),
      child: s == null
          ? const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: _ListSkeleton())
          : s.documentAlerts.isEmpty
              ? const _AllGood(message: 'No document is expired or expiring soon.')
              : Column(
                  children: [
                    for (final a in s.documentAlerts)
                      _LinkRow(
                        onTap: () => context.go(AppRoutes.vehicleSection(a.vehicleId, 'documents')),
                        children: [
                          PlateBadge(number: a.vehicleNumber ?? 'Vehicle ${a.vehicleId}'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.displayName, style: VmsText.table, overflow: TextOverflow.ellipsis),
                                Text(describeExpiry(a.expiryStatus, a.daysUntilExpiry), style: VmsText.meta),
                              ],
                            ),
                          ),
                          ExpiryPill(status: a.expiryStatus, daysLeft: a.daysUntilExpiry),
                        ],
                      ),
                  ],
                ),
    );
  }

  Widget _maintenanceCost(BuildContext context, DashboardSummary? s) {
    final m = s?.maintenanceStats;
    final months = m?.byMonth ?? const <MonthCost>[];
    final max = months.fold<double>(0, (v, e) => e.cost > v ? e.cost : v);
    return VmsCard(
      title: 'Maintenance cost by month',
      trailing: TextButton(onPressed: () => context.go(AppRoutes.maintenance), child: const Text('Open log')),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: s == null
          ? const _ListSkeleton()
          : months.isEmpty
              ? const Text('No maintenance recorded yet.', style: VmsText.meta)
              : Column(
                  children: [
                    for (final month in months)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(width: 64, child: Text(month.label(withYear: true), style: VmsText.table)),
                            Expanded(
                              child: Tooltip(
                                message: '${month.count} record${month.count == 1 ? '' : 's'}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: max == 0 ? 0 : month.cost / max,
                                    minHeight: 10,
                                    color: VmsColors.chart[3],
                                    backgroundColor: VmsColors.track,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Text(formatTaka(month.cost),
                                  textAlign: TextAlign.right, style: VmsText.tabular(VmsText.table)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _recentMaintenance(BuildContext context, DashboardSummary? s) {
    return VmsCard(
      title: 'Recent maintenance',
      trailing: TextButton(onPressed: () => context.go(AppRoutes.maintenance), child: const Text('View all')),
      child: s == null
          ? const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: _ListSkeleton())
          : s.recentMaintenance.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Text('Nothing recorded yet. Record work from a vehicle\'s page.', style: VmsText.meta),
                )
              : Column(
                  children: [
                    for (final r in s.recentMaintenance)
                      _LinkRow(
                        onTap: () => context.go(AppRoutes.vehicleSection(r.vehicleId, 'maintenance')),
                        children: [
                          PlateBadge(number: r.vehicleNumber ?? 'Vehicle ${r.vehicleId}'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.type.label, style: VmsText.table),
                                Text('${formatDate(r.serviceDate)} · ${r.vendor}',
                                    style: VmsText.meta, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Text(formatTaka(r.cost), style: VmsText.tabular(VmsText.table)),
                        ],
                      ),
                  ],
                ),
    );
  }

  Widget _drivers(BuildContext context, DashboardSummary? s) {
    final d = s?.drivers;
    Widget line(String label, int value, VoidCallback onTap, {StatusTone? tone}) => _LinkRow(
          onTap: onTap,
          children: [
            Expanded(child: Text(label, style: VmsText.table)),
            if (tone != null && value > 0)
              StatusPill(label: '$value', tone: tone)
            else
              Text('$value', style: VmsText.tabular(VmsText.section)),
          ],
        );
    return VmsCard(
      title: 'Drivers',
      trailing: TextButton(onPressed: () => context.go(AppRoutes.drivers), child: const Text('View all')),
      child: d == null
          ? const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: _ListSkeleton())
          : Column(
              children: [
                line('On a vehicle', d.assigned, () => context.go(AppRoutes.driversWhere(assigned: true))),
                line('Active without a vehicle', d.available,
                    () => context.go(AppRoutes.driversWhere(assigned: false, status: 'ACTIVE'))),
                line('On leave', d.onLeave, () => context.go(AppRoutes.driversWhere(status: 'ON_LEAVE'))),
                line('Licence expiring soon', d.licenseExpiringSoon, () => context.go(AppRoutes.drivers),
                    tone: StatusTone.warning),
                line('Licence expired', d.licenseExpired, () => context.go(AppRoutes.drivers), tone: StatusTone.danger),
              ],
            ),
    );
  }
}

/// Tappable list row with a top hairline.
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.onTap, required this.children});

  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: VmsColors.divider))),
        child: Row(children: children),
      ),
    );
  }
}

class _AllGood extends StatelessWidget {
  const _AllGood({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        children: [
          const Icon(Icons.check, color: VmsColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14, color: VmsColors.successText))),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.note,
    this.alert = false,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  /// Small line under the number ("of 23 documents").
  final String? note;

  /// Red number: something is already wrong (expired papers).
  final bool alert;

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
                  Text(value!, style: alert ? VmsText.kpi.copyWith(color: VmsColors.danger) : VmsText.kpi),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(note!, style: VmsText.meta),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle, required this.onTap, this.trailing});

  final DashboardVehicle vehicle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final line =
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
