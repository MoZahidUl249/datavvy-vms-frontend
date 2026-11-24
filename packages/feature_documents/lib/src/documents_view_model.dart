import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

/// The expiry segments on the Documents screen. "Needs attention" =
/// expired + expiring soon, the default view.
enum ExpiryFilter {
  attention('attention', 'Needs attention', {ExpiryStatus.expired, ExpiryStatus.expiringSoon}),
  expired('EXPIRED', 'Expired', {ExpiryStatus.expired}),
  expiringSoon('EXPIRING_SOON', 'Expiring soon', {ExpiryStatus.expiringSoon}),
  valid('VALID', 'Valid', {ExpiryStatus.valid}),
  noExpiry('NO_EXPIRY', 'No expiry', {ExpiryStatus.noExpiry}),
  all('all', 'All', <ExpiryStatus>{});

  const ExpiryFilter(this.queryValue, this.label, this.statuses);
  final String queryValue;
  final String label;
  final Set<ExpiryStatus> statuses;

  static ExpiryFilter fromQuery(String? value) =>
      ExpiryFilter.values.firstWhere((f) => f.queryValue == value, orElse: () => ExpiryFilter.attention);

  int countIn(DocumentStats s) => switch (this) {
        attention => s.needingAttention,
        expired => s.expired,
        expiringSoon => s.expiringSoon,
        valid => s.valid,
        noExpiry => s.noExpiry,
        all => s.total,
      };
}

class DocumentsViewModel extends ChangeNotifier {
  DocumentsViewModel({required DocumentRepository repository, ExpiryFilter filter = ExpiryFilter.attention})
      : _repository = repository,
        _filter = filter,
        _query = DocumentQuery(expiry: filter.statuses);

  final DocumentRepository _repository;
  ExpiryFilter _filter;
  DocumentQuery _query;
  Timer? _debounce;
  int _serial = 0;
  bool _disposed = false;

  Paged<VehicleDocument>? page;
  DocumentStats stats = DocumentStats.empty;
  bool loading = false;
  ApiError? error;

  ExpiryFilter get filter => _filter;
  DocumentQuery get query => _query;

  static const sorts = [
    ('expiryDate,asc', 'Expiry: soonest first'),
    ('expiryDate,desc', 'Expiry: latest first'),
    ('updatedAt,desc', 'Recently updated'),
    ('type,asc', 'Type'),
  ];

  Future<void> load() async {
    final serial = ++_serial;
    loading = true;
    error = null;
    _notify();
    final (list, counts) = await (_repository.search(_query), _repository.stats()).wait;
    if (serial != _serial || _disposed) return;
    loading = false;
    page = list.valueOrNull ?? page;
    stats = counts.valueOrNull ?? stats;
    error = list.errorOrNull;
    _notify();
  }

  void setFilter(ExpiryFilter f) {
    _filter = f;
    _apply(_query.copyWith(expiry: f.statuses, page: 0));
  }

  void setType(DocumentType? type) => _apply(_query.copyWith(type: () => type, page: 0));

  void setSort(String sort) => _apply(_query.copyWith(sort: sort, page: 0));

  void setSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _apply(_query.copyWith(search: text, page: 0)));
  }

  void nextPage() {
    if (page?.hasNext ?? false) _apply(_query.copyWith(page: _query.page + 1));
  }

  void previousPage() {
    if (page?.hasPrevious ?? false) _apply(_query.copyWith(page: _query.page - 1));
  }

  Future<Result<Uint8List>> fileOf(VehicleDocument d) => _repository.fileBytes(d.id);

  void _apply(DocumentQuery next) {
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
