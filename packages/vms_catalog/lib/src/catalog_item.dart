import 'package:vms_core/vms_core.dart';

enum CatalogKind {
  vehicleType('vehicle-types', 'Vehicle type');

  const CatalogKind(this.slug, this.label);

  /// URL segment: `/v1/catalog/{slug}`.
  final String slug;
  final String label;
}

class CatalogItem {
  const CatalogItem({required this.id, required this.name, this.sortOrder = 0, this.usageCount = 0});

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
        id: asInt(json['id']),
        name: asString(json['name']),
        sortOrder: asInt(json['sortOrder']),
        usageCount: asInt(json['usageCount']),
      );

  final int id;
  final String name;
  final int sortOrder;
  final int usageCount;

  bool get inUse => usageCount > 0;
}
