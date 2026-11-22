import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';

import '../../data/vehicle_models.dart';
import '../../data/vehicle_repository.dart';
import '../../domain/plate.dart';

/// Field keys, used for touched-state, server errors and the error summary.
enum VehicleField { vehicleNumber, company, type, brand, model, status }

/// Register / Edit form state. Validation shows on blur or Save and clears as
/// soon as the value is fixed; duplicates show as soon as the number is complete.
/// The server re-checks everything (duplicate rule lives in VehicleService).
class VehicleFormViewModel extends ChangeNotifier {
  VehicleFormViewModel({required VehicleRepository repository, this.vehicleId}) : _repository = repository;

  final VehicleRepository _repository;

  /// Null = register; otherwise the vehicle being edited.
  final int? vehicleId;

  bool get isEdit => vehicleId != null;

  // ---- field values (course fields)
  PlateParts plate = PlateParts.empty;
  String company = '';
  String? type;
  String brand = '';
  String model = '';
  VehicleStatus status = VehicleStatus.active;

  // ---- status
  bool loading = false;
  bool saving = false;
  bool deleting = false;
  bool submitted = false;
  ApiError? loadError;
  String? bannerError;
  bool staleVersion = false;
  VehicleNumberCheck? duplicate;

  final Set<VehicleField> _touched = {};
  final Map<VehicleField, String> _serverErrors = {};
  Vehicle? _original;
  int _version = 0;
  Timer? _duplicateDebounce;
  bool _disposed = false;

  Vehicle? get original => _original;

  Future<void> load() async {
    final id = vehicleId;
    if (id == null) return;
    loading = true;
    _notify();
    final result = await _repository.get(id);
    loading = false;
    switch (result) {
      case Ok(:final value):
        _fill(value);
      case Err(:final error):
        loadError = error;
    }
    _notify();
  }

  void _fill(Vehicle v) {
    _original = v;
    _version = v.version;
    plate = PlateParts.parse(v.vehicleNumber);
    company = v.company;
    type = v.type;
    brand = v.brand;
    model = v.model;
    status = v.status;
    staleVersion = false;
    duplicate = null;
    _serverErrors.clear();
  }

  /// Edit: Save stays disabled ("No changes") until something differs.
  bool get hasChanges {
    final o = _original;
    if (o == null) return true;
    return plate.value != o.vehicleNumber ||
        company.trim() != o.company ||
        type != o.type ||
        brand.trim() != o.brand ||
        model.trim() != o.model ||
        status != o.status;
  }

  // ---- setters (each clears that field's server error)

  void setPlate(PlateParts value) {
    if (value == plate) return;
    plate = value;
    _serverErrors.remove(VehicleField.vehicleNumber);
    duplicate = null;
    _scheduleDuplicateCheck();
    _notify();
  }

  void setCompany(String v) => _set(VehicleField.company, () => company = v);
  void setType(String? v) => _set(VehicleField.type, () => type = v);
  void setBrand(String v) => _set(VehicleField.brand, () => brand = v);
  void setModel(String v) => _set(VehicleField.model, () => model = v);
  void setStatus(VehicleStatus v) => _set(VehicleField.status, () => status = v);

  void touch(VehicleField field) {
    if (_touched.add(field)) _notify();
  }

  void _set(VehicleField field, void Function() apply) {
    apply();
    _serverErrors.remove(field);
    _notify();
  }

  // ---- validation (mirrors VehicleRequest bean validation)

  String? _rule(VehicleField field) => switch (field) {
        VehicleField.vehicleNumber => plate.firstProblem,
        VehicleField.company => _required(company, 100, 'Enter the company, like Datavvy Logistics.'),
        VehicleField.type => type == null ? 'Choose a vehicle type, like Microbus.' : null,
        VehicleField.brand => _required(brand, 60, 'Enter the brand, like Toyota.'),
        VehicleField.model => _required(model, 60, 'Enter the model, like Hiace.'),
        VehicleField.status => null,
      };

  static String? _required(String value, int max, String message) {
    final v = value.trim();
    if (v.isEmpty) return message;
    if (v.length > max) return 'Keep it under $max characters.';
    return null;
  }

  /// Message to show under a field right now (respects blur/submit timing).
  String? errorFor(VehicleField field) {
    final server = _serverErrors[field];
    if (server != null) return server;
    if (field == VehicleField.vehicleNumber && duplicate != null && !duplicate!.available) {
      return 'A vehicle with number ${duplicate!.existingVehicleNumber ?? plate.value} already exists.';
    }
    if (!submitted && !_touched.contains(field)) return null;
    return _rule(field);
  }

  /// All current problems, in form order (for the summary at the top).
  List<(VehicleField, String)> get problems => [
        for (final f in VehicleField.values)
          if (errorFor(f) case final message?) (f, message),
      ];

  // ---- live duplicate check (the server is still the authority)

  void _scheduleDuplicateCheck() {
    _duplicateDebounce?.cancel();
    if (!plate.isComplete) return;
    final number = plate.value;
    _duplicateDebounce = Timer(const Duration(milliseconds: 350), () async {
      final result = await _repository.checkNumber(number, excludeId: vehicleId);
      if (_disposed || plate.value != number) return;
      duplicate = result.valueOrNull;
      _notify();
    });
  }

  // ---- commands

  /// Returns the saved vehicle, or null when something needs fixing.
  Future<Vehicle?> save() async {
    submitted = true;
    bannerError = null;
    if (problems.isNotEmpty || (isEdit && !hasChanges)) {
      _notify();
      return null;
    }
    saving = true;
    _notify();

    final draft = VehicleDraft(
      vehicleNumber: plate.value,
      company: company,
      type: type,
      brand: brand,
      model: model,
      status: status,
    );
    final id = vehicleId;
    final result = id == null ? await _repository.create(draft) : await _repository.update(id, draft, version: _version);
    saving = false;

    switch (result) {
      case Ok(:final value):
        _notify();
        return value;
      case Err(:final error):
        _handleSaveError(error);
        _notify();
        return null;
    }
  }

  void _handleSaveError(ApiError error) {
    switch (error.code) {
      case 'DUPLICATE_VEHICLE_NUMBER':
        duplicate = VehicleNumberCheck(
          valid: true,
          available: false,
          existingId: asIntOrNull(error.details['existingId']),
          existingVehicleNumber: asStringOrNull(error.details['vehicleNumber']) ?? plate.value,
        );
      case 'STALE_VERSION':
        staleVersion = true;
        bannerError = 'Someone else changed this vehicle while you were editing. Reload to see their changes.';
      case 'VALIDATION_FAILED':
        error.fieldErrors.forEach((key, message) {
          final field = VehicleField.values.where((f) => f.name == key).firstOrNull;
          if (field != null) _serverErrors[field] = message;
        });
        if (_serverErrors.isEmpty) bannerError = error.message;
      default:
        bannerError = error.message;
    }
  }

  Future<void> reload() async {
    staleVersion = false;
    bannerError = null;
    await load();
  }

  Future<Result<void>> delete() async {
    final id = vehicleId;
    if (id == null) return const Ok(null);
    deleting = true;
    _notify();
    final result = await _repository.delete(id);
    deleting = false;
    _notify();
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _duplicateDebounce?.cancel();
    super.dispose();
  }
}
