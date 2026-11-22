import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// The one input decoration (44 px, radius 10, red border on error).
InputDecoration vmsInputDecoration({
  String? hint,
  bool hasError = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(VmsRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
    isDense: true,
    filled: true,
    fillColor: VmsColors.surface,
    contentPadding: contentPadding,
    semanticCounterText: '',
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    border: border(VmsColors.borderInput),
    enabledBorder: border(hasError ? VmsColors.danger : VmsColors.borderInput),
    focusedBorder: border(hasError ? VmsColors.danger : VmsColors.primary, 2),
    disabledBorder: border(VmsColors.divider),
  );
}

/// Label above the field; "Optional" instead of asterisks.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(text, style: VmsText.label)),
          if (optional) const Text('Optional', style: VmsText.meta),
        ],
      ),
    );
  }
}

/// Reserved 18 px line under every field so messages never shift the layout.
class FieldMessage extends StatelessWidget {
  const FieldMessage({super.key, this.error, this.helper, this.action});

  final String? error;
  final String? helper;

  /// Optional inline link after the error (e.g. "Open that vehicle").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 18),
      padding: const EdgeInsets.only(top: 4),
      child: error != null
          ? Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 6),
                    child: Icon(Icons.error_outline, size: 14, color: VmsColors.danger),
                  ),
                  Flexible(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w500,
                        color: VmsColors.danger,
                      ),
                    ),
                  ),
                  if (action != null) ...[const SizedBox(width: 8), action!],
                ],
              ),
            )
          : helper != null
              ? Text(helper!, style: VmsText.meta)
              : null,
    );
  }
}

/// Labelled 44 px text field with the VMS error treatment.
class VmsTextField extends StatelessWidget {
  const VmsTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.optional = false,
    this.error,
    this.helper,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
    this.prefixIcon,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.showLabel = true,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool optional;
  final String? error;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;
  final IconData? prefixIcon;
  final bool autofocus;
  final bool enabled;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  /// When false the label is only announced to screen readers (toolbar search).
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      style: const TextStyle(fontSize: 15, color: VmsColors.text),
      decoration: vmsInputDecoration(
        hint: hint,
        hasError: hasError,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18, color: VmsColors.textMeta),
        suffixIcon: suffix,
      ),
    );

    if (!showLabel) {
      return Semantics(label: label, textField: true, child: field);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(text: label, optional: optional),
        Semantics(label: label, child: field),
        FieldMessage(error: error, helper: helper),
      ],
    );
  }
}

class VmsOption<T> {
  const VmsOption(this.value, this.label);
  final T value;
  final String label;
}

/// Select styled like an input. [value] null shows [hint].
class VmsSelect<T> extends StatelessWidget {
  const VmsSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.error,
    this.focusNode,
    this.small = false,
    this.optional = false,
  });

  final List<VmsOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final String? error;
  final FocusNode? focusNode;
  final bool small;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final hasValue = options.any((o) => o.value == value);
    final box = Container(
      height: small ? VmsSize.controlSmall : VmsSize.control,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: VmsColors.surface,
        border: Border.all(color: error != null ? VmsColors.danger : VmsColors.borderInput),
        borderRadius: BorderRadius.circular(VmsRadius.control),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: hasValue ? value : null,
          focusNode: focusNode,
          isExpanded: true,
          hint: hint == null ? null : Text(hint!, style: const TextStyle(color: Color(0xFF9CA3AF))),
          icon: const Icon(Icons.expand_more, size: 20, color: VmsColors.textMeta),
          borderRadius: BorderRadius.circular(VmsRadius.group),
          dropdownColor: VmsColors.surface,
          style: TextStyle(fontSize: small ? 14 : 15, color: VmsColors.text),
          onChanged: onChanged,
          items: [
            for (final o in options) DropdownMenuItem<T>(value: o.value, child: Text(o.label)),
          ],
        ),
      ),
    );
    if (label == null) return box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(text: label!, optional: optional),
        box,
        FieldMessage(error: error),
      ],
    );
  }
}
