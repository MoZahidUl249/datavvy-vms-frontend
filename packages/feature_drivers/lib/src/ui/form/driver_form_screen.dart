import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'driver_form_view_model.dart';

/// Add / edit a driver. Edit also shows the current vehicle and the vehicles
/// this driver has driven. Ctrl/⌘+Enter saves, Esc goes back.
class DriverFormScreen extends StatefulWidget {
  const DriverFormScreen({super.key, required this.createViewModel, required this.canManage});

  final DriverFormViewModel Function() createViewModel;
  final bool canManage;

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  late final DriverFormViewModel _vm = widget.createViewModel();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _licence = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  bool get _readOnly => !widget.canManage;

  @override
  void initState() {
    super.initState();
    _vm.load().then((_) {
      final d = _vm.original;
      if (d == null || !mounted) return;
      _name.text = d.fullName;
      _phone.text = d.phone;
      _licence.text = d.licenseNumber;
      _address.text = d.address ?? '';
      _notes.text = d.notes ?? '';
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    for (final c in [_name, _phone, _licence, _address, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _back() => context.go(AppRoutes.drivers);

  Future<void> _save() async {
    if (_readOnly || _vm.saving) return;
    final saved = await _vm.save(
      fullName: _name.text,
      phone: _phone.text,
      licenseNumber: _licence.text,
      address: _address.text,
      notes: _notes.text,
    );
    if (saved == null || !mounted) return;
    showVmsToast(context, _vm.isEdit ? 'Changes saved.' : '${saved.fullName} added.');
    context.go(AppRoutes.drivers);
  }

  Future<void> _delete() async {
    final name = _vm.original?.fullName ?? 'this driver';
    final ok = await showVmsConfirm(
      context,
      title: 'Delete $name?',
      message: 'The driver is removed. Vehicles keep their assignment history.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    final result = await _vm.delete();
    if (!mounted) return;
    switch (result) {
      case Ok():
        showVmsToast(context, '$name deleted.');
        context.go(AppRoutes.drivers);
      case Err(:final error):
        showVmsToast(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _back,
      },
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final name = _vm.original?.fullName;
          final title = _vm.isEdit ? (_readOnly ? (name ?? 'Driver') : 'Edit driver') : 'Add driver';
          return VmsPage(
            maxWidth: VmsSize.contentForm,
            crumbs: [Crumb('Drivers', onTap: _back), Crumb(_vm.isEdit ? (name ?? 'Driver') : 'Add driver')],
            title: title,
            subtitle: _vm.isEdit ? (name == null ? null : 'Licence, contact and status of $name.') : 'Add someone who drives your vehicles.',
            body: _body(context),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_vm.isEdit && _vm.loadError != null) {
      return _vm.loadError!.status == 404
          ? VmsCard(
              child: EmptyState(
                icon: Icons.search_off,
                title: "This driver doesn't exist",
                message: 'They may have been deleted.',
                actionLabel: 'Back to drivers',
                onAction: _back,
              ),
            )
          : ErrorBanner(message: _vm.loadError!.message, actionLabel: 'Try again', onAction: _vm.load);
    }
    if (_vm.isEdit && _vm.original == null) {
      return const VmsCard(padding: EdgeInsets.all(VmsSpace.s5), child: Skeleton(height: 200));
    }
    final e = _vm.errors;
    final d = _vm.original;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_vm.formError != null) ...[ErrorBanner(message: _vm.formError!), const SizedBox(height: VmsSpace.s4)],
        if (d != null) ...[_assignmentCard(context, d), const SizedBox(height: VmsSpace.s4)],
        VmsCard(
          padding: const EdgeInsets.all(VmsSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Driver', style: VmsText.h2),
              const SizedBox(height: VmsSpace.s3),
              _pair(
                VmsTextField(
                  label: 'Full name',
                  controller: _name,
                  enabled: !_readOnly,
                  hint: 'Md. Rahim Uddin',
                  error: e['fullName'],
                  autofocus: !_vm.isEdit,
                  textCapitalization: TextCapitalization.words,
                ),
                VmsTextField(
                  label: 'Mobile number',
                  controller: _phone,
                  enabled: !_readOnly,
                  hint: '01712345678',
                  keyboardType: TextInputType.phone,
                  error: e['phone'],
                ),
              ),
              const SizedBox(height: VmsSpace.s5),
              const Text('Licence', style: VmsText.h2),
              const SizedBox(height: VmsSpace.s3),
              _pair(
                VmsTextField(
                  label: 'Licence number',
                  controller: _licence,
                  enabled: !_readOnly,
                  hint: 'DK0123456C00001',
                  textCapitalization: TextCapitalization.characters,
                  error: e['licenseNumber'],
                ),
                VmsDateField(
                  label: 'Licence expiry',
                  value: _vm.licenseExpiry,
                  enabled: !_readOnly,
                  error: e['licenseExpiry'],
                  helper: d == null ? 'Drivers with an expired licence can\'t be assigned.' : describeExpiry(d.licenseStatus, d.licenseDaysLeft),
                  onChanged: _vm.setLicenseExpiry,
                ),
              ),
              const SizedBox(height: VmsSpace.s5),
              const Text('Employment', style: VmsText.h2),
              const SizedBox(height: VmsSpace.s3),
              _pair(
                VmsSelect<DriverStatus>(
                  label: 'Status',
                  value: _vm.status,
                  error: e['status'],
                  options: [for (final s in DriverStatus.values) VmsOption(s, s.label)],
                  onChanged: _readOnly
                      ? null
                      : (s) {
                          if (s != null) _vm.setStatus(s);
                        },
                ),
                VmsDateField(
                  label: 'Joined on',
                  optional: true,
                  value: _vm.joinedOn,
                  enabled: !_readOnly,
                  lastDate: DateTime.now(),
                  error: e['joinedOn'],
                  onChanged: _vm.setJoinedOn,
                ),
              ),
              const SizedBox(height: VmsSpace.s3),
              VmsTextField(
                label: 'Address',
                optional: true,
                controller: _address,
                enabled: !_readOnly,
                hint: 'Mirpur 10, Dhaka',
                error: e['address'],
              ),
              const SizedBox(height: VmsSpace.s3),
              VmsTextField(
                label: 'Notes',
                optional: true,
                controller: _notes,
                enabled: !_readOnly,
                error: e['notes'],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              if (!_readOnly) ...[
                const SizedBox(height: VmsSpace.s5),
                Row(
                  children: [
                    if (_vm.isEdit)
                      VmsButton(label: 'Delete driver', variant: VmsButtonVariant.destructiveText, onPressed: _delete),
                    const Spacer(),
                    VmsButton(label: 'Cancel', variant: VmsButtonVariant.secondary, onPressed: _back),
                    const SizedBox(width: VmsSpace.s3),
                    VmsButton(
                      label: _vm.isEdit ? 'Save changes' : 'Add driver',
                      loading: _vm.saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _pair(Widget a, Widget b) => LayoutBuilder(
        builder: (context, c) => c.maxWidth < 560
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [a, const SizedBox(height: VmsSpace.s3), b],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: a), const SizedBox(width: VmsSpace.s4), Expanded(child: b)],
              ),
      );

  Widget _assignmentCard(BuildContext context, Driver d) {
    final vehicle = d.assignedVehicle;
    final past = _vm.history.where((r) => !r.isCurrent).take(6).toList();
    return VmsCard(
      title: 'Vehicle',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vehicle == null)
            Text(
              d.notAssignableReason == null
                  ? 'Not on a vehicle. Assign them from a vehicle\'s page.'
                  : 'Not on a vehicle (${d.notAssignableReason!.toLowerCase()}).',
              style: VmsText.secondary,
            )
          else
            Row(
              children: [
                PlateBadge(
                  number: vehicle.vehicleNumber,
                  onTap: () => context.go(AppRoutes.vehicleSection(vehicle.vehicleId, 'driver')),
                ),
                const SizedBox(width: 12),
                Text('since ${formatDate(vehicle.assignedAt)}', style: VmsText.meta),
              ],
            ),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('PREVIOUSLY DROVE', style: VmsText.th),
            const SizedBox(height: 6),
            for (final r in past)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${r.vehicleNumber} · ${formatDate(r.assignedAt)} – ${formatDate(r.releasedAt)}',
                  style: VmsText.tabular(VmsText.secondary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
