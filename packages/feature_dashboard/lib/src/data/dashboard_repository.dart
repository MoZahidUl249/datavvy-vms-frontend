import 'package:vms_core/vms_core.dart';

import 'dashboard_models.dart';

class DashboardRepository {
  const DashboardRepository(this._api);

  final ApiClient _api;

  Future<Result<DashboardSummary>> summary() async =>
      (await _api.get('/v1/dashboard/summary')).map((json) => DashboardSummary.fromJson(asMap(json)));
}
