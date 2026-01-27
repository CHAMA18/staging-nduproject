import 'package:flutter/material.dart';

/// Unified list bullet: period "." per spec (prose fields must not use auto-bullet).
const String kListBullet = '. ';

/// Mixin that adds auto-bullet functionality for *list* fields.
/// Uses ". " (period + space). Do not use for prose (Notes, Scope, Value narrative).
class AutoBulletTextController extends TextEditingController {
  AutoBulletTextController({super.text}) {
    _setupListener();
  }

  void _setupListener() {
    addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final currentText = text;
    final selection = this.selection;
    const bullet = kListBullet;

    if (currentText.isEmpty) {
      value = TextEditingValue(
        text: bullet,
        selection: TextSelection.collapsed(offset: bullet.length),
      );
      return;
    }

    final textBeforeCursor = currentText.substring(0, selection.baseOffset);
    final lastNewlineIndex = textBeforeCursor.lastIndexOf('\n');

    if (lastNewlineIndex != -1) {
      final afterNewline = textBeforeCursor.substring(lastNewlineIndex + 1);
      if (afterNewline.trim().isEmpty && !afterNewline.startsWith(bullet)) {
        final newText = currentText.substring(0, lastNewlineIndex + 1) +
            bullet +
            currentText.substring(selection.baseOffset);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.baseOffset + bullet.length),
        );
        return;
      }
    }

    if (currentText.isNotEmpty && !currentText.startsWith(bullet) && !currentText.contains('\n')) {
      value = TextEditingValue(
        text: '$bullet$currentText',
        selection: TextSelection.collapsed(offset: selection.baseOffset + bullet.length),
      );
    }
  }

  @override
  void dispose() {
    removeListener(_handleTextChange);
    super.dispose();
  }
}

/// Extension for *list* fields only. Prose (Notes, Scope, Value narrative) must not use this.
extension AutoBulletExtension on TextEditingController {
  void enableAutoBullet() {
    addListener(_autoBulletListener);
  }

  void disableAutoBullet() {
    removeListener(_autoBulletListener);
  }

  void _autoBulletListener() {
    final currentText = text;
    final selection = this.selection;
    const bullet = kListBullet;

    if (currentText.isEmpty) {
      value = TextEditingValue(
        text: bullet,
        selection: TextSelection.collapsed(offset: bullet.length),
      );
      return;
    }

    final textBeforeCursor = currentText.substring(0, selection.baseOffset);
    final lastNewlineIndex = textBeforeCursor.lastIndexOf('\n');

    if (lastNewlineIndex != -1) {
      final afterNewline = textBeforeCursor.substring(lastNewlineIndex + 1);
      if (afterNewline.trim().isEmpty && !afterNewline.startsWith(bullet)) {
        final newText = currentText.substring(0, lastNewlineIndex + 1) +
            bullet +
            currentText.substring(selection.baseOffset);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.baseOffset + bullet.length),
        );
        return;
      }
    }

    if (currentText.isNotEmpty &&
        !currentText.contains('\n') &&
        !currentText.startsWith(bullet)) {
      value = TextEditingValue(
        text: '$bullet$currentText',
        selection: TextSelection.collapsed(offset: selection.baseOffset + bullet.length),
      );
    }
  }
}
