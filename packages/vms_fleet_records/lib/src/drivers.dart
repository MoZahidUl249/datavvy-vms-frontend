import 'package:vms_core/vms_core.dart';

import 'expiry.dart';
import 'paged.dart';

/// `DriverStatus` in the contract. Only ACTIVE drivers can be assigned.
enum DriverStatus {
  active('ACTIVE', 'Active'),
  onLeave('ON_LEAVE', 'On leave'),
  inactive('INACTIVE', 'Inactive');

  const DriverStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static DriverStatus fromApi(Object? value) =>
      DriverStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => DriverStatus.active);
}

/// `Driver.assignedVehicle`.
class AssignedVehicle {
  const AssignedVehicle({required this.vehicleId, required this.vehicleNumber, required this.assignedAt});

  factory AssignedVehicle.fromJson(Map<String, dynamic> j) => AssignedVehicle(
        vehicleId: asInt(j['vehicleId']),
        vehicleNumber: asString(j['vehicleNumber']),
        assignedAt: asDateTime(j['assignedAt']),
      );

  final int vehicleId;
  final String vehicleNumber;
  final DateTime? assignedAt;
}

/// `Driver` schema.
class Driver {
  const Driver({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.licenseStatus,
    required this.licenseDaysLeft,
    required this.address,
    required this.joinedOn,
    required this.status,
    required this.notes,
    required this.assignedVehicle,
    required this.version,
  });

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
        id: asInt(j['id']),
        fullName: asString(j['fullName']),
        phone: asString(j['phone']),
        licenseNumber: asString(j['licenseNumber']),
        licenseExpiry: asDate(j['licenseExpiry']),
        licenseStatus: ExpiryStatus.fromApi(j['licenseStatus']),
        licenseDaysLeft: asIntOrNull(j['licenseDaysLeft']),
        address: asStringOrNull(j['address']),
        joinedOn: asDate(j['joinedOn']),
        status: DriverStatus.fromApi(j['status']),
        notes: asStringOrNull(j['notes']),
        assignedVehicle: j['assignedVehicle'] is Map ? AssignedVehicle.fromJson(asMap(j['assignedVehicle'])) : null,
        version: asInt(j['version']),
      );

  final int id;
  final String fullName;
  final String phone;
  final String licenseNumber;
  final DateTime? licenseExpiry;
  final ExpiryStatus licenseStatus;
  final int? licenseDaysLeft;
  final String? address;
  final DateTime? joinedOn;
  final DriverStatus status;
  final String? notes;
  final AssignedVehicle? assignedVehicle;
  final int version;

  /// Why this driver can't take a vehicle right now, or null if they can.
  String? get notAssignableReason {
    if (status != DriverStatus.active) return status.label;
    if (licenseStatus == ExpiryStatus.expired) return 'Licence expired';
    return null;
  }
}

/// `DriverSummary` schema (the driver inside a vehicle assignment).
class DriverSummary {
  const DriverSummary({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.licenseStatus,
    required this.status,
  });

  factory DriverSummary.fromJson(Map<String, dynamic> j) => DriverSummary(
        id: asInt(j['id']),
        fullName: asString(j['fullName']),
        phone: asString(j['phone']),
        licenseNumber: asString(j['licenseNumber']),
        licenseExpiry: asDate(j['licenseExpiry']),
        licenseStatus: ExpiryStatus.fromApi(j['licenseStatus']),
        status: DriverStatus.fromApi(j['status']),
      );

  final int id;
  final String fullName;
  final String phone;
  final String licenseNumber;
  final DateTime? licenseExpiry;
  final ExpiryStatus licenseStatus;
  final DriverStatus status;
}

/// `VehicleAssignment` schema: a vehicle's current driver (null = none).
class VehicleAssignment {
  const VehicleAssignment({required this.vehicleId, required this.driver, required this.assignedAt, required this.assignedBy});

  factory VehicleAssignment.fromJson(Map<String, dynamic> j) => VehicleAssignment(
        vehicleId: asInt(j['vehicleId']),
        driver: j['driver'] is Map ? DriverSummary.fromJson(asMap(j['driver'])) : null,
        assignedAt: asDateTime(j['assignedAt']),
        assignedBy: asStringOrNull(j['assignedBy']),
      );

  final int vehicleId;
  final DriverSummary? driver;
  final DateTime? assignedAt;
  final String? assignedBy;
}

/// `AssignmentRecord` schema: one row of assignment history.
class AssignmentRecord {
  const AssignmentRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.driverId,
    required this.driverName,
    required this.assignedAt,
    required this.assignedBy,
    required this.releasedAt,
    required this.releasedBy,
  });

  factory AssignmentRecord.fromJson(Map<String, dynamic> j) => AssignmentRecord(
        id: asInt(j['id']),
        vehicleId: asInt(j['vehicleId']),
        vehicleNumber: asString(j['vehicleNumber']),
        driverId: asInt(j['driverId']),
        driverName: asString(j['driverName']),
        assignedAt: asDateTime(j['assignedAt']),
        assignedBy: asStringOrNull(j['assignedBy']),
        releasedAt: asDateTime(j['releasedAt']),
        releasedBy: asStringOrNull(j['releasedBy']),
      );

  final int id;
  final int vehicleId;
  final String vehicleNumber;
  final int driverId;
  final String driverName;
  final DateTime? assignedAt;
  final String? assignedBy;
  final DateTime? releasedAt;
  final String? releasedBy;

  bool get isCurrent => releasedAt == null;
}

/// `DriverStats` schema (also inside the dashboard summary).
class DriverStats {
  const DriverStats({
    required this.total,
    required this.active,
    required this.onLeave,
    required this.inactive,
    required this.assigned,
    required this.available,
    required this.licenseExpiringSoon,
    required this.licenseExpired,
  });

  factory DriverStats.fromJson(Map<String, dynamic> j) => DriverStats(
        total: asInt(j['total']),
        active: asInt(j['active']),
        onLeave: asInt(j['onLeave']),
        inactive: asInt(j['inactive']),
        assigned: asInt(j['assigned']),
        available: asInt(j['available']),
        licenseExpiringSoon: asInt(j['licenseExpiringSoon']),
        licenseExpired: asInt(j['licenseExpired']),
      );

  static const empty = DriverStats(
      total: 0, active: 0, onLeave: 0, inactive: 0, assigned: 0, available: 0, licenseExpiringSoon: 0, licenseExpired: 0);

  final int total;
  final int active;
  final int onLeave;
  final int inactive;
  final int assigned;
  final int available;
  final int licenseExpiringSoon;
  final int licenseExpired;
}

/// `DriverRequest` body.
class DriverDraft {
  const DriverDraft({
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.status,
    this.address,
    this.joinedOn,
    this.notes,
  });

  final String fullName;
  final String phone;
  final String licenseNumber;
  final DateTime? licenseExpiry;
  final DriverStatus status;
  final String? address;
  final DateTime? joinedOn;
  final String? notes;

  static String? _clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

  Map<String, Object?> toJson({int? version}) => {
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'licenseNumber': licenseNumber.trim(),
        'licenseExpiry': licenseExpiry == null ? null : isoDate(licenseExpiry!),
        'address': _clean(address),
        'joinedOn': joinedOn == null ? null : isoDate(joinedOn!),
        'status': status.apiValue,
        'notes': _clean(notes),
        if (version != null) 'version': version,
      };
}

/// Assignment filter on the driver list.
enum AssignmentFilter {
  any(null, 'Any vehicle'),
  assigned(true, 'On a vehicle'),
  available(false, 'Without a vehicle');

  const AssignmentFilter(this.apiValue, this.label);
  final bool? apiValue;
  final String label;

  static AssignmentFilter fromQuery(String? value) => switch (value) {
        'true' => AssignmentFilter.assigned,
        'false' => AssignmentFilter.available,
        _ => AssignmentFilter.any,
      };
}

/// Driver list query (`GET /v1/drivers`). [status] null = all statuses.
class DriverQuery {
  const DriverQuery({
    this.status,
    this.assignment = AssignmentFilter.any,
    this.search = '',
    this.sort = 'fullName,asc',
    this.page = 0,
    this.size = 20,
  });

  final DriverStatus? status;
  final AssignmentFilter assignment;
  final String search;
  final String sort;
  final int page;
  final int size;

  DriverQuery copyWith({
    DriverStatus? Function()? status,
    AssignmentFilter? assignment,
    String? search,
    String? sort,
    int? page,
    int? size,
  }) =>
      DriverQuery(
        status: status == null ? this.status : status(),
        assignment: assignment ?? this.assignment,
        search: search ?? this.search,
        sort: sort ?? this.sort,
        page: page ?? this.page,
        size: size ?? this.size,
      );

  Map<String, Object?> toQuery() => {
        'status': status?.apiValue,
        'assigned': assignment.apiValue,
        'q': search.trim(),
        'sort': sort,
        'page': page,
        'size': size,
      };
}

class DriverRepository {
  const DriverRepository(this._api);

  final ApiClient _api;

  Future<Result<Paged<Driver>>> list(DriverQuery query) async =>
      (await _api.get('/v1/drivers', query: query.toQuery())).map((j) => Paged.fromJson(asMap(j), Driver.fromJson));

  Future<Result<DriverStats>> stats() async =>
      (await _api.get('/v1/drivers/stats')).map((j) => DriverStats.fromJson(asMap(j)));

  Future<Result<Driver>> get(int id) async => (await _api.get('/v1/drivers/$id')).map((j) => Driver.fromJson(asMap(j)));

  Future<Result<Driver>> create(DriverDraft draft) async =>
      (await _api.post('/v1/drivers', body: draft.toJson())).map((j) => Driver.fromJson(asMap(j)));

  Future<Result<Driver>> update(int id, DriverDraft draft, {required int version}) async =>
      (await _api.put('/v1/drivers/$id', body: draft.toJson(version: version))).map((j) => Driver.fromJson(asMap(j)));

  Future<Result<void>> delete(int id) async => (await _api.delete('/v1/drivers/$id')).map<void>((_) {});

  Future<Result<List<AssignmentRecord>>> driverHistory(int driverId) async =>
      (await _api.get('/v1/drivers/$driverId/assignments'))
          .map((j) => asList(j).map((e) => AssignmentRecord.fromJson(asMap(e))).toList());

  // -- a vehicle's driver

  Future<Result<VehicleAssignment>> assignment(int vehicleId) async =>
      (await _api.get('/v1/vehicles/$vehicleId/assignment')).map((j) => VehicleAssignment.fromJson(asMap(j)));

  /// Fails with `DRIVER_ASSIGNED_ELSEWHERE` when the driver is on another
  /// vehicle; call again with [reassign] to move them.
  Future<Result<VehicleAssignment>> assign(int vehicleId, int driverId, {bool reassign = false}) async =>
      (await _api.put('/v1/vehicles/$vehicleId/assignment', body: {'driverId': driverId, 'reassign': reassign}))
          .map((j) => VehicleAssignment.fromJson(asMap(j)));

  Future<Result<void>> unassign(int vehicleId) async =>
      (await _api.delete('/v1/vehicles/$vehicleId/assignment')).map<void>((_) {});

  Future<Result<List<AssignmentRecord>>> vehicleHistory(int vehicleId) async =>
      (await _api.get('/v1/vehicles/$vehicleId/assignment/history'))
          .map((j) => asList(j).map((e) => AssignmentRecord.fromJson(asMap(e))).toList());
}
