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

/// Form dialog frame (default 560 px): title, optional subtitle, scrollable
/// body and right-aligned actions. Use for short forms that belong to the page
/// behind them (upload a document, record a service, assign a driver).
class VmsDialog extends StatelessWidget {
  const VmsDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.subtitle,
    this.maxWidth = 560,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VmsColors.surface,
      insetPadding: const EdgeInsets.all(VmsSpace.s4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VmsRadius.dialog)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(VmsSpace.s5, VmsSpace.s5, VmsSpace.s5, VmsSpace.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VmsColors.text)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: VmsText.secondary),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(VmsSpace.s5, VmsSpace.s3, VmsSpace.s5, VmsSpace.s3),
                  child: body,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(VmsSpace.s5, VmsSpace.s3, VmsSpace.s5, VmsSpace.s5),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: VmsSpace.s3,
                  runSpacing: VmsSpace.s2,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
