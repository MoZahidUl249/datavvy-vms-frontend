import 'package:vms_design_system/vms_design_system.dart';

/// `ExpiryStatus` in the contract: where a document or licence stands today.
enum ExpiryStatus {
  expired('EXPIRED', 'Expired', StatusTone.danger),
  expiringSoon('EXPIRING_SOON', 'Expiring soon', StatusTone.warning),
  valid('VALID', 'Valid', StatusTone.success),
  noExpiry('NO_EXPIRY', 'No expiry', StatusTone.neutral);

  const ExpiryStatus(this.apiValue, this.label, this.tone);
  final String apiValue;
  final String label;
  final StatusTone tone;

  static ExpiryStatus fromApi(Object? value) =>
      ExpiryStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => ExpiryStatus.noExpiry);

  bool get needsAttention => this == expired || this == expiringSoon;
}

/// "Expired 9 days ago", "Expires today", "Expires in 12 days", "Valid for 5 months".
String describeExpiry(ExpiryStatus status, int? daysLeft) {
  if (daysLeft == null) return 'Does not expire';
  if (daysLeft < 0) {
    final d = -daysLeft;
    return 'Expired ${d == 1 ? 'yesterday' : '$d days ago'}';
  }
  if (daysLeft == 0) return 'Expires today';
  if (daysLeft == 1) return 'Expires tomorrow';
  if (daysLeft <= 60) return 'Expires in $daysLeft days';
  final months = (daysLeft / 30).floor();
  return months < 24 ? 'Valid for $months months' : 'Valid for ${(daysLeft / 365).floor()} years';
}
