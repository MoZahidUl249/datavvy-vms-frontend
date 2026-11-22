import 'package:vms_core/vms_core.dart';

/// Course field "Status".
enum VehicleStatus {
  active('ACTIVE', 'Active'),
  inactive('INACTIVE', 'Inactive'),
  maintenance('MAINTENANCE', 'Maintenance');

  const VehicleStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static VehicleStatus fromApi(Object? value) =>
      VehicleStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => VehicleStatus.active);
}

/// Vehicle as returned by the API (`Vehicle` schema in contracts/openapi):
/// Vehicle Number, Company, Type, Brand, Model, Status.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: asInt(j['id']),
        vehicleNumber: asString(j['vehicleNumber']),
        company: asString(j['company']),
        type: asString(j['type']),
        brand: asString(j['brand']),
        model: asString(j['model']),
        status: VehicleStatus.fromApi(j['status']),
        createdAt: asDateTime(j['createdAt']),
        updatedAt: asDateTime(j['updatedAt']),
        version: asInt(j['version']),
      );

  final int id;
  final String vehicleNumber;
  final String company;
  final String type;
  final String brand;
  final String model;
  final VehicleStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;
}

class VehiclePage {
  const VehiclePage({required this.items, required this.page, required this.size, required this.total, required this.totalPages});

  factory VehiclePage.fromJson(Map<String, dynamic> j) => VehiclePage(
        items: asList(j['content']).map((e) => Vehicle.fromJson(asMap(e))).toList(),
        page: asInt(j['page']),
        size: asInt(j['size'], 20),
        total: asInt(j['totalElements']),
        totalPages: asInt(j['totalPages']),
      );

  final List<Vehicle> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

class VehicleFacets {
  const VehicleFacets({
    required this.all,
    required this.active,
    required this.inactive,
    required this.maintenance,
    required this.companies,
    required this.brands,
    required this.updatedDates,
    required this.addedDates,
  });

  factory VehicleFacets.fromJson(Map<String, dynamic> j) {
    final counts = asMap(j['statusCounts']);
    Set<DateTime> dates(String key) => asList(j[key])
        .whereType<String>()
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(dateOnly)
        .toSet();
    return VehicleFacets(
      all: asInt(counts['all']),
      active: asInt(counts['active']),
      inactive: asInt(counts['inactive']),
      maintenance: asInt(counts['maintenance']),
      companies: asList(j['companies']).whereType<String>().toList(),
      brands: asList(j['brands']).whereType<String>().toList(),
      updatedDates: dates('updatedDates'),
      addedDates: dates('addedDates'),
    );
  }

  static const empty = VehicleFacets(
    all: 0,
    active: 0,
    inactive: 0,
    maintenance: 0,
    companies: [],
    brands: [],
    updatedDates: {},
    addedDates: {},
  );

  final int all;
  final int active;
  final int inactive;
  final int maintenance;
  final List<String> companies;
  final List<String> brands;
  final Set<DateTime> updatedDates;
  final Set<DateTime> addedDates;
}

class VehicleNumberCheck {
  const VehicleNumberCheck({required this.valid, required this.available, this.existingId, this.existingVehicleNumber});

  factory VehicleNumberCheck.fromJson(Map<String, dynamic> j) => VehicleNumberCheck(
        valid: asBool(j['valid']),
        available: asBool(j['available']),
        existingId: asIntOrNull(j['existingId']),
        existingVehicleNumber: asStringOrNull(j['existingVehicleNumber']),
      );

  final bool valid;
  final bool available;
  final int? existingId;
  final String? existingVehicleNumber;
}

/// Payload for create / update (`VehicleRequest`).
class VehicleDraft {
  const VehicleDraft({
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
  });

  final String vehicleNumber;
  final String company;
  final String? type;
  final String brand;
  final String model;
  final VehicleStatus status;

  Map<String, Object?> toJson({int? version}) => {
        'vehicleNumber': vehicleNumber,
        'company': company.trim(),
        'type': type,
        'brand': brand.trim(),
        'model': model.trim(),
        'status': status.apiValue,
        if (version != null) 'version': version,
      };
}

/// Status segmented control on the list (adds "All").
enum StatusFilter {
  all(null, 'All'),
  active(VehicleStatus.active, 'Active'),
  inactive(VehicleStatus.inactive, 'Inactive'),
  maintenance(VehicleStatus.maintenance, 'Maintenance');

  const StatusFilter(this.status, this.label);
  final VehicleStatus? status;
  final String label;

  String? get apiValue => status?.apiValue;

  static StatusFilter fromApi(String? value) =>
      StatusFilter.values.firstWhere((s) => s.apiValue == value, orElse: () => StatusFilter.all);
}

/// Filters chosen in the filter panel (draft until "Apply filters").
class VehicleFilters {
  const VehicleFilters({
    this.types = const {},
    this.companies = const {},
    this.brands = const {},
    this.updatedOn,
    this.addedOn,
  });

  static const none = VehicleFilters();

  final Set<String> types;
  final Set<String> companies;
  final Set<String> brands;
  final DateTime? updatedOn;
  final DateTime? addedOn;

  int get count =>
      types.length + companies.length + brands.length + (updatedOn != null ? 1 : 0) + (addedOn != null ? 1 : 0);

  bool get isEmpty => count == 0;

  VehicleFilters copyWith({
    Set<String>? types,
    Set<String>? companies,
    Set<String>? brands,
    DateTime? Function()? updatedOn,
    DateTime? Function()? addedOn,
  }) =>
      VehicleFilters(
        types: types ?? this.types,
        companies: companies ?? this.companies,
        brands: brands ?? this.brands,
        updatedOn: updatedOn != null ? updatedOn() : this.updatedOn,
        addedOn: addedOn != null ? addedOn() : this.addedOn,
      );

  Map<String, Object?> toQuery() => {
        'type': types.toList(),
        'company': companies.toList(),
        'brand': brands.toList(),
        'updatedOn': updatedOn == null ? null : isoDate(updatedOn!),
        'addedOn': addedOn == null ? null : isoDate(addedOn!),
      };
}

class VehicleSort {
  const VehicleSort(this.field, {this.ascending = false});

  final String field;
  final bool ascending;

  static const updatedDesc = VehicleSort('updatedAt');

  /// Options of the Sort select (V8 design).
  static const presets = <(VehicleSort, String)>[
    (VehicleSort('updatedAt'), 'Last updated'),
    (VehicleSort('createdAt'), 'Recently added'),
    (VehicleSort('createdAt', ascending: true), 'Oldest added'),
    (VehicleSort('vehicleNumber', ascending: true), 'Number A–Z'),
    (VehicleSort('vehicleNumber'), 'Number Z–A'),
  ];

  String get apiValue => '$field,${ascending ? 'asc' : 'desc'}';

  VehicleSort toggled() => VehicleSort(field, ascending: !ascending);

  @override
  bool operator ==(Object other) => other is VehicleSort && other.field == field && other.ascending == ascending;

  @override
  int get hashCode => Object.hash(field, ascending);
}

/// Everything that determines one page of the list.
class VehicleQuery {
  const VehicleQuery({
    this.status = StatusFilter.all,
    this.search = '',
    this.filters = VehicleFilters.none,
    this.sort = VehicleSort.updatedDesc,
    this.page = 0,
    this.size = 20,
  });

  final StatusFilter status;
  final String search;
  final VehicleFilters filters;
  final VehicleSort sort;
  final int page;
  final int size;

  VehicleQuery copyWith({
    StatusFilter? status,
    String? search,
    VehicleFilters? filters,
    VehicleSort? sort,
    int? page,
    int? size,
  }) =>
      VehicleQuery(
        status: status ?? this.status,
        search: search ?? this.search,
        filters: filters ?? this.filters,
        sort: sort ?? this.sort,
        page: page ?? this.page,
        size: size ?? this.size,
      );

  Map<String, Object?> toQuery() => {
        'status': status.apiValue,
        'q': search.trim(),
        ...filters.toQuery(),
        'page': page,
        'size': size,
        'sort': sort.apiValue,
      };
}
