import 'package:feature_documents/feature_documents.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

void main() {
  test('dashboard links open the matching expiry segment; unknown values fall back to needs attention', () {
    expect(ExpiryFilter.fromQuery('EXPIRED'), ExpiryFilter.expired);
    expect(ExpiryFilter.fromQuery('attention').statuses, {ExpiryStatus.expired, ExpiryStatus.expiringSoon});
    expect(ExpiryFilter.fromQuery('nonsense'), ExpiryFilter.attention);
    expect(ExpiryFilter.all.statuses, isEmpty);
  });

  test('segment counts come from the summary', () {
    const s = DocumentStats(total: 23, valid: 9, expiringSoon: 4, expired: 3, noExpiry: 7, expiringSoonDays: 30);
    expect(ExpiryFilter.attention.countIn(s), 7);
    expect(ExpiryFilter.all.countIn(s), 23);
  });
}
