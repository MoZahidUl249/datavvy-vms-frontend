import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';

import 'catalog_item.dart';

/// Single source of truth for catalog lists. Features read the cached lists
/// and listen for changes made on the Settings screen.
class CatalogRepository extends ChangeNotifier {
  CatalogRepository(this._api);

  final ApiClient _api;
  final Map<CatalogKind, List<CatalogItem>> _items = {};
  ApiError? _lastError;

  List<CatalogItem> items(CatalogKind kind) => _items[kind] ?? const [];
  bool isLoaded(CatalogKind kind) => _items.containsKey(kind);
  ApiError? get lastError => _lastError;

  String nameOf(CatalogKind kind, int? id) {
    for (final item in items(kind)) {
      if (item.id == id) return item.name;
    }
    return '—';
  }

  /// Loads every list (cheap: a few rows each).
  Future<void> loadAll({bool force = false}) async {
    await Future.wait([for (final k in CatalogKind.values) load(k, force: force)]);
  }

  Future<Result<List<CatalogItem>>> load(CatalogKind kind, {bool force = false}) async {
    if (!force && isLoaded(kind)) return Ok(items(kind));
    final result = (await _api.get('/v1/catalog/${kind.slug}'))
        .map((json) => asList(json).map((e) => CatalogItem.fromJson(asMap(e))).toList());
    switch (result) {
      case Ok(:final value):
        _items[kind] = value;
        _lastError = null;
      case Err(:final error):
        _lastError = error;
    }
    notifyListeners();
    return result;
  }

  Future<Result<CatalogItem>> add(CatalogKind kind, String name) async {
    final result = (await _api.post('/v1/catalog/${kind.slug}', body: {'name': name}))
        .map((json) => CatalogItem.fromJson(asMap(json)));
    if (result is Ok<CatalogItem>) await load(kind, force: true);
    return result;
  }

  Future<Result<void>> remove(CatalogKind kind, int id) async {
    final result = (await _api.delete('/v1/catalog/${kind.slug}/$id')).map<void>((_) {});
    if (result is Ok<void>) await load(kind, force: true);
    return result;
  }
}
