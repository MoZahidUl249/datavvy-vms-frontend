/// Every URL in the app. Features navigate with these constants so no
/// feature needs to import another feature to link to it.
abstract final class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const vehicles = '/vehicles';
  static const vehicleNew = '/vehicles/new';
  static const settings = '/settings';
  static const drivers = '/drivers';
  static const driverNew = '/drivers/new';
  static const documents = '/documents';
  static const maintenance = '/maintenance';

  /// Vehicle page: details, driver, documents and maintenance history.
  static String vehicleDetail(int id) => '/vehicles/$id';

  /// Vehicle page scrolled to a section: `driver`, `documents`, `maintenance`.
  static String vehicleSection(int id, String section) => '/vehicles/$id?section=$section';

  static String vehicleEdit(int id) => '/vehicles/$id/edit';

  static String driverEdit(int id) => '/drivers/$id';

  /// Driver list filtered: `assigned` true/false, `status` ACTIVE / ON_LEAVE / INACTIVE.
  static String driversWhere({bool? assigned, String? status}) {
    final query = <String, String>{
      if (assigned != null) 'assigned': '$assigned',
      if (status != null) 'status': status,
    };
    return Uri(path: drivers, queryParameters: query.isEmpty ? null : query).toString();
  }

  /// Document list filtered by expiry: `attention` (expired + expiring soon), `EXPIRED`,
  /// `EXPIRING_SOON`, `VALID`, `NO_EXPIRY`.
  static String documentsWhere({String? expiry}) =>
      Uri(path: documents, queryParameters: expiry == null ? null : {'expiry': expiry}).toString();

  /// Vehicle list with optional filters (`status`: ACTIVE / INACTIVE / MAINTENANCE).
  static String vehiclesWhere({String? status, int? saved}) {
    final query = <String, String>{
      if (status != null) 'status': status,
      if (saved != null) 'saved': '$saved',
    };
    return Uri(path: vehicles, queryParameters: query.isEmpty ? null : query).toString();
  }

  /// Settings scrolled to a section: `types`, `columns`, `cards`.
  static String settingsSection(String section) => '$settings?section=$section';
}
