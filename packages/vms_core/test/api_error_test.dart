import 'package:flutter_test/flutter_test.dart';
import 'package:vms_core/vms_core.dart';

void main() {
  test('reads code, detail and field errors from a problem document', () {
    final e = ApiError.fromResponse(400, {
      'status': 400,
      'detail': 'Some fields need attention.',
      'code': 'VALIDATION_FAILED',
      'fieldErrors': [
        {'field': 'make', 'message': 'Enter the make, like Toyota.'},
      ],
    });
    expect(e.code, 'VALIDATION_FAILED');
    expect(e.isValidation, isTrue);
    expect(e.fieldErrors['make'], 'Enter the make, like Toyota.');
  });

  test('falls back when the body is not a problem document', () {
    final e = ApiError.fromResponse(502, null);
    expect(e.code, 'HTTP_502');
    expect(e.message, contains('502'));
  });

  test('vehiclesWhere builds dashboard deep links', () {
    expect(AppRoutes.vehiclesWhere(status: 'ACTIVE'), '/vehicles?status=ACTIVE');
    expect(AppRoutes.vehiclesWhere(), '/vehicles');
  });
}
