import 'package:vms_core/vms_core.dart';

/// The API's `PageResponse` envelope for any item type.
class Paged<T> {
  const Paged({required this.items, required this.page, required this.size, required this.total, required this.totalPages});

  factory Paged.fromJson(Map<String, dynamic> j, T Function(Map<String, dynamic>) item) => Paged(
        items: asList(j['content']).map((e) => item(asMap(e))).toList(),
        page: asInt(j['page']),
        size: asInt(j['size'], 20),
        total: asInt(j['totalElements']),
        totalPages: asInt(j['totalPages']),
      );

  final List<T> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;

  /// `Showing 21–40 of 57`
  String get rangeLabel {
    if (items.isEmpty) return 'No results';
    final from = page * size + 1;
    return 'Showing $from–${from + items.length - 1} of $total';
  }
}
