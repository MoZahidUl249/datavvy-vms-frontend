/// Every URL in the app. Features navigate with these constants so no
/// feature needs to import another feature to link to it.
abstract final class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const vehicles = '/vehicles';
  static const vehicleNew = '/vehicles/new';
  static const settings = '/settings';

  static String vehicleEdit(int id) => '/vehicles/$id';

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
