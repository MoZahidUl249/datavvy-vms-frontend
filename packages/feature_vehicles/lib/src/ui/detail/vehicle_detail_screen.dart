import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import '../../data/vehicle_models.dart';
import '../list/vehicle_table.dart' show statusTone;
import 'vehicle_detail_view_model.dart';

/// The vehicle page: details, current driver, documents with expiry, and
/// maintenance history. `?section=driver|documents|maintenance` scrolls there.
class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({
    super.key,
    required this.createViewModel,
    required this.canManage,
    this.initialSection,
  });

  final VehicleDetailViewModel Function() createViewModel;
  final bool canManage;
  final String? initialSection;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late final VehicleDetailViewModel _vm = widget.createViewModel();
  final _sections = {
    'driver': GlobalKey(),
    'documents': GlobalKey(),
    'maintenance': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _vm.load().then((_) {
      final key = _sections[widget.initialSection];
      if (key == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = key.currentContext;
        if (mounted && target != null && target.mounted) {
          unawaited(Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300)));
        }
      });
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (mounted) showVmsToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final v = _vm.vehicle;
        final crumbs = [
          Crumb('Vehicles', onTap: () => context.go(AppRoutes.vehicles)),
          Crumb(v?.vehicleNumber ?? 'Vehicle'),
        ];
        if (v == null) {
          return VmsPage(crumbs: crumbs, title: 'Vehicle', body: _loadingOrError(context));
        }
        return VmsPage(
          crumbs: crumbs,
          title: v.vehicleNumber,
          subtitle: [v.type, '${v.brand} ${v.model}'.trim(), v.company].where((s) => s.isNotEmpty).join(' · '),
          actions: [
            StatusPill(label: v.status.label, tone: statusTone(v.status)),
            if (widget.canManage)
              VmsButton(
                label: 'Edit vehicle',
                icon: Icons.edit_outlined,
                variant: VmsButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.vehicleEdit(v.id)),
              ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TwoUp(left: _overview(v), right: _driver(context, v)),
              const SizedBox(height: VmsSpace.s4),
              _documents(context, v),
              const SizedBox(height: VmsSpace.s4),
              _maintenance(context, v),
            ],
          ),
        );
      },
    );
  }

  Widget _loadingOrError(BuildContext context) {
    if (_vm.notFound) {
      return VmsCard(
        child: EmptyState(
          icon: Icons.search_off,
          title: "This vehicle doesn't exist",
          message: 'It may have been deleted. Go back to the list to find it.',
          actionLabel: 'Back to vehicles',
          onAction: () => context.go(AppRoutes.vehicles),
        ),
      );
    }
    if (_vm.vehicleError != null) {
      return ErrorBanner(message: _vm.vehicleError!.message, actionLabel: 'Try again', onAction: _vm.load);
    }
    return const VmsCard(
      padding: EdgeInsets.all(VmsSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 220, height: 22),
          SizedBox(height: 16),
          Skeleton(height: 14),
          SizedBox(height: 10),
          Skeleton(height: 14),
          SizedBox(height: 10),
          Skeleton(width: 300, height: 14),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- overview

  Widget _overview(Vehicle v) {
    Widget field(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 130, child: Text(label, style: VmsText.meta)),
              Expanded(child: value),
            ],
          ),
        );
    Text text(String s) => Text(s, style: VmsText.table);
    return VmsCard(
      title: 'Vehicle',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          field('Vehicle number', Align(alignment: Alignment.centerLeft, child: PlateBadge(number: v.vehicleNumber))),
          field('Company', text(v.company)),
          field('Type', text(v.type)),
          field('Brand / model', text('${v.brand} ${v.model}')),
          field('Status', Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(label: v.status.label, tone: statusTone(v.status)),
          )),
          field('Added', Text(formatDate(v.createdAt), style: VmsText.tabular(VmsText.table))),
          field('Last updated', Text(formatDate(v.updatedAt), style: VmsText.tabular(VmsText.table))),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ driver

  Widget _driver(BuildContext context, Vehicle v) {
    final a = _vm.assignment;
    final driver = a?.driver;
    final inactive = v.status == VehicleStatus.inactive;
    final past = _vm.assignmentHistory.where((r) => !r.isCurrent).take(4).toList();
    return KeyedSubtree(
      key: _sections['driver'],
      child: VmsCard(
        title: 'Driver',
        trailing: widget.canManage && !inactive && driver != null
            ? VmsButton(
                label: 'Change',
                small: true,
                variant: VmsButtonVariant.secondary,
                onPressed: () => _assign(context, v, driver.id),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_vm.driverError != null && a == null)
              ErrorBanner(message: _vm.driverError!.message, actionLabel: 'Try again', onAction: _vm.loadAssignment)
            else if (a == null)
              const Skeleton(height: 40)
            else if (driver == null)
              _noDriver(context, v, inactive)
            else ...[
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: VmsColors.infoBg,
                    child: Icon(Icons.person_outline, color: VmsColors.nav),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => context.go(AppRoutes.driverEdit(driver.id)),
                          child: Text(driver.fullName, style: VmsText.section.copyWith(color: VmsColors.primaryAccessible)),
                        ),
                        const SizedBox(height: 2),
                        Text('${driver.phone} · Licence ${driver.licenseNumber}', style: VmsText.secondary),
                      ],
                    ),
                  ),
                  ExpiryPill(
                    status: driver.licenseStatus,
                    daysLeft: driver.licenseExpiry == null
                        ? null
                        : driver.licenseExpiry!.difference(dateOnly(DateTime.now())).inDays,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Licence expires ${formatDate(driver.licenseExpiry)} · assigned ${formatDate(a.assignedAt)}'
                '${a.assignedBy == null ? '' : ' by ${a.assignedBy}'}',
                style: VmsText.meta,
              ),
              if (widget.canManage) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VmsButton(
                    label: 'Unassign',
                    small: true,
                    variant: VmsButtonVariant.destructiveText,
                    onPressed: () => _unassign(context, v, driver.fullName),
                  ),
                ),
              ],
            ],
            if (past.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: VmsColors.divider),
              const SizedBox(height: 12),
              const Text('PREVIOUS DRIVERS', style: VmsText.th),
              const SizedBox(height: 6),
              for (final r in past)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '${r.driverName} · ${formatDate(r.assignedAt)} – ${formatDate(r.releasedAt)}',
                    style: VmsText.tabular(VmsText.secondary),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noDriver(BuildContext context, Vehicle v, bool inactive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inactive ? 'Inactive vehicles have no driver. Set the vehicle to Active to assign one.' : 'No driver assigned.',
          style: VmsText.secondary,
        ),
        if (widget.canManage && !inactive) ...[
          const SizedBox(height: 12),
          VmsButton(label: 'Assign driver', icon: Icons.person_add_alt, onPressed: () => _assign(context, v, null)),
        ],
      ],
    );
  }

  Future<void> _assign(BuildContext context, Vehicle v, int? currentDriverId) async {
    final result = await showAssignDriverDialog(
      context,
      repository: _vm.driverRepository,
      vehicleId: v.id,
      vehicleNumber: v.vehicleNumber,
      currentDriverId: currentDriverId,
    );
    if (result == null) return;
    await _vm.loadAssignment();
    _toast('${result.driver?.fullName ?? 'Driver'} now drives ${v.vehicleNumber}.');
  }

  Future<void> _unassign(BuildContext context, Vehicle v, String name) async {
    final ok = await showVmsConfirm(
      context,
      title: 'Unassign $name?',
      message: '${v.vehicleNumber} will have no driver. The assignment stays in the history.',
      confirmLabel: 'Unassign',
    );
    if (!ok) return;
    final result = await _vm.unassignDriver();
    _toast(result is Ok<void> ? '$name unassigned.' : result.errorOrNull!.message);
  }

  // --------------------------------------------------------------- documents

  Widget _documents(BuildContext context, Vehicle v) {
    final docs = _vm.documents;
    final attention = docs?.where((d) => d.expiryStatus.needsAttention).length ?? 0;
    final missing = _vm.missingDocumentTypes;
    return KeyedSubtree(
      key: _sections['documents'],
      child: VmsCard(
        title: 'Documents',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attention > 0) ...[
              StatusPill(label: '$attention need attention', tone: StatusTone.danger),
              const SizedBox(width: 12),
            ],
            if (widget.canManage)
              VmsButton(
                label: 'Upload',
                icon: Icons.upload_file,
                small: true,
                onPressed: () => _upload(context, v, null),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_vm.documentsError != null && docs == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: ErrorBanner(
                    message: _vm.documentsError!.message, actionLabel: 'Try again', onAction: _vm.loadDocuments),
              )
            else if (docs == null)
              const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 20), child: Skeleton(height: 60))
            else if (docs.isEmpty)
              EmptyState(
                icon: Icons.description_outlined,
                title: 'No documents yet',
                message: 'Upload the registration, tax token, insurance and fitness certificate to track their expiry.',
                actionLabel: widget.canManage ? 'Upload document' : null,
                onAction: () => _upload(context, v, null),
              )
            else
              for (final d in docs) _documentRow(context, v, d),
            if (docs != null && docs.isNotEmpty && missing.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: VmsColors.divider))),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Missing:', style: VmsText.meta),
                    for (final t in missing)
                      widget.canManage
                          ? VmsButton(
                              label: t.label,
                              icon: Icons.add,
                              small: true,
                              variant: VmsButtonVariant.text,
                              onPressed: () => _upload(context, v, t),
                            )
                          : VmsChip(label: t.label),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _documentRow(BuildContext context, Vehicle v, VehicleDocument d) {
    final line = [
      if (d.documentNumber != null) d.documentNumber!,
      if (d.issueDate != null) 'issued ${formatDate(d.issueDate)}',
      '${d.fileName} · ${formatFileSize(d.sizeBytes)}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: VmsColors.divider))),
      child: Row(
        children: [
          Icon(d.isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined, color: VmsColors.textMeta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.displayName, style: VmsText.section),
                const SizedBox(height: 2),
                Text(line, style: VmsText.secondary, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.expiryDate == null ? 'No expiry' : formatDate(d.expiryDate),
                    style: VmsText.tabular(VmsText.table)),
                const SizedBox(height: 2),
                Text(describeExpiry(d.expiryStatus, d.daysUntilExpiry), style: VmsText.meta),
              ],
            ),
          ),
          SizedBox(width: 130, child: Align(alignment: Alignment.centerLeft, child: ExpiryPill(status: d.expiryStatus, daysLeft: d.daysUntilExpiry))),
          VmsIconButton(
            icon: Icons.visibility_outlined,
            tooltip: 'View ${d.displayName}',
            bordered: false,
            onPressed: () => _openFile(d, download: false),
          ),
          VmsIconButton(
            icon: Icons.download_outlined,
            tooltip: 'Download ${d.fileName}',
            bordered: false,
            onPressed: () => _openFile(d, download: true),
          ),
          if (widget.canManage)
            PopupMenuButton<String>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_horiz, color: VmsColors.textSecondary),
              onSelected: (action) => switch (action) {
                'edit' => _upload(context, v, null, existing: d),
                'replace' => _replace(d),
                _ => _deleteDocument(context, d),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit details / renew')),
                PopupMenuItem(value: 'replace', child: Text('Replace file')),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: VmsColors.danger))),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _upload(BuildContext context, Vehicle v, DocumentType? type, {VehicleDocument? existing}) async {
    final saved = await showDocumentDialog(
      context,
      repository: _vm.documentRepository,
      vehicleId: v.id,
      vehicleNumber: v.vehicleNumber,
      existing: existing,
      initialType: type,
    );
    if (saved == null) return;
    await _vm.loadDocuments();
    _toast(existing == null ? '${saved.displayName} uploaded.' : '${saved.displayName} updated.');
  }

  Future<void> _replace(VehicleDocument d) async {
    final file = await pickFile(accept: documentFileAccept);
    if (file == null) return;
    final result = await _vm.replaceFile(d, file);
    _toast(switch (result) {
      Ok() => 'File replaced. Update the expiry date if the paper was renewed.',
      Err(:final error) => error.fieldErrors['file'] ?? error.message,
    });
  }

  Future<void> _deleteDocument(BuildContext context, VehicleDocument d) async {
    final ok = await showVmsConfirm(
      context,
      title: 'Delete ${d.displayName}?',
      message: 'The document and its file are removed permanently.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    final result = await _vm.deleteDocument(d);
    _toast(result is Ok<void> ? '${d.displayName} deleted.' : result.errorOrNull!.message);
  }

  Future<void> _openFile(VehicleDocument d, {required bool download}) async {
    final result = await _vm.fileOf(d);
    switch (result) {
      case Ok(:final value):
        if (download) {
          saveBytes(value, fileName: d.fileName, contentType: d.contentType);
        } else {
          openBytes(value, contentType: d.contentType);
        }
      case Err(:final error):
        _toast(error.message);
    }
  }

  // ------------------------------------------------------------- maintenance

  Widget _maintenance(BuildContext context, Vehicle v) {
    final s = _vm.maintenanceSummary;
    final page = _vm.maintenancePage;
    return KeyedSubtree(
      key: _sections['maintenance'],
      child: VmsCard(
        title: 'Maintenance history',
        trailing: widget.canManage
            ? VmsButton(
                label: 'Record maintenance',
                icon: Icons.build_outlined,
                small: true,
                onPressed: () => _recordMaintenance(context, v),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s != null && s.recordCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Wrap(
                  spacing: VmsSpace.s5,
                  runSpacing: 8,
                  children: [
                    _stat('Records', '${s.recordCount}'),
                    _stat('Total cost', formatTaka(s.totalCost)),
                    _stat('Last 12 months', formatTaka(s.costLast12Months)),
                    _stat('Last service',
                        '${formatDate(s.lastServiceDate)}${s.lastServiceType == null ? '' : ' · ${s.lastServiceType!.label}'}'),
                    if (s.lastOdometerKm != null) _stat('Odometer', '${s.lastOdometerKm} km'),
                  ],
                ),
              ),
            if (_vm.maintenanceError != null && page == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: ErrorBanner(
                    message: _vm.maintenanceError!.message, actionLabel: 'Try again', onAction: _vm.loadMaintenance),
              )
            else if (page == null)
              const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 20), child: Skeleton(height: 60))
            else if (page.items.isEmpty)
              EmptyState(
                icon: Icons.build_outlined,
                title: 'No maintenance recorded',
                message: 'Record services and repairs to build this vehicle\'s history and cost.',
                actionLabel: widget.canManage ? 'Record maintenance' : null,
                onAction: () => _recordMaintenance(context, v),
              )
            else ...[
              _maintenanceHeader(),
              for (final r in page.items) _maintenanceRow(context, v, r),
              if (page.totalPages > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    children: [
                      Expanded(child: Text(page.rangeLabel, style: VmsText.tabular(VmsText.meta))),
                      VmsButton(
                        label: 'Newer',
                        small: true,
                        variant: VmsButtonVariant.secondary,
                        onPressed: page.hasPrevious ? _vm.previousMaintenancePage : null,
                      ),
                      const SizedBox(width: 8),
                      VmsButton(
                        label: 'Older',
                        small: true,
                        variant: VmsButtonVariant.secondary,
                        onPressed: page.hasNext ? _vm.nextMaintenancePage : null,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: VmsText.meta),
          const SizedBox(height: 2),
          Text(value, style: VmsText.tabular(VmsText.section)),
        ],
      );

  static const _dateW = 120.0, _typeW = 150.0, _odoW = 110.0, _costW = 120.0, _actW = 48.0;

  Widget _maintenanceHeader() => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: VmsColors.surfaceSubtle,
          border: Border(top: BorderSide(color: VmsColors.divider), bottom: BorderSide(color: VmsColors.divider)),
        ),
        child: const Row(
          children: [
            SizedBox(width: _dateW, child: Text('DATE', style: VmsText.th)),
            SizedBox(width: _typeW, child: Text('TYPE', style: VmsText.th)),
            Expanded(child: Text('WORKSHOP / NOTES', style: VmsText.th)),
            SizedBox(width: _odoW, child: Text('ODOMETER', style: VmsText.th, textAlign: TextAlign.right)),
            SizedBox(width: _costW, child: Text('COST', style: VmsText.th, textAlign: TextAlign.right)),
            SizedBox(width: _actW),
          ],
        ),
      );

  Widget _maintenanceRow(BuildContext context, Vehicle v, MaintenanceRecord r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VmsColors.divider))),
      child: Row(
        children: [
          SizedBox(width: _dateW, child: Text(formatDate(r.serviceDate), style: VmsText.tabular(VmsText.table))),
          SizedBox(width: _typeW, child: Text(r.type.label, style: VmsText.table)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.vendor, style: VmsText.table, overflow: TextOverflow.ellipsis),
                if (r.notes != null) Text(r.notes!, style: VmsText.meta, maxLines: 2, overflow: TextOverflow.ellipsis),
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
          SizedBox(
            width: _actW,
            child: widget.canManage
                ? PopupMenuButton<String>(
                    tooltip: 'More actions',
                    icon: const Icon(Icons.more_horiz, color: VmsColors.textSecondary),
                    onSelected: (action) => action == 'edit'
                        ? _recordMaintenance(context, v, existing: r)
                        : _deleteMaintenance(context, r),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: VmsColors.danger))),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _recordMaintenance(BuildContext context, Vehicle v, {MaintenanceRecord? existing}) async {
    final saved = await showMaintenanceDialog(
      context,
      repository: _vm.maintenanceRepository,
      vehicleId: v.id,
      vehicleNumber: v.vehicleNumber,
      existing: existing,
      lastOdometerKm: _vm.maintenanceSummary?.lastOdometerKm,
    );
    if (saved == null) return;
    await _vm.loadMaintenance();
    _toast(existing == null ? '${saved.type.label} recorded.' : 'Record updated.');
  }

  Future<void> _deleteMaintenance(BuildContext context, MaintenanceRecord r) async {
    final ok = await showVmsConfirm(
      context,
      title: 'Delete this record?',
      message: '${r.type.label} on ${formatDate(r.serviceDate)} (${formatTaka(r.cost)}) is removed from the history.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    final result = await _vm.deleteMaintenance(r);
    _toast(result is Ok<void> ? 'Record deleted.' : result.errorOrNull!.message);
  }
}

/// Two cards side by side on wide screens, stacked on narrow ones.
class _TwoUp extends StatelessWidget {
  const _TwoUp({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 860) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: VmsSpace.s4), right],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: VmsSpace.s4),
            Expanded(child: right),
          ],
        ),
      );
    });
  }
}
