import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';

import 'vehicle_models.dart';

/// Talks to `/v1/vehicles` (see backend/API.md). One instance per app.
class VehicleRepository {
  VehicleRepository(this._api);

  final ApiClient _api;

  /// Total vehicles, for the sidebar badge. Updated by [facets].
  final ValueNotifier<int?> total = ValueNotifier<int?>(null);

  Future<Result<VehiclePage>> list(VehicleQuery query) async =>
      (await _api.get('/v1/vehicles', query: query.toQuery())).map((j) => VehiclePage.fromJson(asMap(j)));

  /// How many vehicles match (used for "N vehicles match" in the filter panel).
  Future<Result<int>> count(VehicleQuery query) async =>
      (await _api.get('/v1/vehicles', query: query.copyWith(page: 0, size: 1).toQuery()))
          .map((j) => asInt(asMap(j)['totalElements']));

  Future<Result<VehicleFacets>> facets() async {
    final result = (await _api.get('/v1/vehicles/facets')).map((j) => VehicleFacets.fromJson(asMap(j)));
    if (result case Ok(:final value)) total.value = value.all;
    return result;
  }

  Future<Result<Vehicle>> get(int id) async =>
      (await _api.get('/v1/vehicles/$id')).map((j) => Vehicle.fromJson(asMap(j)));

  Future<Result<Vehicle>> create(VehicleDraft draft) async =>
      (await _api.post('/v1/vehicles', body: draft.toJson())).map((j) => Vehicle.fromJson(asMap(j)));

  Future<Result<Vehicle>> update(int id, VehicleDraft draft, {required int version}) async =>
      (await _api.put('/v1/vehicles/$id', body: draft.toJson(version: version)))
          .map((j) => Vehicle.fromJson(asMap(j)));

  Future<Result<void>> delete(int id) async => (await _api.delete('/v1/vehicles/$id')).map<void>((_) {});

  Future<Result<VehicleNumberCheck>> checkNumber(String number, {int? excludeId}) async =>
      (await _api.get('/v1/vehicles/number-check', query: {'number': number, 'excludeId': excludeId}))
          .map((j) => VehicleNumberCheck.fromJson(asMap(j)));
}
