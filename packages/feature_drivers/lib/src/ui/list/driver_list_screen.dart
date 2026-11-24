import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'driver_list_view_model.dart';

StatusTone driverStatusTone(DriverStatus s) => switch (s) {
      DriverStatus.active => StatusTone.success,
      DriverStatus.onLeave => StatusTone.warning,
      DriverStatus.inactive => StatusTone.neutral,
    };

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key, required this.createViewModel, required this.canManage});

  final DriverListViewModel Function() createViewModel;
  final bool canManage;

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  late final DriverListViewModel _vm = widget.createViewModel()..load();
  late final TextEditingController _search = TextEditingController(text: _vm.query.search);

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
      builder: (context, _) {
        final s = _vm.stats;
        return VmsPage(
          crumbs: const [Crumb('Drivers')],
          title: 'Drivers',
          subtitle: s.total == 0
              ? 'Everyone who drives your vehicles.'
              : '${s.total} drivers · ${s.assigned} on a vehicle · ${s.available} available'
                  '${s.licenseExpired + s.licenseExpiringSoon > 0 ? ' · ${s.licenseExpired + s.licenseExpiringSoon} licences need attention' : ''}',
          actions: [
            if (widget.canManage)
              VmsButton(label: 'Add driver', icon: Icons.person_add_alt, onPressed: () => context.go(AppRoutes.driverNew)),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
        );
      },
    );
  }

  Widget _toolbar() {
    final q = _vm.query;
    final s = _vm.stats;
    return Wrap(
      spacing: VmsSpace.s3,
      runSpacing: VmsSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        VmsSegmented<DriverStatus?>(
          semanticLabel: 'Driver status',
          selected: q.status,
          onChanged: _vm.setStatus,
          segments: [
            VmsSegment(value: null, label: 'All', count: s.total),
            VmsSegment(value: DriverStatus.active, label: 'Active', count: s.active),
            VmsSegment(value: DriverStatus.onLeave, label: 'On leave', count: s.onLeave),
            VmsSegment(value: DriverStatus.inactive, label: 'Inactive', count: s.inactive),
          ],
        ),
        SizedBox(
          width: 280,
          child: VmsTextField(
            label: 'Search drivers',
            showLabel: false,
            controller: _search,
            hint: 'Search name, mobile, licence…',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: _vm.setSearch,
          ),
        ),
        SizedBox(
          width: 190,
          child: VmsSelect<AssignmentFilter>(
            small: true,
            value: q.assignment,
            options: [for (final f in AssignmentFilter.values) VmsOption(f, f.label)],
            onChanged: (f) {
              if (f != null) _vm.setAssignment(f);
            },
          ),
        ),
        SizedBox(
          width: 210,
          child: VmsSelect<String>(
            small: true,
            value: q.sort,
            options: [for (final s in DriverListViewModel.sorts) VmsOption(s.$1, s.$2)],
            onChanged: (s) {
              if (s != null) _vm.setSort(s);
            },
          ),
        ),
      ],
    );
  }

  static const _licenceW = 190.0, _licStatusW = 140.0, _statusW = 120.0, _vehicleW = 210.0, _actionsW = 170.0;

  Widget _table(BuildContext context) {
    final page = _vm.page;
    if (page != null && page.items.isEmpty && !_vm.loading) {
      return _vm.hasCriteria
          ? EmptyState(
              icon: Icons.search_off,
              title: 'No drivers match',
              message: 'Clear the search and filters to see every driver.',
              actionLabel: 'Show all drivers',
              onAction: () {
                _search.clear();
                _vm.clearAll();
              },
            )
          : EmptyState(
              icon: Icons.badge_outlined,
              title: 'Add your first driver',
              message: "You'll need their name, mobile number, licence number and licence expiry date.",
              actionLabel: widget.canManage ? 'Add driver' : null,
              onAction: () => context.go(AppRoutes.driverNew),
            );
    }
    const fixed = _licenceW + _licStatusW + _statusW + _vehicleW + _actionsW + 48;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth > fixed + 220 ? constraints.maxWidth : fixed + 220;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              if (page == null)
                for (var i = 0; i < 5; i++) _skeletonRow()
              else
                for (final d in page.items) _row(context, d),
            ],
          ),
        ),
      );
    });
  }

  Widget _header() => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: VmsColors.surfaceSubtle,
          border: Border(bottom: BorderSide(color: VmsColors.divider)),
        ),
        child: const Row(
          children: [
            Expanded(child: Text('DRIVER', style: VmsText.th)),
            SizedBox(width: _licenceW, child: Text('LICENCE', style: VmsText.th)),
            SizedBox(width: _licStatusW, child: Text('LICENCE STATUS', style: VmsText.th)),
            SizedBox(width: _statusW, child: Text('STATUS', style: VmsText.th)),
            SizedBox(width: _vehicleW, child: Text('VEHICLE', style: VmsText.th)),
            SizedBox(width: _actionsW, child: Text('ACTIONS', style: VmsText.th, textAlign: TextAlign.right)),
          ],
        ),
      );

  Widget _row(BuildContext context, Driver d) {
    final vehicle = d.assignedVehicle;
    return Container(
      height: VmsSize.row,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VmsColors.divider))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.go(AppRoutes.driverEdit(d.id)),
                  child: Text(d.fullName, style: VmsText.section, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 2),
                Text(d.phone, style: VmsText.tabular(VmsText.secondary)),
              ],
            ),
          ),
          SizedBox(
            width: _licenceW,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.licenseNumber, style: VmsText.tabular(VmsText.table), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Expires ${formatDate(d.licenseExpiry)}', style: VmsText.meta),
              ],
            ),
          ),
          SizedBox(
            width: _licStatusW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ExpiryPill(status: d.licenseStatus, daysLeft: d.licenseDaysLeft),
            ),
          ),
          SizedBox(
            width: _statusW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(label: d.status.label, tone: driverStatusTone(d.status)),
            ),
          ),
          SizedBox(
            width: _vehicleW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: vehicle == null
                  ? const Text('—', style: VmsText.meta)
                  : PlateBadge(
                      number: vehicle.vehicleNumber,
                      onTap: () => context.go(AppRoutes.vehicleSection(vehicle.vehicleId, 'driver')),
                    ),
            ),
          ),
          SizedBox(
            width: _actionsW,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VmsButton(
                  label: widget.canManage ? 'Edit' : 'View',
                  small: true,
                  variant: VmsButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.driverEdit(d.id)),
                ),
                if (widget.canManage) ...[
                  const SizedBox(width: 8),
                  VmsButton(
                    label: 'Delete',
                    small: true,
                    variant: VmsButtonVariant.destructiveText,
                    onPressed: () => _confirmDelete(context, d),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonRow() => Container(
        height: VmsSize.row,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VmsColors.divider))),
        child: const Row(
          children: [
            Expanded(child: Align(alignment: Alignment.centerLeft, child: Skeleton(width: 160, height: 18))),
            SizedBox(width: _licenceW, child: Align(alignment: Alignment.centerLeft, child: Skeleton(width: 130))),
            SizedBox(width: _licStatusW, child: Align(alignment: Alignment.centerLeft, child: Skeleton(width: 80))),
            SizedBox(width: _statusW, child: Align(alignment: Alignment.centerLeft, child: Skeleton(width: 60))),
            SizedBox(width: _vehicleW, child: Align(alignment: Alignment.centerLeft, child: Skeleton(width: 150))),
            SizedBox(width: _actionsW),
          ],
        ),
      );

  Widget _pager(Paged<Driver> page) => Padding(
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

  Future<void> _confirmDelete(BuildContext context, Driver d) async {
    final ok = await showVmsConfirm(
      context,
      title: 'Delete ${d.fullName}?',
      message: 'The driver is removed. Vehicles keep their assignment history.',
      confirmLabel: 'Delete',
    );
    if (!ok || !context.mounted) return;
    final result = await _vm.delete(d);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        showVmsToast(context, '${d.fullName} deleted.');
      case Err(:final error) when error.code == 'DRIVER_ASSIGNED':
        showVmsToast(context, error.message, actionLabel: 'Open vehicle', onAction: () {
          final id = asIntOrNull(error.details['vehicleId']);
          if (id != null) context.go(AppRoutes.vehicleSection(id, 'driver'));
        });
      case Err(:final error):
        showVmsToast(context, error.message);
    }
  }
}
