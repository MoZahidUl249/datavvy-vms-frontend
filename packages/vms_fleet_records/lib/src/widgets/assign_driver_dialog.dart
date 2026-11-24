import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../drivers.dart';
import '../expiry.dart';
import 'expiry_pill.dart';

/// Pick a driver for a vehicle. Drivers who can't drive (on leave, inactive,
/// licence expired) are shown but disabled with the reason; a driver who is on
/// another vehicle can be moved after confirming. Resolves to the new
/// assignment, or null when cancelled.
Future<VehicleAssignment?> showAssignDriverDialog(
  BuildContext context, {
  required DriverRepository repository,
  required int vehicleId,
  required String vehicleNumber,
  int? currentDriverId,
}) =>
    showDialog<VehicleAssignment>(
      context: context,
      builder: (_) => _AssignDriverDialog(
        repository: repository,
        vehicleId: vehicleId,
        vehicleNumber: vehicleNumber,
        currentDriverId: currentDriverId,
      ),
    );

class _AssignDriverDialog extends StatefulWidget {
  const _AssignDriverDialog({
    required this.repository,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.currentDriverId,
  });

  final DriverRepository repository;
  final int vehicleId;
  final String vehicleNumber;
  final int? currentDriverId;

  @override
  State<_AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends State<_AssignDriverDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Driver>? _drivers;
  ApiError? _loadError;
  int? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.repository.list(DriverQuery(search: _search.text, size: 50));
    if (!mounted) return;
    setState(() {
      _drivers = result.valueOrNull?.items ?? _drivers;
      _loadError = result.errorOrNull;
    });
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => unawaited(_load()));
  }

  Future<void> _choose(Driver driver, {bool reassign = false}) async {
    setState(() {
      _busyId = driver.id;
      _error = null;
    });
    final result = await widget.repository.assign(widget.vehicleId, driver.id, reassign: reassign);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final error) when error.code == 'DRIVER_ASSIGNED_ELSEWHERE' && !reassign:
        setState(() => _busyId = null);
        final from = asString(error.details['vehicleNumber'], 'another vehicle');
        final move = await showVmsConfirm(
          context,
          title: 'Move ${driver.fullName}?',
          message: '${driver.fullName} drives $from. Moving them leaves $from without a driver.',
          confirmLabel: 'Move to ${widget.vehicleNumber}',
          destructive: false,
        );
        if (move && mounted) await _choose(driver, reassign: true);
      case Err(:final error):
        setState(() {
          _busyId = null;
          _error = error.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drivers = _drivers;
    return VmsDialog(
      title: widget.currentDriverId == null ? 'Assign a driver' : 'Change driver',
      subtitle: widget.vehicleNumber,
      maxWidth: 620,
      actions: [
        VmsButton(label: 'Cancel', variant: VmsButtonVariant.secondary, onPressed: () => Navigator.of(context).pop()),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VmsTextField(
            label: 'Search drivers',
            showLabel: false,
            controller: _search,
            hint: 'Name, mobile or licence number',
            prefixIcon: Icons.search,
            autofocus: true,
            onChanged: _onSearch,
          ),
          const SizedBox(height: VmsSpace.s3),
          if (_error != null) ...[ErrorBanner(message: _error!), const SizedBox(height: VmsSpace.s3)],
          if (_loadError != null && drivers == null)
            ErrorBanner(message: _loadError!.message, actionLabel: 'Try again', onAction: _load)
          else if (drivers == null)
            Column(
              children: [
                for (var i = 0; i < 4; i++)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Skeleton(height: 18)),
              ],
            )
          else if (drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: VmsSpace.s5),
              child: Text('No drivers match. Add drivers on the Drivers page.', style: VmsText.meta),
            )
          else
            for (final d in drivers) _row(d),
        ],
      ),
    );
  }

  Widget _row(Driver d) {
    final current = d.id == widget.currentDriverId;
    final reason = current ? 'Current driver' : d.notAssignableReason;
    final elsewhere = d.assignedVehicle != null && !current ? 'Drives ${d.assignedVehicle!.vehicleNumber}' : null;
    final enabled = reason == null && _busyId == null;
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: VmsColors.divider))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.fullName, style: VmsText.section),
                const SizedBox(height: 2),
                Text(
                  [d.phone, d.licenseNumber, if (elsewhere != null) elsewhere].join(' · '),
                  style: VmsText.secondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (d.licenseStatus == ExpiryStatus.expired || d.licenseStatus == ExpiryStatus.expiringSoon) ...[
            ExpiryPill(status: d.licenseStatus, daysLeft: d.licenseDaysLeft),
            const SizedBox(width: VmsSpace.s2),
          ],
          if (reason != null)
            Text(reason, style: VmsText.meta)
          else
            VmsButton(
              label: elsewhere == null ? 'Assign' : 'Move here',
              small: true,
              variant: VmsButtonVariant.secondary,
              loading: _busyId == d.id,
              onPressed: enabled ? () => _choose(d) : null,
            ),
        ],
      ),
    );
  }
}
