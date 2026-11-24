import 'package:vms_core/vms_core.dart';

import 'paged.dart';

/// `MaintenanceType` in the contract.
enum MaintenanceType {
  routineService('ROUTINE_SERVICE', 'Routine service'),
  oilChange('OIL_CHANGE', 'Oil change'),
  tyres('TYRES', 'Tyres'),
  battery('BATTERY', 'Battery'),
  brakes('BRAKES', 'Brakes'),
  engine('ENGINE', 'Engine'),
  electrical('ELECTRICAL', 'Electrical'),
  bodyWork('BODY_WORK', 'Body work'),
  inspection('INSPECTION', 'Inspection'),
  repair('REPAIR', 'Repair'),
  other('OTHER', 'Other');

  const MaintenanceType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static MaintenanceType fromApi(Object? value) =>
      MaintenanceType.values.firstWhere((t) => t.apiValue == value, orElse: () => MaintenanceType.other);
}

/// `MaintenanceRecord` schema.
class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.serviceDate,
    required this.type,
    required this.cost,
    required this.vendor,
    required this.odometerKm,
    required this.notes,
    required this.createdBy,
    required this.version,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> j) => MaintenanceRecord(
        id: asInt(j['id']),
        vehicleId: asInt(j['vehicleId']),
        vehicleNumber: asStringOrNull(j['vehicleNumber']),
        serviceDate: asDate(j['serviceDate']),
        type: MaintenanceType.fromApi(j['type']),
        cost: asDouble(j['cost']),
        vendor: asString(j['vendor']),
        odometerKm: asIntOrNull(j['odometerKm']),
        notes: asStringOrNull(j['notes']),
        createdBy: asStringOrNull(j['createdBy']),
        version: asInt(j['version']),
      );

  final int id;
  final int vehicleId;
  final String? vehicleNumber;
  final DateTime? serviceDate;
  final MaintenanceType type;
  final double cost;
  final String vendor;
  final int? odometerKm;
  final String? notes;
  final String? createdBy;
  final int version;
}

/// `MaintenanceHistorySummary` schema: the header of a vehicle's history.
class MaintenanceHistorySummary {
  const MaintenanceHistorySummary({
    required this.recordCount,
    required this.totalCost,
    required this.costLast12Months,
    required this.lastServiceDate,
    required this.lastServiceType,
    required this.lastOdometerKm,
  });

  factory MaintenanceHistorySummary.fromJson(Map<String, dynamic> j) => MaintenanceHistorySummary(
        recordCount: asInt(j['recordCount']),
        totalCost: asDouble(j['totalCost']),
        costLast12Months: asDouble(j['costLast12Months']),
        lastServiceDate: asDate(j['lastServiceDate']),
        lastServiceType: j['lastServiceType'] == null ? null : MaintenanceType.fromApi(j['lastServiceType']),
        lastOdometerKm: asIntOrNull(j['lastOdometerKm']),
      );

  final int recordCount;
  final double totalCost;
  final double costLast12Months;
  final DateTime? lastServiceDate;
  final MaintenanceType? lastServiceType;
  final int? lastOdometerKm;
}

class MonthCost {
  const MonthCost({required this.month, required this.count, required this.cost});

  factory MonthCost.fromJson(Map<String, dynamic> j) =>
      MonthCost(month: asString(j['month']), count: asInt(j['count']), cost: asDouble(j['cost']));

  /// `YYYY-MM`
  final String month;
  final int count;
  final double cost;

  static const _short = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// `Nov` (or `Nov 26` with [withYear]).
  String label({bool withYear = false}) {
    final parts = month.split('-');
    final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (m == null || m < 1 || m > 12) return month;
    return withYear ? '${_short[m - 1]} ${parts[0].substring(2)}' : _short[m - 1];
  }
}

class TypeCost {
  const TypeCost({required this.type, required this.count, required this.cost});

  factory TypeCost.fromJson(Map<String, dynamic> j) =>
      TypeCost(type: MaintenanceType.fromApi(j['type']), count: asInt(j['count']), cost: asDouble(j['cost']));

  final MaintenanceType type;
  final int count;
  final double cost;
}

/// `MaintenanceStats` schema (also inside the dashboard summary).
class MaintenanceStats {
  const MaintenanceStats({
    required this.totalRecords,
    required this.totalCost,
    required this.recordsThisMonth,
    required this.costThisMonth,
    required this.vehiclesServicedLast30Days,
    required this.byMonth,
    required this.byType,
  });

  factory MaintenanceStats.fromJson(Map<String, dynamic> j) => MaintenanceStats(
        totalRecords: asInt(j['totalRecords']),
        totalCost: asDouble(j['totalCost']),
        recordsThisMonth: asInt(j['recordsThisMonth']),
        costThisMonth: asDouble(j['costThisMonth']),
        vehiclesServicedLast30Days: asInt(j['vehiclesServicedLast30Days']),
        byMonth: asList(j['byMonth']).map((e) => MonthCost.fromJson(asMap(e))).toList(),
        byType: asList(j['byType']).map((e) => TypeCost.fromJson(asMap(e))).toList(),
      );

  final int totalRecords;
  final double totalCost;
  final int recordsThisMonth;
  final double costThisMonth;
  final int vehiclesServicedLast30Days;
  final List<MonthCost> byMonth;
  final List<TypeCost> byType;
}

/// `MaintenanceRequest` body.
class MaintenanceDraft {
  const MaintenanceDraft({
    required this.serviceDate,
    required this.type,
    required this.cost,
    required this.vendor,
    this.odometerKm,
    this.notes,
  });

  final DateTime? serviceDate;
  final MaintenanceType? type;

  /// As typed; the API validates it (number ≥ 0, 2 decimals).
  final String cost;
  final String vendor;
  final int? odometerKm;
  final String? notes;

  Map<String, Object?> toJson({int? version}) => {
        'serviceDate': serviceDate == null ? null : isoDate(serviceDate!),
        'type': type?.apiValue,
        'cost': num.tryParse(cost.replaceAll(',', '').trim()),
        'vendor': vendor.trim(),
        'odometerKm': odometerKm,
        'notes': notes == null || notes!.trim().isEmpty ? null : notes!.trim(),
        if (version != null) 'version': version,
      };
}

/// Fleet maintenance log query (`GET /v1/maintenance`).
class MaintenanceQuery {
  const MaintenanceQuery({
    this.type,
    this.from,
    this.to,
    this.search = '',
    this.sort = 'serviceDate,desc',
    this.page = 0,
    this.size = 20,
  });

  final MaintenanceType? type;
  final DateTime? from;
  final DateTime? to;
  final String search;
  final String sort;
  final int page;
  final int size;

  MaintenanceQuery copyWith({
    MaintenanceType? Function()? type,
    DateTime? Function()? from,
    DateTime? Function()? to,
    String? search,
    String? sort,
    int? page,
  }) =>
      MaintenanceQuery(
        type: type == null ? this.type : type(),
        from: from == null ? this.from : from(),
        to: to == null ? this.to : to(),
        search: search ?? this.search,
        sort: sort ?? this.sort,
        page: page ?? this.page,
        size: size,
      );

  Map<String, Object?> toQuery() => {
        'type': type?.apiValue,
        'from': from == null ? null : isoDate(from!),
        'to': to == null ? null : isoDate(to!),
        'q': search.trim(),
        'sort': sort,
        'page': page,
        'size': size,
      };
}

class MaintenanceRepository {
  const MaintenanceRepository(this._api);

  final ApiClient _api;

  Future<Result<Paged<MaintenanceRecord>>> history(int vehicleId, {int page = 0, int size = 10}) async =>
      (await _api.get('/v1/vehicles/$vehicleId/maintenance', query: {'page': page, 'size': size}))
          .map((j) => Paged.fromJson(asMap(j), MaintenanceRecord.fromJson));

  Future<Result<MaintenanceHistorySummary>> summary(int vehicleId) async =>
      (await _api.get('/v1/vehicles/$vehicleId/maintenance/summary'))
          .map((j) => MaintenanceHistorySummary.fromJson(asMap(j)));

  Future<Result<Paged<MaintenanceRecord>>> search(MaintenanceQuery query) async =>
      (await _api.get('/v1/maintenance', query: query.toQuery()))
          .map((j) => Paged.fromJson(asMap(j), MaintenanceRecord.fromJson));

  Future<Result<MaintenanceStats>> stats() async =>
      (await _api.get('/v1/maintenance/stats')).map((j) => MaintenanceStats.fromJson(asMap(j)));

  Future<Result<MaintenanceRecord>> create(int vehicleId, MaintenanceDraft draft) async =>
      (await _api.post('/v1/vehicles/$vehicleId/maintenance', body: draft.toJson()))
          .map((j) => MaintenanceRecord.fromJson(asMap(j)));

  Future<Result<MaintenanceRecord>> update(int id, MaintenanceDraft draft, {required int version}) async =>
      (await _api.put('/v1/maintenance/$id', body: draft.toJson(version: version)))
          .map((j) => MaintenanceRecord.fromJson(asMap(j)));

  Future<Result<void>> delete(int id) async => (await _api.delete('/v1/maintenance/$id')).map<void>((_) {});
}
