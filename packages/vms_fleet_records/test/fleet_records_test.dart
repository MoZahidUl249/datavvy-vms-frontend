import 'package:flutter_test/flutter_test.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

void main() {
  test('taka amounts use Bangladeshi grouping and show paisa only when present', () {
    expect(formatTaka(0), '৳ 0');
    expect(formatTaka(4500), '৳ 4,500');
    expect(formatTaka(129000), '৳ 1,29,000');
    expect(formatTaka(12345678.5), '৳ 1,23,45,678.50');
  });

  test('expiry wording', () {
    expect(describeExpiry(ExpiryStatus.expired, -1), 'Expired yesterday');
    expect(describeExpiry(ExpiryStatus.expired, -9), 'Expired 9 days ago');
    expect(describeExpiry(ExpiryStatus.expiringSoon, 0), 'Expires today');
    expect(describeExpiry(ExpiryStatus.expiringSoon, 12), 'Expires in 12 days');
    expect(describeExpiry(ExpiryStatus.valid, 200), 'Valid for 6 months');
    expect(describeExpiry(ExpiryStatus.noExpiry, null), 'Does not expire');
  });

  test('document JSON matches the contract', () {
    final d = VehicleDocument.fromJson({
      'id': 7,
      'vehicleId': 2,
      'vehicleNumber': 'CTG-METRO-TA 12-0931',
      'type': 'TAX_TOKEN',
      'documentNumber': 'TT-25-0120931',
      'issueDate': '2025-11-15',
      'expiryDate': '2026-11-15',
      'expiryStatus': 'EXPIRED',
      'daysUntilExpiry': -9,
      'fileName': 'tax-token.pdf',
      'contentType': 'application/pdf',
      'sizeBytes': 622,
      'version': 0,
    });
    expect(d.type, DocumentType.taxToken);
    expect(d.displayName, 'Tax token');
    expect(d.expiryStatus, ExpiryStatus.expired);
    expect(d.expiryStatus.needsAttention, isTrue);
    expect(d.expiryDate, DateTime(2026, 11, 15));
  });

  test('document draft sends only filled fields on upload', () {
    final fields = DocumentDraft(
      type: DocumentType.insurance,
      documentNumber: '  GDIC/1 ',
      expiryDate: DateTime(2027, 6, 30),
      notes: ' ',
    ).toFields();
    expect(fields, {'type': 'INSURANCE', 'documentNumber': 'GDIC/1', 'expiryDate': '2027-06-30'});
  });

  test('maintenance draft converts the typed cost to a number', () {
    final json = MaintenanceDraft(
      serviceDate: DateTime(2026, 11, 20),
      type: MaintenanceType.oilChange,
      cost: '4,500.50',
      vendor: ' Navana ',
    ).toJson(version: 3);
    expect(json['cost'], 4500.5);
    expect(json['type'], 'OIL_CHANGE');
    expect(json['vendor'], 'Navana');
    expect(json['version'], 3);
  });

  test('driver with expired licence or on leave cannot be assigned', () {
    Driver driver(String status, String licence) => Driver.fromJson({
          'id': 1,
          'fullName': 'Rubel Mia',
          'phone': '01716000006',
          'licenseNumber': 'DK3344556M00006',
          'licenseStatus': licence,
          'status': status,
        });
    expect(driver('ACTIVE', 'VALID').notAssignableReason, isNull);
    expect(driver('ACTIVE', 'EXPIRED').notAssignableReason, 'Licence expired');
    expect(driver('ON_LEAVE', 'VALID').notAssignableReason, 'On leave');
  });

  test('driver query maps the assignment filter', () {
    final q = const DriverQuery(assignment: AssignmentFilter.available, status: DriverStatus.active).toQuery();
    expect(q['assigned'], false);
    expect(q['status'], 'ACTIVE');
  });
}
