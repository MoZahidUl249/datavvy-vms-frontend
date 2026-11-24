import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

/// State + commands behind the Drivers list. Search, filters, sorting and
/// paging all run on the server.
class DriverListViewModel extends ChangeNotifier {
  DriverListViewModel({required DriverRepository repository, DriverQuery initialQuery = const DriverQuery()})
      : _repository = repository,
        _query = initialQuery;

  final DriverRepository _repository;
  DriverQuery _query;
  Timer? _debounce;
  int _serial = 0;
  bool _disposed = false;

  Paged<Driver>? page;
  DriverStats stats = DriverStats.empty;
  bool loading = false;
  ApiError? error;

  DriverQuery get query => _query;

  static const sorts = [
    ('fullName,asc', 'Name A–Z'),
    ('licenseExpiry,asc', 'Licence expiring first'),
    ('joinedOn,desc', 'Newest joiners'),
    ('updatedAt,desc', 'Recently updated'),
  ];

  bool get hasCriteria =>
      _query.status != null || _query.assignment != AssignmentFilter.any || _query.search.trim().isNotEmpty;

  Future<void> load() async {
    final serial = ++_serial;
    loading = true;
    error = null;
    _notify();
    final (list, counts) = await (_repository.list(_query), _repository.stats()).wait;
    if (serial != _serial || _disposed) return;
    loading = false;
    page = list.valueOrNull ?? page;
    stats = counts.valueOrNull ?? stats;
    error = list.errorOrNull;
    _notify();
  }

  void setStatus(DriverStatus? status) => _apply(_query.copyWith(status: () => status, page: 0));

  void setAssignment(AssignmentFilter filter) => _apply(_query.copyWith(assignment: filter, page: 0));

  void setSort(String sort) => _apply(_query.copyWith(sort: sort, page: 0));

  void setSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _apply(_query.copyWith(search: text, page: 0)));
  }

  void clearAll() => _apply(const DriverQuery());

  void nextPage() {
    if (page?.hasNext ?? false) _apply(_query.copyWith(page: _query.page + 1));
  }

  void previousPage() {
    if (page?.hasPrevious ?? false) _apply(_query.copyWith(page: _query.page - 1));
  }

  Future<Result<void>> delete(Driver driver) async {
    final result = await _repository.delete(driver.id);
    if (result is Ok<void>) await load();
    return result;
  }

  void _apply(DriverQuery next) {
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
