import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'fields.dart';

/// A calendar day input: looks like a text field, opens the date picker on
/// click / Enter, and can be cleared when [optional]. Shows `19 Nov 2026`.
class VmsDateField extends StatelessWidget {
  const VmsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.error,
    this.helper,
    this.optional = false,
    this.enabled = true,
    this.showLabel = true,
    this.hint = 'Choose a date',
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? error;
  final String? helper;
  final bool optional;
  final bool enabled;
  final bool showLabel;
  final String hint;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String _format(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 30);
    final last = lastDate ?? DateTime(now.year + 15);
    var initial = value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: label,
    );
    if (picked != null) onChanged(DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final box = Semantics(
      button: true,
      label: '$label, ${value == null ? 'not set' : _format(value!)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => _pick(context) : null,
        borderRadius: BorderRadius.circular(VmsRadius.control),
        child: Container(
          height: VmsSize.control,
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: enabled ? VmsColors.surface : VmsColors.surfaceSubtle,
            border: Border.all(color: hasError ? VmsColors.danger : VmsColors.borderInput),
            borderRadius: BorderRadius.circular(VmsRadius.control),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: VmsColors.textMeta),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value == null ? hint : _format(value!),
                  style: value == null
                      ? const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))
                      : VmsText.tabular(const TextStyle(fontSize: 15, color: VmsColors.text)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (optional && value != null && enabled)
                IconButton(
                  tooltip: 'Clear $label',
                  icon: const Icon(Icons.close, size: 16, color: VmsColors.textMeta),
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
        ),
      ),
    );
    if (!showLabel) return box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(text: label, optional: optional),
        box,
        FieldMessage(error: error, helper: helper),
      ],
    );
  }
}
