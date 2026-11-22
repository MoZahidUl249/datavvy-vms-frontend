import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';

import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository);

  final DashboardRepository _repository;

  DashboardSummary? summary;
  ApiError? error;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    final result = await _repository.summary();
    loading = false;
    summary = result.valueOrNull ?? summary;
    error = result.errorOrNull;
    notifyListeners();
  }
}
