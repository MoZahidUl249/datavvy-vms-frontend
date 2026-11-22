import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../../domain/plate.dart';

/// Segmented vehicle number: Area · METRO · Class · Series · Number.
///
/// * auto-advance when a part is full; Space or `-` also advances
/// * a digit typed in Class moves to Series
/// * Backspace in an empty part goes back and deletes
/// * ← / → cross parts at the edges
/// * pasting a full number into any part fills every part
/// * METRO turns on automatically for metro areas unless the user changed it
class PlateInput extends StatefulWidget {
  const PlateInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
    this.areaFocusNode,
    this.error,
    this.errorAction,
    this.enabled = true,
    this.autofocus = false,
    this.onBlur,
  });

  final PlateParts value;
  final ValueChanged<PlateParts> onChanged;

  /// Enter in the last part (move to the next form field).
  final VoidCallback onSubmitted;
  final FocusNode? areaFocusNode;
  final String? error;
  final Widget? errorAction;
  final bool enabled;
  final bool autofocus;

  /// Focus left the whole plate group.
  final VoidCallback? onBlur;

  @override
  State<PlateInput> createState() => _PlateInputState();
}

enum _Part { area, cls, series, number }

class _PlateInputState extends State<PlateInput> {
  late final Map<_Part, TextEditingController> _c = {
    _Part.area: TextEditingController(text: widget.value.area),
    _Part.cls: TextEditingController(text: widget.value.cls),
    _Part.series: TextEditingController(text: widget.value.series),
    _Part.number: TextEditingController(text: widget.value.number),
  };
  late final FocusNode _ownAreaFocus = FocusNode();
  final Map<_Part, FocusNode> _f = {
    _Part.cls: FocusNode(),
    _Part.series: FocusNode(),
    _Part.number: FocusNode(),
  };
  late bool _metro = widget.value.metro;
  bool _metroTouched = false;

  FocusNode _focus(_Part p) => p == _Part.area ? (widget.areaFocusNode ?? _ownAreaFocus) : _f[p]!;

  static const _max = {_Part.area: 3, _Part.cls: 3, _Part.series: 2, _Part.number: 4};
  static final _letters = RegExp('[A-Z]');
  static final _digits = RegExp('[0-9]');
  static const _hints = {_Part.area: 'DHA', _Part.cls: 'GA', _Part.series: '11', _Part.number: '4582'};
  static const _labels = {_Part.area: 'Area', _Part.cls: 'Class', _Part.series: 'Series', _Part.number: 'Number'};
  static const _widths = {_Part.area: 78.0, _Part.cls: 70.0, _Part.series: 60.0, _Part.number: 84.0};

  @override
  void didUpdateWidget(PlateInput old) {
    super.didUpdateWidget(old);
    // External change (edit form loaded, reset): sync controllers.
    if (widget.value != _current) {
      _setText(_Part.area, widget.value.area);
      _setText(_Part.cls, widget.value.cls);
      _setText(_Part.series, widget.value.series);
      _setText(_Part.number, widget.value.number);
      _metro = widget.value.metro;
    }
  }

  void _setText(_Part p, String text) {
    if (_c[p]!.text != text) {
      _c[p]!.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    }
  }

  PlateParts get _current => PlateParts(
        area: _c[_Part.area]!.text,
        metro: _metro,
        cls: _c[_Part.cls]!.text,
        series: _c[_Part.series]!.text,
        number: _c[_Part.number]!.text,
      );

  void _emit() => widget.onChanged(_current);

  @override
  void dispose() {
    _flushTimer?.cancel();
    for (final c in _c.values) {
      c.dispose();
    }
    for (final f in _f.values) {
      f.dispose();
    }
    _ownAreaFocus.dispose();
    super.dispose();
  }

  _Part? _next(_Part p) => p.index + 1 < _Part.values.length ? _Part.values[p.index + 1] : null;
  _Part? _prev(_Part p) => p.index > 0 ? _Part.values[p.index - 1] : null;

  void _goTo(_Part? p, {bool atEnd = true}) {
    if (p == null) return;
    final node = _focus(p);
    node.requestFocus();
    final c = _c[p]!;
    c.selection = TextSelection.collapsed(offset: atEnd ? c.text.length : 0);
  }

  void _onChanged(_Part p, String text) {
    if (p == _Part.area && !_metroTouched && text.length == 3) {
      _metro = PlateParts.metroAreas.contains(text);
    }
    _emit();
    if (text.length == _max[p]!) {
      final next = _next(p);
      if (next != null) _goTo(next);
    }
  }

  /// Pasted text that is a whole plate fills every part.
  bool _tryPaste(String raw) {
    final parsed = PlateParts.tryParse(raw);
    if (parsed == null) return false;
    scheduleMicrotask(() {
      _setText(_Part.area, parsed.area);
      _setText(_Part.cls, parsed.cls);
      _setText(_Part.series, parsed.series);
      _setText(_Part.number, parsed.number);
      _metro = parsed.metro;
      _metroTouched = true;
      setState(() {});
      _emit();
      _goTo(_Part.number);
    });
    return true;
  }

  static bool _isDigitPart(_Part p) => p == _Part.series || p == _Part.number;

  /// Characters waiting to be added to a part (see [_carry]).
  final Map<_Part, String> _pending = {};
  Timer? _flushTimer;

  /// Characters a part can't keep (overflow past its length, or a digit typed
  /// into a letters box) belong to a later part.
  ///
  /// They are NOT written into that part straight away: right after focus
  /// moves, the browser's input for the new part still holds its old value,
  /// and the next keystroke would overwrite a value written now (that is how
  /// a fast "11" became "1"). Instead they wait in [_pending] and are joined
  /// to the next edit that reaches the part ([_takePending], called from its
  /// formatter), or written by a short timer if no key follows.
  void _carry(_Part from, String chars) {
    var target = _next(from);
    while (target != null) {
      final kindOk = (_isDigitPart(target) ? _digits : _letters).hasMatch(chars[0]);
      final used = _c[target]!.text.length + (_pending[target]?.length ?? 0);
      if (kindOk && used < _max[target]!) break;
      target = _next(target);
    }
    if (target == null) return;
    _pending[target] = (_pending[target] ?? '') + chars;
    _goTo(target);
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 150), _flushPending);
  }

  String _takePending(_Part p) => _pending.remove(p) ?? '';

  void _flushPending() {
    if (!mounted || _pending.isEmpty) return;
    final entries = Map.of(_pending);
    _pending.clear();
    for (final e in entries.entries) {
      final c = _c[e.key]!;
      final allowed = _isDigitPart(e.key) ? _digits : _letters;
      final add = e.value.split('').where(allowed.hasMatch).join();
      final room = _max[e.key]! - c.text.length;
      if (room <= 0 || add.isEmpty) continue;
      _setText(e.key, c.text + (add.length > room ? add.substring(0, room) : add));
      if (_c[e.key]!.text.length == _max[e.key]! && _next(e.key) != null) _goTo(_next(e.key));
    }
    _emit();
  }

  KeyEventResult _onKey(_Part p, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final c = _c[p]!;
    final key = event.logicalKey;
    final atStart = c.selection.baseOffset <= 0 && c.selection.isCollapsed;
    final atEnd = c.selection.baseOffset >= c.text.length && c.selection.isCollapsed;

    if (key == LogicalKeyboardKey.backspace && c.text.isEmpty) {
      final prev = _prev(p);
      if (prev == null) return KeyEventResult.ignored;
      final pc = _c[prev]!;
      if (pc.text.isNotEmpty) _setText(prev, pc.text.substring(0, pc.text.length - 1));
      _goTo(prev);
      _emit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && atStart && _prev(p) != null) {
      _goTo(_prev(p));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight && atEnd && _next(p) != null) {
      _goTo(_next(p), atEnd: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (!hasFocus) widget.onBlur?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FieldLabel(text: 'Vehicle number'),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VmsColors.surfaceSubtle,
              border: Border.all(color: hasError ? VmsColors.danger : VmsColors.borderPlate),
              borderRadius: BorderRadius.circular(VmsRadius.group),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _part(_Part.area),
                _metroToggle(),
                _part(_Part.cls),
                _part(_Part.series),
                _part(_Part.number),
              ],
            ),
          ),
          FieldMessage(
            error: widget.error,
            helper: 'Paste a full number into any box to fill them all.',
            action: widget.errorAction,
          ),
        ],
      ),
    );
  }

  Widget _part(_Part p) {
    final isDigits = p == _Part.series || p == _Part.number;
    return SizedBox(
      width: _widths[p],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_labels[p]!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VmsColors.textMeta)),
          const SizedBox(height: 4),
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (node, event) => _onKey(p, event),
            child: TextField(
              controller: _c[p],
              focusNode: _focus(p),
              enabled: widget.enabled,
              autofocus: widget.autofocus && p == _Part.area,
              keyboardType: isDigits ? TextInputType.number : TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.center,
              style: VmsText.tabular(const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
              inputFormatters: [
                _PartFormatter(
                  maxLength: _max[p]!,
                  allowed: isDigits ? _digits : _letters,
                  onSeparator: () => _goTo(_next(p)),
                  onPaste: _tryPaste,
                  onRejected: (chars) => _carry(p, chars),
                  takePending: () => _takePending(p),
                ),
              ],
              decoration: vmsInputDecoration(
                hint: _hints[p],
                hasError: widget.error != null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              ),
              onChanged: (text) => _onChanged(p, text),
              onSubmitted: (_) {
                // Ctrl/⌘+Enter saves from any box; plain Enter moves on.
                final k = HardwareKeyboard.instance;
                if (p == _Part.number || k.isMetaPressed || k.isControlPressed) {
                  widget.onSubmitted();
                } else {
                  _goTo(_next(p));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metroToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Metro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VmsColors.textMeta)),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          toggled: _metro,
          label: 'METRO',
          child: Material(
            color: _metro ? VmsColors.nav : VmsColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VmsRadius.control),
              side: BorderSide(color: _metro ? VmsColors.nav : VmsColors.borderInput),
            ),
            child: InkWell(
              canRequestFocus: false,
              onTap: widget.enabled
                  ? () {
                      setState(() {
                        _metro = !_metro;
                        _metroTouched = true;
                      });
                      _emit();
                    }
                  : null,
              borderRadius: BorderRadius.circular(VmsRadius.control),
              child: SizedBox(
                width: 76,
                height: 46,
                child: Center(
                  child: Text(
                    'METRO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _metro ? Colors.white : VmsColors.textMeta,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Uppercases, keeps only allowed characters, caps length, and reports
/// separators, pastes and rejected characters back to the plate input.
class _PartFormatter extends TextInputFormatter {
  _PartFormatter({
    required this.maxLength,
    required this.allowed,
    required this.onSeparator,
    required this.onPaste,
    this.onRejected,
    this.takePending,
  });

  final int maxLength;
  final RegExp allowed;
  final VoidCallback onSeparator;
  final bool Function(String raw) onPaste;
  final void Function(String rejected)? onRejected;

  /// Characters carried in from an earlier part, to go before what was typed.
  final String Function()? takePending;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var raw = newValue.text;
    if (raw.length - oldValue.text.length > 2 && onPaste(raw)) return oldValue;
    final pending = takePending?.call() ?? '';
    if (pending.isNotEmpty) {
      final old = oldValue.text;
      raw = raw.startsWith(old) ? old + pending + raw.substring(old.length) : pending + raw;
    }

    final upper = raw.toUpperCase();
    final hadSeparator = upper.contains(RegExp(r'[\s-]'));
    final kept = StringBuffer();
    final rejected = StringBuffer();
    for (final ch in upper.split('')) {
      if (RegExp(r'[\s-]').hasMatch(ch)) continue;
      // Once the part is full or a wrong-kind character arrives, everything
      // after it is passed on so the order of what was typed is preserved.
      if (rejected.isEmpty && allowed.hasMatch(ch) && kept.length < maxLength) {
        kept.write(ch);
      } else {
        rejected.write(ch);
      }
    }
    final text = kept.toString();

    if (hadSeparator && text.isNotEmpty) scheduleMicrotask(onSeparator);
    final r = rejected.toString();
    if (r.isNotEmpty && onRejected != null) scheduleMicrotask(() => onRejected!(r));

    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
