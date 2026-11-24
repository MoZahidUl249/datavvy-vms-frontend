import 'package:material_ui/material_ui.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../expiry.dart';

/// Expiry state as colour + word, with the exact wording in a tooltip
/// ("Expires in 12 days"). Red = expired, amber = expiring soon.
class ExpiryPill extends StatelessWidget {
  const ExpiryPill({super.key, required this.status, this.daysLeft});

  final ExpiryStatus status;
  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: describeExpiry(status, daysLeft),
      child: StatusPill(label: status.label, tone: status.tone),
    );
  }
}
