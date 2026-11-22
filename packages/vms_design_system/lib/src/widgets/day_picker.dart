import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

/// Small month calendar where only days that have data can be picked
/// (bold, with a dot). ‹ › jump to the previous / next month that has data.
class VmsDayPicker extends StatefulWidget {
  const VmsDayPicker({
    super.key,
    required this.enabledDays,
    required this.selected,
    required this.onChanged,
  });

  /// Date-only values (time ignored).
  final Set<DateTime> enabledDays;
  final DateTime? selected;

  /// Null = "Any date".
  final ValueChanged<DateTime?> onChanged;

  @override
  State<VmsDayPicker> createState() => _VmsDayPickerState();
}

class _VmsDayPickerState extends State<VmsDayPicker> {
  late DateTime _month;

  Set<DateTime> get _days => widget.enabledDays.map((d) => DateTime(d.year, d.month, d.day)).toSet();

  @override
  void initState() {
    super.initState();
    final anchor = widget.selected ?? _latest() ?? DateTime.now();
    _month = DateTime(anchor.year, anchor.month);
  }

  DateTime? _latest() {
    if (widget.enabledDays.isEmpty) return null;
    return widget.enabledDays.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Nearest month before/after the shown one that has data.
  DateTime? _jump(int direction) {
    final months = _days.map((d) => DateTime(d.year, d.month)).toSet().toList()..sort();
    if (direction < 0) {
      final before = months.where((m) => m.isBefore(_month));
      return before.isEmpty ? null : before.last;
    }
    final after = months.where((m) => m.isAfter(_month));
    return after.isEmpty ? null : after.first;
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    final prev = _jump(-1);
    final next = _jump(1);
    final first = DateTime(_month.year, _month.month);
    final leading = (first.weekday + 6) % 7; // Monday-first
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final sel = widget.selected == null
        ? null
        : DateTime(widget.selected!.year, widget.selected!.month, widget.selected!.day);

    final cells = <Widget>[
      for (final w in _weekdays)
        Center(child: Text(w, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VmsColors.textMeta))),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++) _day(DateTime(_month.year, _month.month, d), days, sel),
    ];

    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VmsColors.surface,
        border: Border.all(color: VmsColors.borderCard),
        borderRadius: BorderRadius.circular(VmsRadius.group),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month with data',
                onPressed: prev == null ? null : () => setState(() => _month = prev),
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: VmsColors.text),
                ),
              ),
              IconButton(
                tooltip: 'Next month with data',
                onPressed: next == null ? null : () => setState(() => _month = next),
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: cells,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => widget.onChanged(null),
              child: const Text('Any date'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _day(DateTime day, Set<DateTime> enabled, DateTime? selected) {
    final isEnabled = enabled.contains(day);
    final isSelected = selected == day;
    final label = '${day.day}';
    return Semantics(
      button: isEnabled,
      selected: isSelected,
      enabled: isEnabled,
      label: '${day.day} ${_monthNames[day.month - 1]} ${day.year}${isEnabled ? '' : ', no data'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: isEnabled ? () => widget.onChanged(day) : null,
        borderRadius: BorderRadius.circular(VmsRadius.small),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? VmsColors.nav : Colors.transparent,
            borderRadius: BorderRadius.circular(VmsRadius.small),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: VmsText.tabular(TextStyle(
                  fontSize: 13,
                  fontWeight: isEnabled ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : isEnabled
                          ? VmsColors.text
                          : const Color(0xFFCBD5E1),
                )),
              ),
              if (isEnabled)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : VmsColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
