import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

class VmsSegment<T> {
  const VmsSegment({required this.value, required this.label, this.count});
  final T value;
  final String label;
  final int? count;
}

/// iOS-style segmented control: gray track, selected segment white.
/// Each segment is a button; Tab reaches them in order.
class VmsSegmented<T> extends StatelessWidget {
  const VmsSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.small = true,
    this.semanticLabel,
  });

  final List<VmsSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;
  final bool small;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: VmsColors.track,
          borderRadius: BorderRadius.circular(VmsRadius.control),
        ),
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            for (var i = 0; i < segments.length; i++) _segment(context, i),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
    final s = segments[index];
    final isOn = s.value == selected;
    return Semantics(
      selected: isOn,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(s.value),
          borderRadius: BorderRadius.circular(VmsRadius.small),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: small ? 30 : 36,
            // No `alignment` here: it would make each segment fill the row.
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isOn ? VmsColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(VmsRadius.small),
              boxShadow: isOn ? VmsShadows.segment : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOn ? VmsColors.text : VmsColors.textSecondary,
                  ),
                ),
                if (s.count != null) ...[
                  const SizedBox(width: 6),
                  Text('${s.count}', style: VmsText.tabular(VmsText.meta)),
                ],
              ],
            ),
          ),
      ),
    );
  }
}

/// 51×31 switch: green on, slate off.
class VmsSwitch extends StatelessWidget {
  const VmsSwitch({super.key, required this.value, required this.onChanged, this.focusNode, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final FocusNode? focusNode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Switch(
        value: value,
        onChanged: onChanged,
        focusNode: focusNode,
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? VmsColors.success : VmsColors.switchOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
