import 'dart:convert';

import 'package:feature_maintenance/src/maintenance_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

class _Token implements TokenProvider {
  @override
  String? get token => 't';
}

void main() {
  test('filters go to the server as query parameters and the page total adds up', () async {
    final seen = <Uri>[];
    final client = MockClient((req) async {
      seen.add(req.url);
      if (req.url.path.endsWith('/stats')) {
        return http.Response(
            jsonEncode({'totalRecords': 2, 'totalCost': 11000, 'recordsThisMonth': 1, 'costThisMonth': 4500, 'byMonth': [], 'byType': []}),
            200);
      }
      return http.Response(
        jsonEncode({
          'content': [
            {'id': 1, 'vehicleId': 1, 'vehicleNumber': 'DHA-METRO-GA 11-4582', 'serviceDate': '2026-11-20', 'type': 'OIL_CHANGE', 'cost': 4500, 'vendor': 'Navana'},
            {'id': 2, 'vehicleId': 2, 'vehicleNumber': 'CTG-METRO-TA 12-0931', 'serviceDate': '2026-10-02', 'type': 'BRAKES', 'cost': 6500.5, 'vendor': 'Isuzu'},
          ],
          'page': 0,
          'size': 20,
          'totalElements': 2,
          'totalPages': 1,
        }),
        200,
      );
    });
    final vm = MaintenanceViewModel(
      repository: MaintenanceRepository(
          ApiClient(config: const AppConfig(apiBaseUrl: 'http://api.test/api'), tokens: _Token(), httpClient: client)),
    );
    await vm.load();
    expect(vm.page!.items, hasLength(2));
    expect(vm.pageCost, 11000.5);
    expect(vm.stats!.costThisMonth, 4500);

    vm.setType(MaintenanceType.brakes);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final list = seen.lastWhere((u) => u.path.endsWith('/v1/maintenance'));
    expect(list.queryParameters['type'], 'BRAKES');
    expect(list.queryParameters['sort'], 'serviceDate,desc');
    vm.dispose();
  });
}
