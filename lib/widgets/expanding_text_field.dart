import 'package:flutter/material.dart';

/// A drop-in TextField that grows vertically as the user types.
/// - No internal scrolling; the enclosing page scrolls instead.
/// - By default starts with [minLines] and expands with content (maxLines=null).
/// - Use for multiline content such as notes, descriptions, comments.
class ExpandingTextField extends StatelessWidget {
  const ExpandingTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.minLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.decoration,
    this.style,
    this.enabled,
    this.onEditingComplete,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final int minLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool? enabled;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final InputDecoration baseDecoration = decoration ?? const InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: null, // allow vertical growth with content
      decoration: baseDecoration.copyWith(
        hintText: hintText ?? baseDecoration.hintText,
        labelText: labelText ?? baseDecoration.labelText,
      ),
      style: style,
      enabled: enabled,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
    );
  }
}

/// A Form-compatible variant using TextFormField.
class ExpandingTextFormField extends StatelessWidget {
  const ExpandingTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.minLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.decoration,
    this.style,
    this.enabled,
    this.validator,
    this.onSaved,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autovalidateMode,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final int minLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool? enabled;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final InputDecoration baseDecoration = decoration ?? const InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: null,
      decoration: baseDecoration.copyWith(
        hintText: hintText ?? baseDecoration.hintText,
        labelText: labelText ?? baseDecoration.labelText,
      ),
      style: style,
      enabled: enabled,
      validator: validator,
      onSaved: onSaved,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
    );
  }
}
