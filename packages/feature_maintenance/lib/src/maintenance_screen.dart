import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'maintenance_view_model.dart';

/// Every service and repair across the fleet, newest first, with this
/// month's figures on top. Add records from a vehicle's page.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, required this.createViewModel});

  final MaintenanceViewModel Function() createViewModel;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late final MaintenanceViewModel _vm = widget.createViewModel()..load();
  final _search = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => VmsPage(
        crumbs: const [Crumb('Maintenance')],
        title: 'Maintenance',
        subtitle: 'Every service and repair across the fleet. Record new work from a vehicle\'s page.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _figures(),
            const SizedBox(height: VmsSpace.s4),
            _toolbar(),
            const SizedBox(height: VmsSpace.s4),
            if (_vm.error != null) ...[
              ErrorBanner(message: _vm.error!.message, actionLabel: 'Try again', onAction: _vm.load),
              const SizedBox(height: VmsSpace.s4),
            ],
            VmsCard(child: _table(context)),
            if ((_vm.page?.totalPages ?? 0) > 1) _pager(_vm.page!),
          ],
        ),
      ),
    );
  }

  Widget _figures() {
    final s = _vm.stats;
    Widget tile(String label, String? value, String? hint) => Expanded(
          child: VmsCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: VmsColors.textMeta)),
                const SizedBox(height: 8),
                if (value == null) const Skeleton(width: 90, height: 30) else Text(value, style: VmsText.kpi),
                if (hint != null) ...[const SizedBox(height: 4), Text(hint, style: VmsText.meta)],
              ],
            ),
          ),
        );
    return LayoutBuilder(builder: (context, c) {
      final tiles = [
        tile('Cost this month', s == null ? null : formatTaka(s.costThisMonth),
            s == null ? null : '${s.recordsThisMonth} record${s.recordsThisMonth == 1 ? '' : 's'}'),
        tile('Vehicles serviced', s == null ? null : '${s.vehiclesServicedLast30Days}', 'in the last 30 days'),
        tile('All-time cost', s == null ? null : formatTaka(s.totalCost),
            s == null ? null : '${s.totalRecords} records'),
      ];
      if (c.maxWidth < 700) {
        return Column(
          children: [
            for (final t in tiles) Row(children: [t]),
          ].expand((w) => [w, const SizedBox(height: VmsSpace.s3)]).toList(),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [tiles[0], const SizedBox(width: VmsSpace.s4), tiles[1], const SizedBox(width: VmsSpace.s4), tiles[2]],
      );
    });
  }

  Widget _toolbar() {
    final q = _vm.query;
    return Wrap(
      spacing: VmsSpace.s3,
      runSpacing: VmsSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: VmsTextField(
            label: 'Search maintenance',
            showLabel: false,
            controller: _search,
            hint: 'Vehicle number, workshop, notes…',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: _vm.setSearch,
          ),
        ),
        SizedBox(
          width: 190,
          child: VmsSelect<MaintenanceType?>(
            small: true,
            hint: 'All types',
            value: q.type,
            options: [
              const VmsOption<MaintenanceType?>(null, 'All types'),
              for (final t in MaintenanceType.values) VmsOption<MaintenanceType?>(t, t.label),
            ],
            onChanged: _vm.setType,
          ),
        ),
        SizedBox(
          width: 170,
          child: VmsDateField(
            label: 'From',
            showLabel: false,
            hint: 'From date',
            optional: true,
            value: q.from,
            lastDate: DateTime.now(),
            onChanged: _vm.setFrom,
          ),
        ),
        SizedBox(
          width: 170,
          child: VmsDateField(
            label: 'To',
            showLabel: false,
            hint: 'To date',
            optional: true,
            value: q.to,
            lastDate: DateTime.now(),
            onChanged: _vm.setTo,
          ),
        ),
        SizedBox(
          width: 170,
          child: VmsSelect<String>(
            small: true,
            value: q.sort,
            options: [for (final o in MaintenanceViewModel.sorts) VmsOption(o.$1, o.$2)],
            onChanged: (s) {
              if (s != null) _vm.setSort(s);
            },
          ),
        ),
        if (_vm.hasCriteria)
          VmsButton(
            label: 'Clear',
            small: true,
            variant: VmsButtonVariant.text,
            onPressed: () {
              _search.clear();
              _vm.clearAll();
            },
          ),
      ],
    );
  }

  static const _dateW = 120.0, _vehicleW = 220.0, _typeW = 150.0, _odoW = 110.0, _costW = 130.0;

  Widget _table(BuildContext context) {
    final page = _vm.page;
    if (page != null && page.items.isEmpty && !_vm.loading) {
      return EmptyState(
        icon: _vm.hasCriteria ? Icons.search_off : Icons.build_outlined,
        title: _vm.hasCriteria ? 'No records match' : 'No maintenance recorded yet',
        message: _vm.hasCriteria
            ? 'Clear the search and filters to see every record.'
            : 'Open a vehicle and choose Record maintenance after each service or repair.',
        actionLabel: _vm.hasCriteria ? 'Clear filters' : 'Go to vehicles',
        onAction: () {
          if (_vm.hasCriteria) {
            _search.clear();
            _vm.clearAll();
          } else {
            context.go(AppRoutes.vehicles);
          }
        },
      );
    }
    const fixed = _dateW + _vehicleW + _typeW + _odoW + _costW + 48;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth > fixed + 220 ? constraints.maxWidth : fixed + 220;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: VmsColors.surfaceSubtle,
                  border: Border(bottom: BorderSide(color: VmsColors.divider)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: _dateW, child: Text('DATE', style: VmsText.th)),
                    SizedBox(width: _vehicleW, child: Text('VEHICLE', style: VmsText.th)),
                    SizedBox(width: _typeW, child: Text('TYPE', style: VmsText.th)),
                    Expanded(child: Text('WORKSHOP / NOTES', style: VmsText.th)),
                    SizedBox(width: _odoW, child: Text('ODOMETER', style: VmsText.th, textAlign: TextAlign.right)),
                    SizedBox(width: _costW, child: Text('COST', style: VmsText.th, textAlign: TextAlign.right)),
                  ],
                ),
              ),
              if (page == null)
                for (var i = 0; i < 6; i++)
                  const Padding(padding: EdgeInsets.fromLTRB(24, 18, 24, 18), child: Skeleton(height: 18))
              else
                for (final r in page.items) _row(context, r),
              if (page != null && page.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  color: VmsColors.surfaceSubtle,
                  child: Row(
                    children: [
                      Expanded(child: Text('Total on this page', style: VmsText.label)),
                      Text(formatTaka(_vm.pageCost), style: VmsText.tabular(VmsText.section)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _row(BuildContext context, MaintenanceRecord r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VmsColors.divider))),
      child: Row(
        children: [
          SizedBox(width: _dateW, child: Text(formatDate(r.serviceDate), style: VmsText.tabular(VmsText.table))),
          SizedBox(
            width: _vehicleW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PlateBadge(
                number: r.vehicleNumber ?? 'Vehicle ${r.vehicleId}',
                onTap: () => context.go(AppRoutes.vehicleSection(r.vehicleId, 'maintenance')),
              ),
            ),
          ),
          SizedBox(width: _typeW, child: Text(r.type.label, style: VmsText.table)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.vendor, style: VmsText.table, overflow: TextOverflow.ellipsis),
                if (r.notes != null) Text(r.notes!, style: VmsText.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: _odoW,
            child: Text(r.odometerKm == null ? '—' : '${r.odometerKm} km',
                textAlign: TextAlign.right, style: VmsText.tabular(VmsText.table)),
          ),
          SizedBox(
            width: _costW,
            child: Text(formatTaka(r.cost), textAlign: TextAlign.right, style: VmsText.tabular(VmsText.table)),
          ),
        ],
      ),
    );
  }

  Widget _pager(Paged<MaintenanceRecord> page) => Padding(
        padding: const EdgeInsets.only(top: VmsSpace.s4),
        child: Row(
          children: [
            Expanded(child: Text(page.rangeLabel, style: VmsText.tabular(VmsText.meta))),
            VmsButton(
              label: 'Previous',
              small: true,
              variant: VmsButtonVariant.secondary,
              onPressed: page.hasPrevious ? _vm.previousPage : null,
            ),
            const SizedBox(width: 8),
            VmsButton(
              label: 'Next',
              small: true,
              variant: VmsButtonVariant.secondary,
              onPressed: page.hasNext ? _vm.nextPage : null,
            ),
          ],
        ),
      );
}
