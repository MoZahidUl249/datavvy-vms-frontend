import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'buttons.dart';

/// Confirmation dialog (400 px). Destructive: Cancel beside a red action.
/// Resolves to true only when the user confirms.
Future<bool> showVmsConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: VmsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VmsRadius.dialog)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(VmsSpace.s5),
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VmsColors.text)),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 15, height: 22 / 15, color: VmsColors.textSecondary)),
                const SizedBox(height: VmsSpace.s5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    VmsButton(
                      label: 'Cancel',
                      variant: VmsButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: VmsSpace.s3),
                    VmsButton(
                      label: confirmLabel,
                      variant: destructive ? VmsButtonVariant.destructive : VmsButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
