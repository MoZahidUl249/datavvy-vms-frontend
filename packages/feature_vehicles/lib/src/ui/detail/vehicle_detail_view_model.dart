
import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import '../../data/vehicle_models.dart';
import '../../data/vehicle_repository.dart';

/// Everything on the vehicle page: the vehicle, its driver (and history),
/// its documents and its maintenance history. Each section loads and fails
/// on its own, so one slow or broken section never blanks the page.
class VehicleDetailViewModel extends ChangeNotifier {
  VehicleDetailViewModel({
    required this.vehicleId,
    required VehicleRepository vehicles,
    required DocumentRepository documents,
    required MaintenanceRepository maintenance,
    required DriverRepository drivers,
  })  : _vehicles = vehicles,
        documentRepository = documents,
        maintenanceRepository = maintenance,
        driverRepository = drivers;

  final int vehicleId;
  final VehicleRepository _vehicles;
  final DocumentRepository documentRepository;
  final MaintenanceRepository maintenanceRepository;
  final DriverRepository driverRepository;

  static const maintenancePageSize = 8;

  bool _disposed = false;

  Vehicle? vehicle;
  ApiError? vehicleError;
  bool get notFound => vehicleError?.status == 404;

  VehicleAssignment? assignment;
  List<AssignmentRecord> assignmentHistory = const [];
  ApiError? driverError;

  List<VehicleDocument>? documents;
  ApiError? documentsError;

  MaintenanceHistorySummary? maintenanceSummary;
  Paged<MaintenanceRecord>? maintenancePage;
  ApiError? maintenanceError;
  int _maintenancePage = 0;

  /// Standard papers this vehicle has no document for yet.
  List<DocumentType> get missingDocumentTypes {
    final have = {for (final d in documents ?? const <VehicleDocument>[]) d.type};
    return [
      for (final t in const [
        DocumentType.registration,
        DocumentType.taxToken,
        DocumentType.insurance,
        DocumentType.fitness,
      ])
        if (!have.contains(t)) t,
    ];
  }

  Future<void> load() async {
    final result = await _vehicles.get(vehicleId);
    if (_disposed) return;
    vehicle = result.valueOrNull ?? vehicle;
    vehicleError = result.errorOrNull;
    _notify();
    if (vehicle == null) return;
    await (loadAssignment(), loadDocuments(), loadMaintenance()).wait;
  }

  Future<void> loadAssignment() async {
    final (current, history) =
        await (driverRepository.assignment(vehicleId), driverRepository.vehicleHistory(vehicleId)).wait;
    if (_disposed) return;
    assignment = current.valueOrNull ?? assignment;
    assignmentHistory = history.valueOrNull ?? assignmentHistory;
    driverError = current.errorOrNull;
    _notify();
  }

  Future<void> loadDocuments() async {
    final result = await documentRepository.forVehicle(vehicleId);
    if (_disposed) return;
    documents = result.valueOrNull ?? documents;
    documentsError = result.errorOrNull;
    _notify();
  }

  Future<void> loadMaintenance() async {
    final (summary, page) = await (
      maintenanceRepository.summary(vehicleId),
      maintenanceRepository.history(vehicleId, page: _maintenancePage, size: maintenancePageSize),
    ).wait;
    if (_disposed) return;
    maintenanceSummary = summary.valueOrNull ?? maintenanceSummary;
    maintenancePage = page.valueOrNull ?? maintenancePage;
    maintenanceError = page.errorOrNull ?? summary.errorOrNull;
    _notify();
  }

  Future<void> nextMaintenancePage() async {
    if (!(maintenancePage?.hasNext ?? false)) return;
    _maintenancePage++;
    await loadMaintenance();
  }

  Future<void> previousMaintenancePage() async {
    if (!(maintenancePage?.hasPrevious ?? false)) return;
    _maintenancePage--;
    await loadMaintenance();
  }

  Future<Result<void>> unassignDriver() async {
    final result = await driverRepository.unassign(vehicleId);
    if (result is Ok<void>) await loadAssignment();
    return result;
  }

  Future<Result<void>> deleteDocument(VehicleDocument d) async {
    final result = await documentRepository.delete(d.id);
    if (result is Ok<void>) await loadDocuments();
    return result;
  }

  Future<Result<VehicleDocument>> replaceFile(VehicleDocument d, PickedFile file) async {
    final result = await documentRepository.replaceFile(d.id, file);
    if (result is Ok<VehicleDocument>) await loadDocuments();
    return result;
  }

  Future<Result<Uint8List>> fileOf(VehicleDocument d) => documentRepository.fileBytes(d.id);

  Future<Result<void>> deleteMaintenance(MaintenanceRecord r) async {
    final result = await maintenanceRepository.delete(r.id);
    if (result is Ok<void>) await loadMaintenance();
    return result;
  }

  Future<Result<void>> deleteVehicle() => _vehicles.delete(vehicleId);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
