import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

enum VmsButtonVariant { primary, secondary, text, destructive, destructiveText }

/// The one button. One `primary` per screen; `destructive*` only for delete.
/// While [loading] the label stays so the button keeps its width.
class VmsButton extends StatelessWidget {
  const VmsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VmsButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.small = false,
    this.expand = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final VmsButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool small;
  final bool expand;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final height = small ? VmsSize.controlSmall : VmsSize.control;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      VmsButtonVariant.primary => (VmsColors.primary, Colors.white, BorderSide.none),
      VmsButtonVariant.secondary =>
        (VmsColors.surface, VmsColors.text, const BorderSide(color: VmsColors.borderInput)),
      VmsButtonVariant.text => (Colors.transparent, VmsColors.primaryAccessible, BorderSide.none),
      VmsButtonVariant.destructive => (VmsColors.danger, Colors.white, BorderSide.none),
      VmsButtonVariant.destructiveText => (Colors.transparent, VmsColors.danger, BorderSide.none),
    };
    final hoverOverlay = switch (variant) {
      VmsButtonVariant.destructiveText => VmsColors.dangerBg,
      VmsButtonVariant.primary || VmsButtonVariant.destructive => Colors.black.withValues(alpha: 0.08),
      _ => VmsColors.track,
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            ),
          )
        else if (icon != null)
          Padding(padding: const EdgeInsets.only(right: 8), child: Icon(icon, size: 18)),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final button = TextButton(
      onPressed: loading ? null : onPressed,
      focusNode: focusNode,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, height)),
        fixedSize: WidgetStatePropertyAll(Size.fromHeight(height)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: small ? 14 : 20)),
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: small ? 14 : 15, fontWeight: FontWeight.w600),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(VmsRadius.control))),
        ),
        side: WidgetStatePropertyAll(side),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled) && !loading) {
            return bg == Colors.transparent ? Colors.transparent : bg.withValues(alpha: 0.45);
          }
          return bg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled) && !loading) return fg.withValues(alpha: 0.6);
          return fg;
        }),
        overlayColor: WidgetStatePropertyAll(hoverOverlay),
      ),
      child: content,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// 36 px square icon button with a tooltip (doubles as its accessible label)
/// and an optional count badge.
class VmsIconButton extends StatelessWidget {
  const VmsIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.bordered = true,
    this.color = VmsColors.textSecondary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badgeCount;
  final bool bordered;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 18, color: color);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(VmsSize.controlSmall, VmsSize.controlSmall),
          minimumSize: const Size(VmsSize.controlSmall, VmsSize.controlSmall),
          padding: EdgeInsets.zero,
          backgroundColor: bordered ? VmsColors.surface : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VmsRadius.control),
            side: bordered ? const BorderSide(color: VmsColors.borderInput) : BorderSide.none,
          ),
        ),
        icon: badgeCount > 0
            ? Badge(
                label: Text('$badgeCount'),
                backgroundColor: VmsColors.primaryAccessible,
                child: glyph,
              )
            : glyph,
      ),
    );
  }
}
