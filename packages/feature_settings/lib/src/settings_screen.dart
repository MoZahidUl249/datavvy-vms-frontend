import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_catalog/vms_catalog.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

/// Settings-style sections. Changes apply immediately (no Save button).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.catalog,
    required this.preferences,
    required this.isAdmin,
    this.initialSection,
  });

  final CatalogRepository catalog;
  final UiPreferences preferences;
  final bool isAdmin;

  /// `types`, `columns` or `cards` — scrolled into view on open.
  final String? initialSection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keys = {for (final s in ['types', 'columns', 'cards']) s: GlobalKey()};

  @override
  void initState() {
    super.initState();
    widget.catalog.loadAll(force: true);
    final target = _keys[widget.initialSection];
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = target.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.catalog, widget.preferences]),
      builder: (context, _) => VmsPage(
        maxWidth: VmsSize.contentForm,
        crumbs: const [Crumb('Settings')],
        title: 'Settings',
        subtitle: 'Lists and display options for your workspace. Changes apply right away.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CatalogSection(
              key: _keys['types'],
              kind: CatalogKind.vehicleType,
              title: 'Vehicle types',
              description: 'The Type choices on the vehicle form and in the list filters. Types in use can\'t be removed or renamed.',
              placeholder: 'Add a type, like Ambulance',
              catalog: widget.catalog,
              canEdit: widget.isAdmin,
            ),
            const SizedBox(height: VmsSpace.s4),
            _switchSection(
              key: _keys['columns'],
              title: 'Vehicle list columns',
              description: 'Every field can have its own column. Brand and model that are switched off '
                  'show under the vehicle number instead.',
              rows: [
                for (final c in VehicleColumn.values)
                  (c.label, widget.preferences.showsColumn(c), (bool v) => widget.preferences.setColumn(c, v)),
              ],
            ),
            const SizedBox(height: VmsSpace.s4),
            _switchSection(
              key: _keys['cards'],
              title: 'Dashboard cards',
              description: 'Totals are always shown. Choose which other cards appear on the dashboard.',
              rows: [
                for (final c in DashboardCard.values)
                  (c.label, widget.preferences.showsCard(c), (bool v) => widget.preferences.setCard(c, v)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchSection({
    required Key? key,
    required String title,
    required String description,
    required List<(String, bool, ValueChanged<bool>)> rows,
  }) {
    return VmsCard(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: title, description: description),
          for (final (label, on, onChanged) in rows)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: VmsSpace.s5),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: VmsColors.divider))),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: VmsText.body)),
                  VmsSwitch(value: on, onChanged: onChanged, semanticLabel: label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: VmsText.h2)),
          const SizedBox(height: 4),
          Text(description, style: VmsText.meta),
        ],
      ),
    );
  }
}

/// Chips with usage counts; add via input + Enter; values in use (or the
/// last one) can't be removed.
class _CatalogSection extends StatefulWidget {
  const _CatalogSection({
    super.key,
    required this.kind,
    required this.title,
    required this.description,
    required this.placeholder,
    required this.catalog,
    required this.canEdit,
  });

  final CatalogKind kind;
  final String title;
  final String description;
  final String placeholder;
  final CatalogRepository catalog;
  final bool canEdit;

  @override
  State<_CatalogSection> createState() => _CatalogSectionState();
}

class _CatalogSectionState extends State<_CatalogSection> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _input.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Type a name first, then press Enter.');
      return;
    }
    final exists = widget.catalog.items(widget.kind).any((i) => i.name.toLowerCase() == name.toLowerCase());
    if (exists) {
      setState(() => _error = '$name is already in the list.');
      return;
    }
    setState(() => _busy = true);
    final result = await widget.catalog.add(widget.kind, name);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok():
          _input.clear();
          _error = null;
        case Err(:final error):
          _error = error.fieldErrors['name'] ?? error.message;
      }
    });
    _focus.requestFocus();
  }

  Future<void> _remove(CatalogItem item) async {
    final result = await widget.catalog.remove(widget.kind, item.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        showVmsToast(context, '${item.name} removed.');
      case Err(:final error):
        showVmsToast(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.catalog.items(widget.kind);
    final onlyOne = items.length <= 1;
    return VmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: widget.title, description: widget.description),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!widget.catalog.isLoaded(widget.kind))
                      for (var i = 0; i < 4; i++) const Skeleton(width: 90, height: 32, radius: 999),
                    for (final item in items)
                      VmsChip(
                        label: item.name,
                        trailing: '${item.usageCount}',
                        removeTooltip: item.inUse
                            ? '${item.name} is used by ${item.usageCount} vehicle(s)'
                            : onlyOne
                                ? 'Keep at least one'
                                : 'Remove ${item.name}',
                        onRemove: widget.canEdit && !item.inUse && !onlyOne ? () => _remove(item) : null,
                      ),
                  ],
                ),
                if (widget.canEdit) ...[
                  const SizedBox(height: VmsSpace.s4),
                  SizedBox(
                    width: 360,
                    child: VmsTextField(
                      label: 'Add ${widget.kind.label.toLowerCase()}',
                      controller: _input,
                      focusNode: _focus,
                      hint: widget.placeholder,
                      enabled: !_busy,
                      error: _error,
                      helper: 'Press Enter to add. Values in use can\'t be removed.',
                      textInputAction: TextInputAction.done,
                      inputFormatters: [LengthLimitingTextInputFormatter(60)],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Only admins can change these lists.', style: VmsText.meta),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
