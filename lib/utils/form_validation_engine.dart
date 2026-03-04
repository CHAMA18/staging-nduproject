import 'package:flutter/material.dart';

enum ValidationFieldType {
  text,
  dropdown,
  date,
  multiSelect,
  fileUpload,
  custom,
}

class ValidationFieldRule {
  const ValidationFieldRule({
    required this.id,
    required this.label,
    this.value,
    this.type = ValidationFieldType.text,
    this.section,
    this.required = true,
    this.errorText,
    this.fieldKey,
    this.focusNode,
    this.isMissing,
  });

  final String id;
  final String label;
  final dynamic value;
  final ValidationFieldType type;
  final String? section;
  final bool required;
  final String? errorText;
  final GlobalKey? fieldKey;
  final FocusNode? focusNode;
  final bool Function(ValidationFieldRule field)? isMissing;
}

class ValidationIssue {
  const ValidationIssue({
    required this.id,
    required this.label,
    required this.errorText,
    this.section,
    this.fieldKey,
    this.focusNode,
  });

  final String id;
  final String label;
  final String errorText;
  final String? section;
  final GlobalKey? fieldKey;
  final FocusNode? focusNode;
}

class FormValidationResult {
  const FormValidationResult(this.issues);

  final List<ValidationIssue> issues;

  bool get isValid =>
      !FormValidationEngine.enforceBlockingValidation || issues.isEmpty;
  bool get hasIssues => issues.isNotEmpty;
  ValidationIssue? get firstIssue => issues.isEmpty ? null : issues.first;

  Map<String, String> get errorByFieldId {
    final errors = <String, String>{};
    for (final issue in issues) {
      errors[issue.id] = issue.errorText;
    }
    return errors;
  }

  Map<String, List<ValidationIssue>> get issuesBySection {
    final grouped = <String, List<ValidationIssue>>{};
    for (final issue in issues) {
      final key = (issue.section ?? '').trim();
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => <ValidationIssue>[]).add(issue);
    }
    return grouped;
  }
}

class FormValidationEngine {
  /// When false, validation remains available for UX hints but will not block
  /// navigation/actions that depend on `FormValidationResult.isValid`.
  static bool enforceBlockingValidation = false;

  static FormValidationResult validateForm(List<ValidationFieldRule> fields) {
    final issues = <ValidationIssue>[];

    for (final field in fields) {
      if (!field.required) continue;

      final missing = field.isMissing != null
          ? field.isMissing!(field)
          : _isMissingByType(field);
      if (!missing) continue;

      issues.add(
        ValidationIssue(
          id: field.id,
          label: field.label,
          section: field.section,
          fieldKey: field.fieldKey,
          focusNode: field.focusNode,
          errorText: field.errorText ?? 'This field is required',
        ),
      );
    }

    return FormValidationResult(issues);
  }

  static String buildMissingFieldsMessage(
    FormValidationResult result, {
    int maxItems = 6,
    String intro = 'Please complete the following before continuing:',
  }) {
    if (result.issues.isEmpty) return '';

    final sections = result.issuesBySection.keys.toList(growable: false);
    final header = sections.length == 1
        ? 'The ${sections.first} section is incomplete. Please fill in all required fields.'
        : intro;

    final uniqueLabels = <String>[];
    final seen = <String>{};
    for (final issue in result.issues) {
      if (seen.add(issue.label)) {
        uniqueLabels.add(issue.label);
      }
    }

    final visibleLabels = uniqueLabels.take(maxItems).toList(growable: false);
    final overflow = uniqueLabels.length - visibleLabels.length;
    final bullets = <String>[
      for (final label in visibleLabels) '• $label',
      if (overflow > 0) '• +$overflow more',
    ].join('\n');

    return '$header\n$bullets';
  }

  static void showValidationSnackBar(
    BuildContext context,
    FormValidationResult result, {
    int maxItems = 6,
    String intro = 'Please complete the following before continuing:',
    Duration duration = const Duration(seconds: 5),
    Color backgroundColor = const Color(0xFFEF4444),
  }) {
    if (!context.mounted || result.issues.isEmpty) return;
    final message = buildMissingFieldsMessage(
      result,
      maxItems: maxItems,
      intro: intro,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
  }

  static Future<void> scrollToFirstIssue(
    FormValidationResult result, {
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) async {
    final first = result.firstIssue;
    if (first == null) return;

    final issueContext = first.fieldKey?.currentContext;
    if (issueContext != null) {
      await Scrollable.ensureVisible(
        issueContext,
        alignment: 0.12,
        duration: duration,
        curve: curve,
      );
    }

    final focusNode = first.focusNode;
    if (focusNode != null && focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  }

  static bool _isMissingByType(ValidationFieldRule field) {
    switch (field.type) {
      case ValidationFieldType.text:
        return !_hasText(field.value);
      case ValidationFieldType.dropdown:
      case ValidationFieldType.date:
      case ValidationFieldType.custom:
        return !_hasValue(field.value);
      case ValidationFieldType.multiSelect:
      case ValidationFieldType.fileUpload:
        return !_hasCollectionValue(field.value);
    }
  }

  static bool _hasText(dynamic value) {
    return value is String && value.trim().isNotEmpty;
  }

  static bool _hasCollectionValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  static bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is bool) return value;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}
