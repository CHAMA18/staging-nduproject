# Comprehensive Implementation Guide: AI Regenerate/Undo Across All Pages

## ✅ Completed Components

1. **Core Infrastructure:**
   - ✅ `FieldHistory` class in `project_data_model.dart`
   - ✅ `PageRegenerateAllButton` widget
   - ✅ `FieldRegenerateUndoButtons` widget  
   - ✅ `HoverableFieldControls` widget
   - ✅ Helper functions in `page_regenerate_all_button.dart`

2. **Screens with Full Implementation:**
   - ✅ `potential_solutions_screen.dart` - Has both page-level and field-level
   - ✅ `preferred_solution_analysis_screen.dart` - Has page-level
   - ✅ `risk_identification_screen.dart` - **JUST ADDED** page-level and field-level

## 🔧 Implementation Pattern for Remaining Screens

### Step 1: Add Imports
```dart
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/widgets/field_regenerate_undo_buttons.dart';
```

### Step 2: Add Page-Level Regenerate Button
Find the header/title row and add:
```dart
Row(
  children: [
    // ... existing title/header
    Expanded(child: /* existing description */),
    PageRegenerateAllButton(
      onRegenerateAll: () async {
        final confirmed = await showRegenerateAllConfirmation(context);
        if (confirmed && mounted) {
          await _regenerateAllContent();
        }
      },
      isLoading: _isRegenerating,
    ),
  ],
)
```

### Step 3: Add Field-Level Controls
Wrap AI-generated text fields with `HoverableFieldControls`:
```dart
HoverableFieldControls(
  isAiGenerated: true,
  canUndo: provider.canUndoField('field_key'),
  onRegenerate: () async {
    provider.addFieldToHistory('field_key', controller.text, isAiGenerated: true);
    await _regenerateField('field_key', controller);
  },
  onUndo: () async {
    final previousValue = provider.undoField('field_key');
    if (previousValue != null) {
      controller.text = previousValue;
      await provider.saveToFirebase(checkpoint: 'field_undo');
    }
  },
  child: TextField(controller: controller, ...),
)
```

## 📋 Screens Needing Implementation

### High Priority (Initiation Phase):
1. ✅ `risk_identification_screen.dart` - **DONE**
2. ⏳ `core_stakeholders_screen.dart` - **NEXT**
3. ⏳ `it_considerations_screen.dart`
4. ⏳ `infrastructure_considerations_screen.dart`
5. ⏳ `cost_analysis_screen.dart`

### Medium Priority (FEP Screens):
6. ⏳ `front_end_planning_requirements_screen.dart`
7. ⏳ `front_end_planning_risks_screen.dart`
8. ⏳ `front_end_planning_opportunities_screen.dart`
9. ⏳ All other FEP screens with AI content

### Lower Priority:
10. ⏳ Execution Plan screens
11. ⏳ Other screens with AI-generated content

## 🎯 Quick Implementation Checklist

For each screen:
- [ ] Add imports for regenerate widgets
- [ ] Add page-level regenerate button in header
- [ ] Implement `_regenerateAllContent()` method
- [ ] Wrap AI text fields with `HoverableFieldControls`
- [ ] Implement field-level regenerate methods
- [ ] Add field history tracking
- [ ] Test regenerate and undo functionality

## 🔍 Finding AI-Generated Fields

Look for:
- `OpenAiServiceSecure` usage
- `generateFepSectionText` calls
- `generateSolutionsFromBusinessCase` calls
- `generateRisksForSolutions` calls
- Text fields that get populated by AI
- Fields with "KAZ AI" buttons

## ⚠️ Important Notes

1. **Notes Fields**: Never add AI regeneration to notes fields - they must remain user-only
2. **History Tracking**: Always call `addFieldToHistory` before regenerating
3. **Auto-Save**: Always call `saveToFirebase` after regenerate/undo
4. **Confirmation**: Always show confirmation dialog for page-level regenerate
5. **Loading States**: Show loading indicators during regeneration
