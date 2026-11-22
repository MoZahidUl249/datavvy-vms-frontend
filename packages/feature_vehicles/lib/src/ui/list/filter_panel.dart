import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:vms_catalog/vms_catalog.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../../data/vehicle_models.dart';

/// Opens the 380 px filter popover. Choices are a draft: nothing changes
/// until "Apply filters". Esc / × close without applying (returns null).
Future<VehicleFilters?> showFilterPanel(
  BuildContext context, {
  required VehicleFilters current,
  required List<CatalogItem> types,
  required VehicleFacets facets,
  required Future<int?> Function(VehicleFilters draft) countFor,
}) {
  return showDialog<VehicleFilters>(
    context: context,
    barrierColor: const Color(0x14101828),
    builder: (context) => Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.fromLTRB(24, 140, 32, 24),
      backgroundColor: VmsColors.surface,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VmsRadius.card)),
      child: SizedBox(
        width: 380,
        child: _FilterPanel(current: current, types: types, facets: facets, countFor: countFor),
      ),
    ),
  );
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    required this.current,
    required this.types,
    required this.facets,
    required this.countFor,
  });

  final VehicleFilters current;
  final List<CatalogItem> types;
  final VehicleFacets facets;
  final Future<int?> Function(VehicleFilters draft) countFor;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

enum _OpenCalendar { none, updated, added }

class _FilterPanelState extends State<_FilterPanel> {
  late VehicleFilters _draft = widget.current;
  _OpenCalendar _calendar = _OpenCalendar.none;
  int? _matchCount;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _recount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _update(VehicleFilters next) {
    setState(() => _draft = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _recount);
  }

  Future<void> _recount() async {
    final draft = _draft;
    final n = await widget.countFor(draft);
    if (mounted && identical(draft, _draft)) setState(() => _matchCount = n);
  }

  Set<T> _toggle<T>(Set<T> set, T value) => set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height - 220;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: 'Filters',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
            child: Row(
              children: [
                const Expanded(child: Text('Filters', style: VmsText.h2)),
                VmsIconButton(
                  icon: Icons.close,
                  tooltip: 'Close without applying',
                  bordered: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Flexible lets the list shrink when the popup is shorter than
          // maxHeight, so header + list + footer never overflow.
          Flexible(
            child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight < 240 ? 240 : maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section('Vehicle type', [
                    for (final t in widget.types)
                      _ToggleChip(
                        label: t.name,
                        selected: _draft.types.contains(t.name),
                        onTap: () => _update(_draft.copyWith(types: _toggle(_draft.types, t.name))),
                      ),
                  ]),
                  _section('Company', [
                    for (final c in widget.facets.companies)
                      _ToggleChip(
                        label: c,
                        selected: _draft.companies.contains(c),
                        onTap: () => _update(_draft.copyWith(companies: _toggle(_draft.companies, c))),
                      ),
                  ]),
                  _section('Brand', [
                    for (final b in widget.facets.brands)
                      _ToggleChip(
                        label: b,
                        selected: _draft.brands.contains(b),
                        onTap: () => _update(_draft.copyWith(brands: _toggle(_draft.brands, b))),
                      ),
                  ]),
                  _dateField(
                    label: 'Last updated on',
                    value: _draft.updatedOn,
                    open: _calendar == _OpenCalendar.updated,
                    onToggle: () => setState(() => _calendar =
                        _calendar == _OpenCalendar.updated ? _OpenCalendar.none : _OpenCalendar.updated),
                    days: widget.facets.updatedDates,
                    onPick: (d) {
                      _update(_draft.copyWith(updatedOn: () => d));
                      setState(() => _calendar = _OpenCalendar.none);
                    },
                  ),
                  _dateField(
                    label: 'Added on',
                    value: _draft.addedOn,
                    open: _calendar == _OpenCalendar.added,
                    onToggle: () => setState(() =>
                        _calendar = _calendar == _OpenCalendar.added ? _OpenCalendar.none : _OpenCalendar.added),
                    days: widget.facets.addedDates,
                    onPick: (d) {
                      _update(_draft.copyWith(addedOn: () => d));
                      setState(() => _calendar = _OpenCalendar.none);
                    },
                  ),
                ],
              ),
            ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: const BoxDecoration(
              color: VmsColors.surfaceSubtle,
              border: Border(top: BorderSide(color: VmsColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _matchCount == null
                          ? 'Counting…'
                          : '$_matchCount vehicle${_matchCount == 1 ? '' : 's'} match',
                      style: VmsText.tabular(VmsText.meta),
                    ),
                  ),
                ),
                VmsButton(
                  label: 'Reset',
                  small: true,
                  variant: VmsButtonVariant.text,
                  onPressed: _draft.isEmpty ? null : () => _update(VehicleFilters.none),
                ),
                const SizedBox(width: 8),
                VmsButton(
                  label: 'Apply filters',
                  small: true,
                  onPressed: () => Navigator.of(context).pop(_draft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> chips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VmsText.label),
          const SizedBox(height: 8),
          if (chips.isEmpty)
            const Text('Nothing to filter by yet.', style: VmsText.meta)
          else
            Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required bool open,
    required VoidCallback onToggle,
    required Set<DateTime> days,
    required ValueChanged<DateTime?> onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: VmsText.label),
          const SizedBox(height: 8),
          Material(
            color: value != null ? VmsColors.selectedBg : VmsColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VmsRadius.control),
              side: BorderSide(color: open ? VmsColors.primary : VmsColors.borderInput),
            ),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(VmsRadius.control),
              child: SizedBox(
                height: VmsSize.control,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: VmsColors.textMeta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(value == null ? 'Any date' : formatDate(value),
                            style: VmsText.tabular(VmsText.body)),
                      ),
                      Icon(open ? Icons.expand_less : Icons.expand_more, size: 20, color: VmsColors.textMeta),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (open) ...[
            const SizedBox(height: 8),
            VmsDayPicker(enabledDays: days, selected: value, onChanged: onPick),
          ],
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      child: Material(
        color: selected ? VmsColors.nav : VmsColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VmsRadius.pill),
          side: BorderSide(color: selected ? VmsColors.nav : VmsColors.borderInput),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : VmsColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
