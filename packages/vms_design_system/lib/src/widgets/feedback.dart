import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'buttons.dart';

/// Grey placeholder block; compose skeletons that match the final layout.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: VmsColors.divider, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Centered empty / no-results state with one way forward.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: VmsColors.infoBg, shape: BoxShape.circle),
            child: Icon(icon, color: VmsColors.nav, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, height: 26 / 20, fontWeight: FontWeight.w600, color: VmsColors.text)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 22 / 15, color: VmsColors.textMeta)),
          ),
          if (extra != null) ...[const SizedBox(height: 12), extra!],
          if (actionLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (secondaryLabel != null)
                  VmsButton(label: secondaryLabel!, onPressed: onSecondary, variant: VmsButtonVariant.secondary),
                if (actionLabel != null) VmsButton(label: actionLabel!, onPressed: onAction),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline red banner (wrong credentials, save failed, load failed).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.actionLabel, this.onAction, this.children = const []});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Extra lines, e.g. a list of field problems that link to their fields.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: VmsColors.dangerBg,
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(VmsRadius.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1, right: 10),
              child: Icon(Icons.error_outline, size: 18, color: VmsColors.danger),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message,
                      style: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, color: VmsColors.dangerText)),
                  ...children,
                ],
              ),
            ),
            if (actionLabel != null)
              VmsButton(label: actionLabel!, onPressed: onAction, variant: VmsButtonVariant.text, small: true),
          ],
        ),
      ),
    );
  }
}

/// Dark toast, bottom-centre, 6 s, optional Undo.
void showVmsToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        width: 440,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VmsRadius.group)),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}, textColor: VmsColors.primary),
      ),
    );
}
