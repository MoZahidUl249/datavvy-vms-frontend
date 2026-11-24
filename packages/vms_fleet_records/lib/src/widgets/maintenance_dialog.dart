import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../maintenance.dart';

/// Record service / repair work for a vehicle, or correct a record
/// ([existing]). Resolves to the saved record, or null when cancelled.
Future<MaintenanceRecord?> showMaintenanceDialog(
  BuildContext context, {
  required MaintenanceRepository repository,
  required int vehicleId,
  required String vehicleNumber,
  MaintenanceRecord? existing,
  int? lastOdometerKm,
}) =>
    showDialog<MaintenanceRecord>(
      context: context,
      builder: (_) => _MaintenanceDialog(
        repository: repository,
        vehicleId: vehicleId,
        vehicleNumber: vehicleNumber,
        existing: existing,
        lastOdometerKm: lastOdometerKm,
      ),
    );

class _MaintenanceDialog extends StatefulWidget {
  const _MaintenanceDialog({
    required this.repository,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.existing,
    required this.lastOdometerKm,
  });

  final MaintenanceRepository repository;
  final int vehicleId;
  final String vehicleNumber;
  final MaintenanceRecord? existing;
  final int? lastOdometerKm;

  @override
  State<_MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<_MaintenanceDialog> {
  late DateTime? _date = widget.existing?.serviceDate ?? dateOnly(DateTime.now());
  late MaintenanceType? _type = widget.existing?.type;
  late final _cost = TextEditingController(text: _initialCost());
  late final _vendor = TextEditingController(text: widget.existing?.vendor ?? '');
  late final _odometer = TextEditingController(text: widget.existing?.odometerKm?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _formError;

  bool get _isEdit => widget.existing != null;

  String _initialCost() {
    final c = widget.existing?.cost;
    if (c == null) return '';
    return c == c.roundToDouble() ? c.toStringAsFixed(0) : c.toStringAsFixed(2);
  }

  @override
  void dispose() {
    for (final c in [_cost, _vendor, _odometer, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _localErrors() {
    final e = <String, String>{};
    if (_date == null) e['serviceDate'] = 'Enter the service date.';
    if (_type == null) e['type'] = 'Choose what was done.';
    final cost = num.tryParse(_cost.text.replaceAll(',', '').trim());
    if (cost == null) {
      e['cost'] = 'Enter the cost in taka, like 4500. Use 0 for free work.';
    } else if (cost < 0) {
      e['cost'] = "The cost can't be negative.";
    }
    if (_vendor.text.trim().isEmpty) e['vendor'] = 'Enter the workshop or vendor.';
    return e;
  }

  Future<void> _save() async {
    final local = _localErrors();
    if (local.isNotEmpty) {
      setState(() => _errors = local);
      return;
    }
    setState(() {
      _saving = true;
      _errors = const {};
      _formError = null;
    });
    final draft = MaintenanceDraft(
      serviceDate: _date,
      type: _type,
      cost: _cost.text,
      vendor: _vendor.text,
      odometerKm: int.tryParse(_odometer.text.replaceAll(',', '').trim()),
      notes: _notes.text,
    );
    final result = _isEdit
        ? await widget.repository.update(widget.existing!.id, draft, version: widget.existing!.version)
        : await widget.repository.create(widget.vehicleId, draft);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final error):
        setState(() {
          _saving = false;
          _errors = error.fieldErrors;
          _formError = switch (error.code) {
            'VALIDATION_FAILED' => null,
            'STALE_VERSION' => 'Someone else changed this record. Close and open it again.',
            _ => error.message,
          };
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return VmsDialog(
      title: _isEdit ? 'Edit maintenance record' : 'Record maintenance',
      subtitle: widget.vehicleNumber,
      actions: [
        VmsButton(
          label: 'Cancel',
          variant: VmsButtonVariant.secondary,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        VmsButton(label: _isEdit ? 'Save changes' : 'Save record', loading: _saving, onPressed: _saving ? null : _save),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_formError != null) ...[
            ErrorBanner(message: _formError!),
            const SizedBox(height: VmsSpace.s4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VmsDateField(
                  label: 'Service date',
                  value: _date,
                  lastDate: DateTime.now(),
                  error: _errors['serviceDate'],
                  onChanged: (d) => setState(() => _date = d),
                ),
              ),
              const SizedBox(width: VmsSpace.s3),
              Expanded(
                child: VmsSelect<MaintenanceType>(
                  label: 'Type',
                  hint: 'What was done',
                  value: _type,
                  error: _errors['type'],
                  options: [for (final t in MaintenanceType.values) VmsOption(t, t.label)],
                  onChanged: _saving ? null : (t) => setState(() => _type = t),
                ),
              ),
            ],
          ),
          const SizedBox(height: VmsSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VmsTextField(
                  label: 'Cost (৳)',
                  controller: _cost,
                  hint: '4500',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: digits,
                  error: _errors['cost'],
                ),
              ),
              const SizedBox(width: VmsSpace.s3),
              Expanded(
                child: VmsTextField(
                  label: 'Odometer (km)',
                  optional: true,
                  controller: _odometer,
                  hint: widget.lastOdometerKm == null ? '84200' : 'Last: ${widget.lastOdometerKm}',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  error: _errors['odometerKm'],
                ),
              ),
            ],
          ),
          const SizedBox(height: VmsSpace.s3),
          VmsTextField(
            label: 'Workshop / vendor',
            controller: _vendor,
            hint: 'Navana Service Centre, Tejgaon',
            error: _errors['vendor'],
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: VmsSpace.s3),
          VmsTextField(
            label: 'Notes',
            optional: true,
            controller: _notes,
            hint: 'Parts replaced, next service due …',
            error: _errors['notes'],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
    );
  }
}
