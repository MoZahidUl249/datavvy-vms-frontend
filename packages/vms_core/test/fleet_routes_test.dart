import 'package:flutter_test/flutter_test.dart';
import 'package:vms_core/vms_core.dart';

void main() {
  test('vehicle page, edit form and section links', () {
    expect(AppRoutes.vehicleDetail(7), '/vehicles/7');
    expect(AppRoutes.vehicleEdit(7), '/vehicles/7/edit');
    expect(AppRoutes.vehicleSection(7, 'documents'), '/vehicles/7?section=documents');
  });

  test('filtered list links', () {
    expect(AppRoutes.documentsWhere(expiry: 'EXPIRED'), '/documents?expiry=EXPIRED');
    expect(AppRoutes.documentsWhere(), '/documents');
    expect(AppRoutes.driversWhere(assigned: false, status: 'ACTIVE'), '/drivers?assigned=false&status=ACTIVE');
  });

  test('dates and money from JSON', () {
    expect(asDate('2026-11-24'), DateTime(2026, 11, 24));
    expect(asDate(null), isNull);
    expect(asDouble(4500), 4500.0);
    expect(asDouble(85000.5), 85000.5);
    expect(asDouble('12.25'), 12.25);
  });

  test('file sizes', () {
    expect(formatFileSize(622), '622 B');
    expect(formatFileSize(640 * 1024), '640 KB');
    expect(formatFileSize(5 * 1024 * 1024), '5.0 MB');
  });
}
