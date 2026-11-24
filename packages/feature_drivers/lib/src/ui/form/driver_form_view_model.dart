import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

/// Add / edit driver. Field errors come from the API (`fieldErrors`) and from
/// a few checks done here first so the user sees them before saving.
class DriverFormViewModel extends ChangeNotifier {
  DriverFormViewModel({required DriverRepository repository, this.driverId}) : _repository = repository;

  final DriverRepository _repository;
  final int? driverId;

  bool get isEdit => driverId != null;

  Driver? original;
  List<AssignmentRecord> history = const [];
  bool loading = false;
  bool saving = false;
  ApiError? loadError;
  String? formError;
  Map<String, String> errors = const {};

  // Field values (text fields are owned by the screen's controllers).
  DateTime? licenseExpiry;
  DateTime? joinedOn;
  DriverStatus status = DriverStatus.active;

  bool _disposed = false;

  Future<void> load() async {
    final id = driverId;
    if (id == null) return;
    loading = true;
    _notify();
    final (driver, assignments) = await (_repository.get(id), _repository.driverHistory(id)).wait;
    if (_disposed) return;
    loading = false;
    original = driver.valueOrNull;
    loadError = driver.errorOrNull;
    history = assignments.valueOrNull ?? const [];
    final d = original;
    if (d != null) {
      licenseExpiry = d.licenseExpiry;
      joinedOn = d.joinedOn;
      status = d.status;
    }
    _notify();
  }

  void setLicenseExpiry(DateTime? d) {
    licenseExpiry = d;
    errors = {...errors}..remove('licenseExpiry');
    _notify();
  }

  void setJoinedOn(DateTime? d) {
    joinedOn = d;
    _notify();
  }

  void setStatus(DriverStatus s) {
    status = s;
    _notify();
  }

  static final _mobile = RegExp(r'^(?:\+?880|0)?1[3-9]\d{8}$');

  /// Same rules as the API, checked before the round trip.
  static Map<String, String> check({
    required String fullName,
    required String phone,
    required String licenseNumber,
    required DateTime? licenseExpiry,
  }) {
    final e = <String, String>{};
    if (fullName.trim().isEmpty) e['fullName'] = "Enter the driver's full name, like Md. Rahim Uddin.";
    final digits = phone.replaceAll(RegExp(r'[\s\-().]'), '');
    if (digits.isEmpty) {
      e['phone'] = 'Enter a mobile number, like 01712345678.';
    } else if (!_mobile.hasMatch(digits)) {
      e['phone'] = 'Enter a Bangladeshi mobile number, like 01712345678.';
    }
    final key = licenseNumber.toUpperCase().replaceAll(RegExp(r'[\s\-/]'), '');
    if (key.isEmpty) {
      e['licenseNumber'] = 'Enter the driving licence number, like DK0123456C00001.';
    } else if (!RegExp(r'^[A-Z0-9]{5,30}$').hasMatch(key)) {
      e['licenseNumber'] = 'Use 5–30 letters and digits, as printed on the licence.';
    }
    if (licenseExpiry == null) e['licenseExpiry'] = 'Enter the licence expiry date.';
    return e;
  }

  /// Returns the saved driver, or null with [errors] / [formError] set.
  Future<Driver?> save({
    required String fullName,
    required String phone,
    required String licenseNumber,
    required String address,
    required String notes,
  }) async {
    final local = check(fullName: fullName, phone: phone, licenseNumber: licenseNumber, licenseExpiry: licenseExpiry);
    if (local.isNotEmpty) {
      errors = local;
      formError = null;
      _notify();
      return null;
    }
    saving = true;
    errors = const {};
    formError = null;
    _notify();
    final draft = DriverDraft(
      fullName: fullName,
      phone: phone,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      status: status,
      address: address,
      joinedOn: joinedOn,
      notes: notes,
    );
    final id = driverId;
    final result = id == null
        ? await _repository.create(draft)
        : await _repository.update(id, draft, version: original?.version ?? 0);
    if (_disposed) return null;
    saving = false;
    switch (result) {
      case Ok(:final value):
        original = value;
        _notify();
        return value;
      case Err(:final error):
        errors = error.fieldErrors;
        formError = switch (error.code) {
          'VALIDATION_FAILED' => null,
          'DUPLICATE_LICENSE_NUMBER' => null,
          'STALE_VERSION' => 'Someone else changed this driver. Reload the page and try again.',
          _ => error.message,
        };
        if (error.code == 'DUPLICATE_LICENSE_NUMBER') {
          errors = {'licenseNumber': error.message};
        }
        _notify();
        return null;
    }
  }

  Future<Result<void>> delete() => _repository.delete(driverId!);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
