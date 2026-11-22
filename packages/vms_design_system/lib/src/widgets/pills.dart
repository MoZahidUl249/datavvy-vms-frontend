import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

enum StatusTone { success, neutral, warning }

/// Status is always colour + word, never colour alone.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color dot, Color fg) = switch (tone) {
      StatusTone.success => (VmsColors.successBg, VmsColors.success, VmsColors.successText),
      StatusTone.warning => (VmsColors.warningBg, VmsColors.warning, VmsColors.warningText),
      StatusTone.neutral => (VmsColors.track, VmsColors.textMeta, VmsColors.textSecondary),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(VmsRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// Vehicle number shown like a number plate. Tappable when [onTap] set.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.number, this.onTap});

  final String number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final plate = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VmsColors.surfaceSubtle,
        border: Border.all(color: VmsColors.borderPlate),
        borderRadius: BorderRadius.circular(VmsRadius.plate),
      ),
      child: Text(
        number,
        style: VmsText.tabular(const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: VmsColors.text,
          letterSpacing: 0.2,
        )),
      ),
    );
    if (onTap == null) return plate;
    return Semantics(
      button: true,
      label: 'Open $number',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VmsRadius.plate),
        child: plate,
      ),
    );
  }
}

/// Pill chip, optionally removable (applied filters, catalog values).
class VmsChip extends StatelessWidget {
  const VmsChip({super.key, required this.label, this.onRemove, this.trailing, this.removeTooltip});

  final String label;
  final VoidCallback? onRemove;
  final String? trailing;
  final String? removeTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: EdgeInsets.only(left: 12, right: onRemove == null ? 12 : 4),
      decoration: BoxDecoration(
        color: VmsColors.infoBg,
        borderRadius: BorderRadius.circular(VmsRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VmsColors.nav)),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Text(trailing!, style: VmsText.tabular(VmsText.meta)),
          ],
          if (onRemove != null)
            Tooltip(
              message: removeTooltip ?? 'Remove $label',
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: VmsColors.nav),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `Enter` style shortcut hint.
class KbdHint extends StatelessWidget {
  const KbdHint({super.key, required this.keys, required this.label});

  final String keys;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 22),
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: VmsColors.surface,
            border: Border.all(color: VmsColors.borderInput),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(keys, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VmsColors.label)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: VmsColors.textMeta)),
      ],
    );
  }
}
