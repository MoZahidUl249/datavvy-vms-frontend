import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';
import 'package:feature_drivers/src/ui/form/driver_form_view_model.dart';

class _NoToken implements TokenProvider {
  @override
  String? get token => 'test-token';
}

DriverRepository _repo(http.Client client) =>
    DriverRepository(ApiClient(config: const AppConfig(apiBaseUrl: 'http://api.test/api'), tokens: _NoToken(), httpClient: client));

void main() {
  test('local checks catch a bad mobile and a missing licence expiry before calling the API', () async {
    var calls = 0;
    final vm = DriverFormViewModel(repository: _repo(MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    })));
    final saved = await vm.save(fullName: 'Kamal', phone: '12345', licenseNumber: 'DK555666C777', address: '', notes: '');
    expect(saved, isNull);
    expect(vm.errors.keys, containsAll(['phone', 'licenseExpiry']));
    expect(calls, 0);
  });

  test('accepts +880 numbers and spaced licence numbers', () {
    final e = DriverFormViewModel.check(
      fullName: 'Kamal Hossain',
      phone: '+880 1711-223344',
      licenseNumber: 'dk 555 666 c 777',
      licenseExpiry: DateTime(2029),
    );
    expect(e, isEmpty);
  });

  test('a duplicate licence from the API shows under the licence field', () async {
    final vm = DriverFormViewModel(repository: _repo(MockClient((req) async {
      expect(req.url.path, '/api/v1/drivers');
      return http.Response(
        jsonEncode({
          'status': 409,
          'code': 'DUPLICATE_LICENSE_NUMBER',
          'detail': 'Licence DK555666C777 already belongs to Kamal Hossain.',
          'details': {'field': 'licenseNumber', 'existingId': 9},
        }),
        409,
      );
    })))
      ..setLicenseExpiry(DateTime(2029, 1, 1));
    final saved =
        await vm.save(fullName: 'Someone', phone: '01811223344', licenseNumber: 'DK555666C777', address: '', notes: '');
    expect(saved, isNull);
    expect(vm.errors['licenseNumber'], contains('Kamal Hossain'));
    expect(vm.formError, isNull);
  });
}
