import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

class MaintenanceViewModel extends ChangeNotifier {
  MaintenanceViewModel({required MaintenanceRepository repository}) : _repository = repository;

  final MaintenanceRepository _repository;
  MaintenanceQuery _query = const MaintenanceQuery();
  Timer? _debounce;
  int _serial = 0;
  bool _disposed = false;

  Paged<MaintenanceRecord>? page;
  MaintenanceStats? stats;
  bool loading = false;
  ApiError? error;

  MaintenanceQuery get query => _query;

  static const sorts = [
    ('serviceDate,desc', 'Newest first'),
    ('serviceDate,asc', 'Oldest first'),
    ('cost,desc', 'Highest cost'),
    ('cost,asc', 'Lowest cost'),
  ];

  bool get hasCriteria =>
      _query.type != null || _query.from != null || _query.to != null || _query.search.trim().isNotEmpty;

  /// Cost of the rows on screen (the server totals are in [stats]).
  double get pageCost => page?.items.fold<double>(0, (sum, r) => sum + r.cost) ?? 0;

  Future<void> load() async {
    final serial = ++_serial;
    loading = true;
    error = null;
    _notify();
    final (list, figures) = await (_repository.search(_query), _repository.stats()).wait;
    if (serial != _serial || _disposed) return;
    loading = false;
    page = list.valueOrNull ?? page;
    stats = figures.valueOrNull ?? stats;
    error = list.errorOrNull;
    _notify();
  }

  void setType(MaintenanceType? type) => _apply(_query.copyWith(type: () => type, page: 0));

  void setFrom(DateTime? d) => _apply(_query.copyWith(from: () => d, page: 0));

  void setTo(DateTime? d) => _apply(_query.copyWith(to: () => d, page: 0));

  void setSort(String sort) => _apply(_query.copyWith(sort: sort, page: 0));

  void setSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _apply(_query.copyWith(search: text, page: 0)));
  }

  void clearAll() => _apply(const MaintenanceQuery());

  void nextPage() {
    if (page?.hasNext ?? false) _apply(_query.copyWith(page: _query.page + 1));
  }

  void previousPage() {
    if (page?.hasPrevious ?? false) _apply(_query.copyWith(page: _query.page - 1));
  }

  void _apply(MaintenanceQuery next) {
    _query = next;
    unawaited(load());
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
