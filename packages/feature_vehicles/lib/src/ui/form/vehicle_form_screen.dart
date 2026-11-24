import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_catalog/vms_catalog.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../../data/vehicle_models.dart';
import 'plate_input.dart';
import 'vehicle_form_view_model.dart';

/// Register / Edit vehicle. One card, three sections, keyboard-only flow:
/// Enter = next field · Ctrl/⌘+Enter = save · Esc = cancel.
class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({
    super.key,
    required this.createViewModel,
    required this.catalog,
    required this.canManage,
  });

  final VehicleFormViewModel Function() createViewModel;
  final CatalogRepository catalog;
  final bool canManage;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  late final VehicleFormViewModel _vm = widget.createViewModel();

  final _focus = {for (final f in VehicleField.values) f: FocusNode()};
  final _saveFocus = FocusNode();

  final _company = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();

  bool get _readOnly => !widget.canManage;

  @override
  void initState() {
    super.initState();
    widget.catalog.loadAll();
    _vm.addListener(_syncControllers);
    _vm.load().then((_) {
      // Focus starts in Area (register) or Company (edit), after the form is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _readOnly) return;
        (_vm.isEdit ? _focus[VehicleField.company]! : _focus[VehicleField.vehicleNumber]!).requestFocus();
      });
    });
    // The plate reports its own blur (focus moving between its parts is not a blur).
    for (final entry in _focus.entries.where((e) => e.key != VehicleField.vehicleNumber)) {
      var hadFocus = false;
      entry.value.addListener(() {
        // Only a real blur counts: a field that never had focus stays untouched.
        if (entry.value.hasFocus) {
          hadFocus = true;
        } else if (hadFocus) {
          _vm.touch(entry.key);
        }
      });
    }
  }

  /// Pushes view-model values into text controllers after load / reload.
  void _syncControllers() {
    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_company, _vm.company);
    sync(_brand, _vm.brand);
    sync(_model, _vm.model);
  }

  @override
  void dispose() {
    _vm.removeListener(_syncControllers);
    _vm.dispose();
    for (final f in _focus.values) {
      f.dispose();
    }
    _saveFocus.dispose();
    for (final c in [_company, _brand, _model]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cancel() => context.go(_vm.isEdit && _vm.vehicleId != null ? AppRoutes.vehicleDetail(_vm.vehicleId!) : AppRoutes.vehicles);

  /// Enter moves to [next]; Ctrl/⌘+Enter saves from any text field.
  void _saveOr(VehicleField next) {
    final k = HardwareKeyboard.instance;
    if (k.isControlPressed || k.isMetaPressed) {
      _save();
    } else {
      _focus[next]!.requestFocus();
    }
  }

  Future<void> _save() async {
    if (_readOnly) return;
    final saved = await _vm.save();
    if (!mounted) return;
    if (saved == null) {
      final first = _vm.problems.isEmpty ? null : _vm.problems.first.$1;
      if (first != null) _focus[first]!.requestFocus();
      return;
    }
    showVmsToast(context, _vm.isEdit ? 'Changes saved.' : '${saved.vehicleNumber} registered.');
    context.go(_vm.isEdit ? AppRoutes.vehicleDetail(saved.id) : AppRoutes.vehiclesWhere(saved: saved.id));
  }

  Future<void> _delete() async {
    final number = _vm.original?.vehicleNumber ?? 'this vehicle';
    final ok = await showVmsConfirm(
      context,
      title: 'Delete $number?',
      message: 'The vehicle is removed permanently from the list and dashboard.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    final result = await _vm.delete();
    if (!mounted) return;
    switch (result) {
      case Ok():
        showVmsToast(context, '$number deleted.');
        context.go(AppRoutes.vehicles);
      case Err(:final error):
        showVmsToast(context, error.message);
    }
  }

  /// Wraps non-text controls so Enter moves on instead of activating them.
  Widget _enterToNext(FocusNode next, Widget child) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        final k = HardwareKeyboard.instance;
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
            !k.isControlPressed &&
            !k.isMetaPressed) {
          next.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([_vm, widget.catalog]),
        builder: (context, _) {
          final title = _vm.isEdit ? (_vm.original?.vehicleNumber ?? 'Edit vehicle') : 'Register vehicle';
          return VmsPage(
            maxWidth: VmsSize.contentForm,
            crumbs: _vm.isEdit
                ? [
                    Crumb('Vehicles', onTap: () => context.go(AppRoutes.vehicles)),
                    Crumb(title, onTap: _cancel),
                    const Crumb('Edit'),
                  ]
                : [Crumb('Vehicles', onTap: _cancel), const Crumb('Register vehicle')],
            title: _vm.isEdit ? 'Edit vehicle' : 'Register vehicle',
            subtitle: _vm.isEdit
                ? 'Update the details of $title.'
                : 'Add a vehicle to your fleet.',
            below: _readOnly ? null : const _ShortcutHints(),
            body: _body(context),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_vm.loading) {
      return const VmsCard(
        padding: EdgeInsets.all(VmsSpace.s5),
        child: Column(
          children: [
            Skeleton(height: 44),
            SizedBox(height: 24),
            Skeleton(height: 44),
            SizedBox(height: 24),
            Skeleton(height: 44),
          ],
        ),
      );
    }
    if (_vm.loadError != null) {
      return ErrorBanner(
        message: _vm.loadError!.status == 404 ? 'This vehicle no longer exists.' : _vm.loadError!.message,
        actionLabel: 'Back to vehicles',
        onAction: _cancel,
      );
    }
    final problems = _vm.submitted ? _vm.problems : const <(VehicleField, String)>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_vm.bannerError != null) ...[
          ErrorBanner(
            message: _vm.bannerError!,
            actionLabel: _vm.staleVersion ? 'Reload' : null,
            onAction: _vm.staleVersion ? _vm.reload : null,
          ),
          const SizedBox(height: VmsSpace.s4),
        ] else if (problems.isNotEmpty) ...[
          ErrorBanner(
            message: problems.length == 1 ? 'Fix 1 thing to save.' : 'Fix ${problems.length} things to save.',
            children: [
              for (final (field, message) in problems)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                    onPressed: () => _focus[field]!.requestFocus(),
                    child: Text(message, style: const TextStyle(fontSize: 13, color: VmsColors.dangerText)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VmsSpace.s4),
        ],
        VmsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section('Identification', 'The vehicle number and the company it belongs to.', _identification()),
              const Divider(height: 1, color: VmsColors.divider),
              _section('Vehicle details', 'What kind of vehicle it is.', _details()),
              const Divider(height: 1, color: VmsColors.divider),
              _section('Status', 'Inactive and maintenance vehicles stay on record.', _statusField()),
              _footer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, String hint, Widget fields) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 640;
      final label = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VmsText.section),
          const SizedBox(height: 4),
          Text(hint, style: VmsText.meta),
        ],
      );
      return Padding(
        padding: const EdgeInsets.all(VmsSpace.s5),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 200, child: label),
                  const SizedBox(width: VmsSpace.s5),
                  Expanded(child: fields),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [label, const SizedBox(height: VmsSpace.s4), fields],
              ),
      );
    });
  }

  Widget _identification() {
    final dup = _vm.duplicate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlateInput(
          value: _vm.plate,
          enabled: !_readOnly,
          areaFocusNode: _focus[VehicleField.vehicleNumber],
          error: _vm.errorFor(VehicleField.vehicleNumber),
          errorAction: dup != null && !dup.available && dup.existingId != null
              ? TextButton(
                  onPressed: () => context.go(AppRoutes.vehicleDetail(dup.existingId!)),
                  child: const Text('Open that vehicle'),
                )
              : null,
          onChanged: _vm.setPlate,
          onBlur: () => _vm.touch(VehicleField.vehicleNumber),
          onSubmitted: () => _saveOr(VehicleField.company),
        ),
        const SizedBox(height: VmsSpace.s2),
        VmsTextField(
          label: 'Company',
          enabled: !_readOnly,
          controller: _company,
          focusNode: _focus[VehicleField.company],
          hint: 'Datavvy Logistics',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          error: _vm.errorFor(VehicleField.company),
          onChanged: _vm.setCompany,
          onSubmitted: (_) => _saveOr(VehicleField.type),
        ),
      ],
    );
  }

  Widget _details() {
    final types = widget.catalog.items(CatalogKind.vehicleType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _enterToNext(
          _focus[VehicleField.brand]!,
          VmsSelect<String>(
            label: 'Type',
            hint: 'Choose a type',
            focusNode: _focus[VehicleField.type],
            value: _vm.type,
            error: _vm.errorFor(VehicleField.type),
            options: [for (final t in types) VmsOption(t.name, t.name)],
            onChanged: _readOnly ? null : _vm.setType,
          ),
        ),
        Wrap(
          spacing: VmsSpace.s4,
          children: [
            SizedBox(
              width: 260,
              child: VmsTextField(
                label: 'Brand',
                enabled: !_readOnly,
                controller: _brand,
                focusNode: _focus[VehicleField.brand],
                hint: 'Toyota',
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                error: _vm.errorFor(VehicleField.brand),
                onChanged: _vm.setBrand,
                onSubmitted: (_) => _saveOr(VehicleField.model),
              ),
            ),
            SizedBox(
              width: 260,
              child: VmsTextField(
                label: 'Model',
                enabled: !_readOnly,
                controller: _model,
                focusNode: _focus[VehicleField.model],
                hint: 'Hiace',
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                error: _vm.errorFor(VehicleField.model),
                onChanged: _vm.setModel,
                onSubmitted: (_) => _saveOr(VehicleField.status),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Status as a segmented radio group: ← → pick, Enter goes to Save.
  Widget _statusField() {
    const options = VehicleStatus.values;
    final node = _focus[VehicleField.status]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel(text: 'Status'),
        Align(
          alignment: Alignment.centerLeft,
          child: Focus(
            focusNode: node,
            onKeyEvent: (n, event) {
              if (event is! KeyDownEvent || _readOnly) return KeyEventResult.ignored;
              final i = options.indexOf(_vm.status);
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.arrowDown) {
                _vm.setStatus(options[(i + 1) % options.length]);
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowUp) {
                _vm.setStatus(options[(i - 1 + options.length) % options.length]);
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isControlPressed &&
                  !HardwareKeyboard.instance.isMetaPressed) {
                _saveFocus.requestFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: ListenableBuilder(
              listenable: node,
              builder: (context, child) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VmsRadius.group),
                  border: Border.all(color: node.hasFocus ? VmsColors.primary : Colors.transparent, width: 2),
                ),
                child: child,
              ),
              child: VmsSegmented<VehicleStatus>(
                small: false,
                semanticLabel: 'Status',
                selected: _vm.status,
                onChanged: _readOnly ? null : _vm.setStatus,
                segments: [for (final s in options) VmsSegment(value: s, label: s.label)],
              ),
            ),
          ),
        ),
        const FieldMessage(helper: 'Use ← → to pick, Enter to go to Save.'),
      ],
    );
  }

  Widget _footer() {
    final noChanges = _vm.isEdit && !_vm.hasChanges;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VmsSpace.s5, vertical: VmsSpace.s4),
      decoration: const BoxDecoration(
        color: VmsColors.surfaceSubtle,
        border: Border(top: BorderSide(color: VmsColors.divider)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: VmsSpace.s3,
        runSpacing: VmsSpace.s3,
        children: [
          if (_vm.isEdit && !_readOnly)
            VmsButton(
              label: 'Delete vehicle',
              variant: VmsButtonVariant.destructiveText,
              loading: _vm.deleting,
              onPressed: _delete,
            )
          else if (_readOnly)
            const Text('View only — ask an admin or fleet manager to make changes.', style: VmsText.meta)
          else
            const SizedBox.shrink(),
          Wrap(
            spacing: VmsSpace.s3,
            children: [
              VmsButton(label: _readOnly ? 'Back' : 'Cancel', variant: VmsButtonVariant.secondary, onPressed: _cancel),
              if (!_readOnly)
                VmsButton(
                  label: noChanges ? 'No changes' : (_vm.isEdit ? 'Save changes' : 'Register vehicle'),
                  focusNode: _saveFocus,
                  loading: _vm.saving,
                  onPressed: noChanges ? null : _save,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutHints extends StatelessWidget {
  const _ShortcutHints();

  @override
  Widget build(BuildContext context) {
    final mac = Theme.of(context).platform == TargetPlatform.macOS;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          const KbdHint(keys: 'Enter', label: 'next field'),
          KbdHint(keys: mac ? '⌘ Enter' : 'Ctrl Enter', label: 'save'),
          const KbdHint(keys: 'Esc', label: 'cancel'),
        ],
      ),
    );
  }
}
