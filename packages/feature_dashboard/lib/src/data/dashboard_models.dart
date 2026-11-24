import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

class DashboardSlice {
  const DashboardSlice({required this.name, required this.count});

  factory DashboardSlice.fromJson(Map<String, dynamic> j) =>
      DashboardSlice(name: asString(j['name']), count: asInt(j['count']));

  final String name;
  final int count;
}

class DashboardVehicle {
  const DashboardVehicle({
    required this.id,
    required this.vehicleNumber,
    required this.company,
    required this.brand,
    required this.model,
    required this.status,
    required this.updatedAt,
  });

  factory DashboardVehicle.fromJson(Map<String, dynamic> j) => DashboardVehicle(
        id: asInt(j['id']),
        vehicleNumber: asString(j['vehicleNumber']),
        company: asString(j['company']),
        brand: asString(j['brand']),
        model: asString(j['model']),
        status: asString(j['status']),
        updatedAt: asDateTime(j['updatedAt']),
      );

  final int id;
  final String vehicleNumber;
  final String company;
  final String brand;
  final String model;

  /// `ACTIVE`, `INACTIVE` or `MAINTENANCE`.
  final String status;
  final DateTime? updatedAt;
}

class DashboardSummary {
  const DashboardSummary({
    required this.total,
    required this.active,
    required this.inactive,
    required this.maintenance,
    required this.byType,
    required this.byBrand,
    required this.recentlyUpdated,
    required this.inMaintenance,
    this.documents,
    this.documentAlerts = const [],
    this.maintenanceStats,
    this.recentMaintenance = const [],
    this.drivers,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    final k = asMap(j['kpis']);
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        asList(j[key]).map((e) => f(asMap(e))).toList();
    return DashboardSummary(
      total: asInt(k['total']),
      active: asInt(k['active']),
      inactive: asInt(k['inactive']),
      maintenance: asInt(k['maintenance']),
      byType: list('byType', DashboardSlice.fromJson),
      byBrand: list('byBrand', DashboardSlice.fromJson),
      recentlyUpdated: list('recentlyUpdated', DashboardVehicle.fromJson),
      inMaintenance: list('inMaintenance', DashboardVehicle.fromJson),
      documents: j['documents'] is Map ? DocumentStats.fromJson(asMap(j['documents'])) : null,
      documentAlerts: list('documentAlerts', DocumentAlert.fromJson),
      maintenanceStats: j['maintenance'] is Map ? MaintenanceStats.fromJson(asMap(j['maintenance'])) : null,
      recentMaintenance: list('recentMaintenance', MaintenanceRecord.fromJson),
      drivers: j['drivers'] is Map ? DriverStats.fromJson(asMap(j['drivers'])) : null,
    );
  }

  final int total;
  final int active;
  final int inactive;
  final int maintenance;
  final List<DashboardSlice> byType;
  final List<DashboardSlice> byBrand;
  final List<DashboardVehicle> recentlyUpdated;
  final List<DashboardVehicle> inMaintenance;

  // Fleet management (null / empty when talking to an older API).
  final DocumentStats? documents;
  final List<DocumentAlert> documentAlerts;
  final MaintenanceStats? maintenanceStats;
  final List<MaintenanceRecord> recentMaintenance;
  final DriverStats? drivers;
}
