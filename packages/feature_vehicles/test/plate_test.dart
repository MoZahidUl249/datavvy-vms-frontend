import 'package:feature_vehicles/feature_vehicles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlateParts', () {
    test('parses loose spellings into the canonical value', () {
      expect(PlateParts.tryParse('dha metro ga 11 4582')!.value, 'DHA-METRO-GA 11-4582');
      expect(PlateParts.tryParse('DHAMETROGA114582')!.value, 'DHA-METRO-GA 11-4582');
      expect(PlateParts.tryParse('SYL-GA 11-0458')!.value, 'SYL-GA 11-0458');
    });

    test('rejects incomplete numbers', () {
      expect(PlateParts.tryParse('DHA-GA 1-4582'), isNull);
      expect(PlateParts.tryParse(''), isNull);
    });

    test('names the part that needs fixing', () {
      expect(const PlateParts(area: 'DH').firstProblem, contains('Area'));
      expect(const PlateParts(area: 'DHA', cls: 'GA', series: '1').firstProblem, contains('Series'));
      expect(const PlateParts(area: 'DHA', cls: 'GA', series: '11', number: '458').firstProblem, contains('Number'));
      expect(const PlateParts(area: 'DHA', metro: true, cls: 'GA', series: '11', number: '4582').isComplete, isTrue);
    });

    test('key ignores case, spaces and hyphens', () {
      expect(PlateParts.key('dha-metro-ga 11-4582'), 'DHAMETROGA114582');
    });
  });

  test('filters count each applied choice', () {
    final f = VehicleFilters(types: const {'Bus', 'Truck'}, brands: const {'Toyota'}, addedOn: DateTime(2026, 11, 12));
    expect(f.count, 4);
    expect(f.toQuery()['addedOn'], '2026-11-12');
    expect(f.toQuery()['type'], ['Bus', 'Truck']);
  });

  test('vehicle JSON maps the course fields', () {
    final v = Vehicle.fromJson({
      'id': 1,
      'vehicleNumber': 'DHA-METRO-GA 11-4582',
      'company': 'Datavvy Logistics',
      'type': 'Microbus',
      'brand': 'Toyota',
      'model': 'Hiace',
      'status': 'MAINTENANCE',
      'version': 3,
    });
    expect(v.status, VehicleStatus.maintenance);
    expect(v.company, 'Datavvy Logistics');
    const draft = VehicleDraft(
      vehicleNumber: 'DHA-METRO-GA 11-4582',
      company: ' Datavvy ',
      type: 'Microbus',
      brand: 'Toyota',
      model: 'Hiace',
      status: VehicleStatus.inactive,
    );
    expect(draft.toJson(version: 3), containsPair('status', 'INACTIVE'));
    expect(draft.toJson()['company'], 'Datavvy');
    expect(draft.toJson().containsKey('version'), isFalse);
  });
}
