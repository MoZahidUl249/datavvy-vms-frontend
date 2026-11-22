import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';

import '../../data/vehicle_models.dart';
import '../../data/vehicle_repository.dart';

/// State + commands behind the Vehicle List screen.
class VehicleListViewModel extends ChangeNotifier {
  VehicleListViewModel({
    required VehicleRepository repository,
    VehicleQuery initialQuery = const VehicleQuery(),
    this.highlightId,
  })  : _repository = repository,
        _query = initialQuery;

  final VehicleRepository _repository;
  VehicleQuery _query;
  Timer? _searchDebounce;
  int _requestSerial = 0;
  bool _disposed = false;

  VehiclePage? page;
  VehicleFacets facets = VehicleFacets.empty;
  bool loading = false;
  ApiError? error;

  /// Row to flash light blue after save (~2 s).
  int? highlightId;

  VehicleQuery get query => _query;

  /// No vehicles at all (first-run empty state), as opposed to "no results".
  bool get isFirstRun => facets.all == 0 && page != null && page!.total == 0 && !_hasCriteria;

  bool get _hasCriteria =>
      _query.status != StatusFilter.all || _query.search.trim().isNotEmpty || !_query.filters.isEmpty;

  Future<void> load() async {
    final serial = ++_requestSerial;
    loading = true;
    error = null;
    _notify();
    final (pageResult, facetResult) = await (_repository.list(_query), _repository.facets()).wait;
    if (serial != _requestSerial || _disposed) return; // a newer request superseded this one
    loading = false;
    page = pageResult.valueOrNull ?? page;
    facets = facetResult.valueOrNull ?? facets;
    error = pageResult.errorOrNull;
    _notify();
    if (highlightId != null) {
      Timer(const Duration(seconds: 2), () {
        highlightId = null;
        _notify();
      });
    }
  }

  void setStatus(StatusFilter status) => _apply(_query.copyWith(status: status, page: 0));

  void setSearch(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () => _apply(_query.copyWith(search: text, page: 0)));
  }

  void applyFilters(VehicleFilters filters) => _apply(_query.copyWith(filters: filters, page: 0));

  void clearFilters() => applyFilters(VehicleFilters.none);

  void setSort(VehicleSort sort) => _apply(_query.copyWith(sort: sort, page: 0));

  /// Header click: same field flips direction, new field starts descending.
  void sortBy(String field) {
    final current = _query.sort;
    setSort(current.field == field ? current.toggled() : VehicleSort(field));
  }

  void nextPage() {
    if (page?.hasNext ?? false) _apply(_query.copyWith(page: _query.page + 1));
  }

  void previousPage() {
    if (page?.hasPrevious ?? false) _apply(_query.copyWith(page: _query.page - 1));
  }

  /// Count for a draft of filters (filter panel footer).
  Future<int?> countFor(VehicleFilters draft) async =>
      (await _repository.count(_query.copyWith(filters: draft))).valueOrNull;

  Future<Result<void>> delete(Vehicle vehicle) async {
    final result = await _repository.delete(vehicle.id);
    if (result is Ok<void>) await load();
    return result;
  }

  void _apply(VehicleQuery next) {
    _query = next;
    unawaited(load());
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }
}
