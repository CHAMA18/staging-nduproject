# Business Case Modules - Deep Gap Analysis

**Date:** January 27, 2026  
**Objective:** Comprehensive audit of Business Case modules against specified requirements

---

## Executive Summary

This document identifies **all gaps** between current implementation and the specified requirements for Business Case modules. Each gap is categorized, prioritized, and includes specific file locations and line numbers where applicable.

---

## 1. Universal Text Field & Icon Refinement

### 1.1 Icon Ergonomics - Relocate Undo/Regenerate Icons

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Icons are positioned **inside text fields** using `Positioned` widgets (see `lib/screens/potential_solutions_screen.dart:1610-1632`)
- Icons overlay text content, potentially obstructing typing
- `HoverableFieldControls` widget exists (`lib/widgets/field_regenerate_undo_buttons.dart:63-134`) but uses `Padding(right: 88)` which reserves space but icons still positioned inside field boundaries

**Gaps Identified:**

1. **`lib/screens/potential_solutions_screen.dart`** (Lines 1609-1632)
   - ❌ Icons positioned `right: 8, top: 8` **inside** text field container
   - ❌ Icons can overlap text content
   - ❌ No floating action row above field

2. **`lib/widgets/field_regenerate_undo_buttons.dart`** (Lines 63-134)
   - ⚠️ `HoverableFieldControls` uses `AnimatedPositioned` with `right: 8, top: 4`
   - ⚠️ Icons positioned within field boundaries, not above
   - ❌ Missing "subtle action row floating neatly above top-right corner"

3. **`lib/screens/front_end_planning_requirements_screen.dart`** (Lines 640-675)
   - ❌ Icons positioned inside text field using `Positioned` widget
   - ❌ Same obstruction issue

**Required Changes:**
- Move icons to floating row **above** text field (not inside)
- Use `Stack` with `Positioned` widget positioned **outside** field container
- Ensure icons never overlap text input area
- Implement clean suffix container alternative if floating row not feasible

---

### 1.2 Auto-Bulleting Logic

**Status:** ⚠️ **PARTIAL GAP**

**Current Implementation:**
- `AutoBulletTextController` exists (`lib/utils/auto_bullet_text_controller.dart`)
- Some fields use `.enableAutoBullet()` method
- Bullet style varies (hyphens, circles, periods)

**Gaps Identified:**

1. **List Fields - Unified Period Bullet**
   - ❌ **`lib/screens/it_considerations_screen.dart`**: Uses hyphen bullets (`-`) instead of period (`.`)
   - ❌ **`lib/screens/infrastructure_considerations_screen.dart`**: Bullet style inconsistent
   - ❌ **`lib/screens/core_stakeholders_screen.dart`**: Uses auto-bullet but style not verified as period
   - ⚠️ **`lib/utils/auto_bullet_text_controller.dart`**: Need to verify bullet character is period (`.`)

2. **Prose Fields - No Auto-Bullets**
   - ✅ **`lib/screens/core_stakeholders_screen.dart`** (Line 85): Notes field correctly has no auto-bullet
   - ✅ **`lib/screens/potential_solutions_screen.dart`**: Notes field correctly initialized without auto-bullet
   - ⚠️ Need audit of all "Notes" fields across all Business Case screens

**Required Changes:**
- Audit all list fields (Risks, Stakeholders, Infrastructure) to ensure period (`.`) bullet
- Verify all prose fields (Notes, Scope Statement) have NO auto-bullets
- Update `AutoBulletTextController` to enforce period bullet for list fields

---

### 1.3 Notes Sections - AI Never Populates

**Status:** ⚠️ **NEEDS VERIFICATION**

**Current Implementation:**
- Notes fields initialized as empty in most screens
- Some screens may auto-populate notes on AI generation

**Gaps Identified:**

1. **`lib/screens/preferred_solution_analysis_screen.dart`**
   - ⚠️ `_notesController` initialized from `widget.notes` (Line 82)
   - ⚠️ Need to verify AI never populates this field

2. **`lib/screens/cost_analysis_screen.dart`**
   - ⚠️ Notes field may be populated during AI generation
   - Need to audit all AI generation methods to exclude Notes fields

**Required Changes:**
- Add explicit check in all AI generation methods to skip Notes fields
- Ensure Notes fields always initialized as empty strings
- Add validation to prevent AI population of Notes fields

---

### 1.4 Local Undo/Regen - Field-Specific Controls

**Status:** ⚠️ **PARTIALLY IMPLEMENTED**

**Current Implementation:**
- `FieldRegenerateUndoButtons` widget exists
- `HoverableFieldControls` wrapper exists
- Field history tracking exists in `ProjectDataModel` (`FieldHistory` class)

**Gaps Identified:**

1. **Field History Integration**
   - ✅ `FieldHistory` class exists in `lib/models/project_data_model.dart` (Lines 2457-2506)
   - ✅ `addFieldToHistory()`, `undoField()`, `canUndoField()` methods exist
   - ⚠️ Not all screens use field history tracking
   - ❌ Some screens use local undo stacks instead of `FieldHistory`

2. **Field-Specific Regenerate**
   - ⚠️ Regenerate functionality exists but may not be field-specific
   - Need to verify each field has its own regenerate callback

**Required Changes:**
- Ensure all text fields use `FieldHistory` for undo tracking
- Verify each field has dedicated regenerate callback
- Remove local undo stack implementations in favor of `FieldHistory`

---

## 2. Potential Solutions & Card-Based UI

### 2.1 Dynamic Solution Management - Delete Solution

**Status:** ⚠️ **PARTIALLY IMPLEMENTED**

**Current Implementation:**
- Delete functionality exists in `lib/screens/potential_solutions_screen.dart`
- Delete button visible on solution rows (Line ~1600+)
- Admin-only deletion in some cases

**Gaps Identified:**

1. **`lib/screens/potential_solutions_screen.dart`**
   - ✅ Delete button exists
   - ⚠️ Need to verify "Add Solution" button re-enables after deletion
   - ⚠️ Need to verify limit enforcement (max 3 customers, max 5 admins)
   - ❌ Solution renumbering after deletion may not be implemented

2. **`lib/models/project_data_model.dart`**
   - ✅ `deletePotentialSolution()` method exists (Line 619)
   - ✅ `_renumberSolutions()` method exists (Line 625)
   - ⚠️ Need to verify renumbering is called after deletion

**Required Changes:**
- Verify "Add Solution" button state updates after deletion
- Ensure solution limit enforcement (3/5 max)
- Verify solution renumbering works correctly

---

### 2.2 Preferred Solution Card Refactor

**Status:** ⚠️ **PARTIALLY IMPLEMENTED**

**Current Implementation:**
- `SolutionCard` widget exists (`lib/widgets/solution_card.dart`)
- Card-based layout exists in `lib/screens/preferred_solution_analysis_screen.dart` (`_buildCardBasedView()` method, Line 1862)
- "View Details" button exists on cards

**Gaps Identified:**

1. **Project Context Section Removal**
   - ❌ **CRITICAL**: `_buildProjectContextCard()` method exists (Line ~3175-3253)
   - ❌ Project Context section displayed in Preferred Solution Analysis screen
   - ❌ Must be removed per requirement: "Remove the 'Project Context' section from the Preferred Solution Analysis page"

2. **Card-Based UI**
   - ✅ Card layout implemented (`_buildCardBasedView()`, Line 1862)
   - ✅ `SolutionCard` widget exists
   - ✅ "View Details" button exists
   - ⚠️ Need to verify cards are "dynamic and visually distinct"

3. **View More Details Button**
   - ✅ Button exists on cards
   - ⚠️ Need to verify it shows "full, un-summarized data"

**Required Changes:**
- **REMOVE** `_buildProjectContextCard()` method and all calls to it
- Remove Project Context section from Preferred Solution Analysis page
- Verify card visual distinctness
- Verify "View Details" shows complete data

---

### 2.3 Deep-Dive Navigation

**Status:** ⚠️ **PARTIALLY IMPLEMENTED**

**Current Implementation:**
- `PreferredSolutionDetailsScreen` exists (created in previous work)
- Navigation to detail screen exists (`_navigateToSolutionDetails()`)

**Gaps Identified:**

1. **Full Data Display**
   - ⚠️ Detail screen may show summarized data instead of full data
   - Need to verify all sections (Risks, IT, CBA, Stakeholders, Scope) show complete information

2. **Navigation Flow**
   - ✅ Navigation exists
   - ⚠️ Need to verify it shows "full, un-summarized data"

**Required Changes:**
- Audit `PreferredSolutionDetailsScreen` to ensure full data display
- Verify all accordion sections show complete information

---

### 2.4 Auto-Navigation on Selection

**Status:** ⚠️ **NEEDS VERIFICATION**

**Current Implementation:**
- Selection logic exists (`_selectPreferredAndContinue()`, `_confirmSelectPreferredFromCard()`)
- Navigation to `FrontEndPlanningSummaryScreen` exists

**Gaps Identified:**

1. **Auto-Navigation**
   - ⚠️ Navigation exists but may not be "automatic"
   - Need to verify navigation happens immediately upon selection
   - Need to verify it navigates to "Preferred Solution Detail" page

**Required Changes:**
- Verify auto-navigation triggers immediately on selection
- Ensure navigation goes to detail page showing full breakdown

---

## 3. Content Logic & Stakeholder Switch

### 3.1 Scope Statement - AI Suggestion Auto-Populate

**Status:** ✅ **IMPLEMENTED**

**Current Implementation:**
- `AiSuggestingTextField` exists (`lib/widgets/ai_suggesting_textfield.dart`)
- `_applySuggestion()` method exists (Line 266)
- Auto-population on suggestion click implemented

**Gaps Identified:**

1. **Copy to Clipboard Feature**
   - ✅ `_copyToClipboard()` method exists (Line 296)
   - ✅ Auto-paste functionality exists (`_applySuggestion()` called after copy)
   - ✅ Toast notification exists ("Copied and pasted to field")
   - ✅ **REQUIREMENT MET**

**Required Changes:**
- None - feature is implemented correctly

---

### 3.2 Stakeholder Reordering - External First

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- `lib/screens/core_stakeholders_screen.dart` displays stakeholders
- Current order: Internal Stakeholders FIRST, External Stakeholders SECOND

**Gaps Identified:**

1. **`lib/screens/core_stakeholders_screen.dart`**
   - ❌ **Line 819**: "External Stakeholders" section
   - ❌ **Line 875**: "Internal Stakeholders" section
   - ❌ **WRONG ORDER**: Internal appears before External in build method
   - ❌ Requirement: External must be FIRST, Internal SECOND

**Required Changes:**
- **SWAP** section order in `_buildMainContent()` method
- Move External Stakeholders section above Internal section
- Update any instructional text referencing order

---

### 3.3 Infrastructure - AI Prompt Update

**Status:** ⚠️ **NEEDS VERIFICATION**

**Current Implementation:**
- Infrastructure Considerations screen exists
- AI generation uses prompts from `OpenAiServiceSecure`

**Gaps Identified:**

1. **AI Prompt Content**
   - ⚠️ Need to verify AI prompt specifies "physical, touchable infrastructure"
   - ⚠️ Need to check `OpenAiServiceSecure` infrastructure generation methods
   - ❌ May currently suggest software/data infrastructure instead of hardware

**Required Changes:**
- Audit AI prompt for infrastructure generation
- Update prompt to specify: "physical, touchable infrastructure (Hardware, Servers, etc.)"
- Ensure prompt excludes software/data infrastructure suggestions

---

## 4. Cost-Benefit Analysis (CBA) Optimization

### 4.1 Layout - Data Table to Top

**Status:** ⚠️ **NEEDS VERIFICATION**

**Current Implementation:**
- Cost Analysis screen has multiple steps/tabs
- Data table exists in `_buildBenefitLineItemsTab()`

**Gaps Identified:**

1. **`lib/screens/cost_analysis_screen.dart`**
   - ⚠️ Table position needs verification
   - ⚠️ May be in Step 0 tab, not at very top of page
   - ❌ Requirement: Table should be "first thing user sees"

**Required Changes:**
- Move Data Table to absolute top of page (before any tabs/steps)
- Ensure table is visible immediately on page load

---

### 4.2 Dropdowns & Labels - Full Text

**Status:** ⚠️ **PARTIALLY IMPLEMENTED**

**Current Implementation:**
- Dropdowns exist in CBA screen
- Some labels may use shortcuts

**Gaps Identified:**

1. **Dropdown Text**
   - ⚠️ Need to audit all dropdowns for shortcuts
   - ❌ Requirement: "Operational Efficiency" instead of shortcuts
   - Need to find all dropdown instances and verify full text

2. **Label Change**
   - ✅ **FOUND**: Line 2910 shows "Subtotal Benefit" (correct)
   - ⚠️ Need to verify no instances of "Subtotal Benefit Value" remain

**Required Changes:**
- Audit all dropdowns for full text labels
- Replace any shortcuts with full text
- Verify "Subtotal Benefit" label (not "Subtotal Benefit Value")

---

### 4.3 Scaling - Reduce Font/Padding Sizes

**Status:** ❌ **GAP**

**Current Implementation:**
- Standard Flutter font sizes used
- No global scaling constants for tables/dropdowns

**Gaps Identified:**

1. **DataTables Font/Padding**
   - ❌ No reduced font sizes for tables
   - ❌ Standard padding may cause overflow
   - ❌ Need responsive font scaling

2. **Dropdowns Font/Padding**
   - ❌ No reduced sizes for dropdowns
   - ❌ May cause scrolling issues

**Required Changes:**
- Create responsive font size constants (smaller for desktop, slightly larger for mobile)
- Reduce padding in DataTables
- Reduce padding in Dropdowns
- Ensure all information fits on single screen without excessive scrolling

---

### 4.4 Header Alignment - Center-Align

**Status:** ❌ **GAP**

**Current Implementation:**
- Table headers may be left-aligned
- Cell inputs may be left-aligned

**Gaps Identified:**

1. **Table Headers**
   - ❌ Headers not center-aligned
   - Need to add `textAlign: TextAlign.center` to all header cells

2. **Cell Inputs**
   - ❌ Input fields in cells not center-aligned
   - Need to center-align all input fields

**Required Changes:**
- Center-align all table headers
- Center-align all cell inputs
- Apply to all DataTables in CBA screen

---

### 4.5 Currency - Single Indicator at Top

**Status:** ⚠️ **NEEDS VERIFICATION**

**Current Implementation:**
- Currency may be displayed per row
- Currency selector exists

**Gaps Identified:**

1. **Currency Display**
   - ⚠️ Need to verify if "Unit Currency" appears in individual rows
   - ❌ Requirement: Single currency indicator at top, remove from rows

**Required Changes:**
- Remove "Unit Currency" from individual table rows
- Add single currency indicator at top of table
- Ensure currency selector updates top indicator

---

## 5. Global Persistence & AI Persona

### 5.1 Regenerate Page - Global Button

**Status:** ⚠️ **PARTIALLY IMPLEMENTED**

**Current Implementation:**
- `PageRegenerateAllButton` widget exists (`lib/widgets/page_regenerate_all_button.dart`)
- Some screens have global regenerate buttons

**Gaps Identified:**

1. **Missing Global Regenerate Buttons**
   - ❌ **`lib/screens/potential_solutions_screen.dart`**: No global regenerate button
   - ⚠️ **`lib/screens/preferred_solution_analysis_screen.dart`**: Need to verify global button exists
   - ⚠️ **`lib/screens/cost_analysis_screen.dart`**: Has `PageRegenerateAllButton` (Line 38 import)
   - ⚠️ **`lib/screens/core_stakeholders_screen.dart`**: Has `PageRegenerateAllButton` (Line 32 import)

**Required Changes:**
- Add global "Regenerate" button to ALL Business Case screens
- Ensure button refreshes all AI-dependent fields
- Add confirmation dialog before regeneration
- Show loading state during regeneration
- Show success/error toast notifications

---

### 5.2 State Persistence - Save on Blur

**Status:** ⚠️ **NEEDS VERIFICATION**

**Current Implementation:**
- `ProjectDataProvider` handles saving
- Some fields may save on blur, others on navigation

**Gaps Identified:**

1. **Blur Event Handling**
   - ⚠️ Need to verify all text fields save on blur
   - ⚠️ Need to verify navigation doesn't reset fields
   - ❌ May have fields that only save on explicit save action

**Required Changes:**
- Add `onEditingComplete` or `onChanged` handlers to all text fields
- Ensure all changes save to `ProjectDataProvider` on blur
- Verify Back/Next navigation preserves edited fields
- Add debouncing to prevent excessive saves

---

### 5.3 AI Persona - CBA Financial Value Focus

**Status:** ⚠️ **NEEDS VERIFICATION**

**Current Implementation:**
- AI prompts exist in `OpenAiServiceSecure`
- CBA generation uses prompts

**Gaps Identified:**

1. **AI Prompt Content**
   - ⚠️ Need to verify CBA prompt asks: "What direct financial value does this project bring to the company?"
   - ⚠️ Need to check `_projectValuePrompt` or similar methods in `OpenAiServiceSecure`

**Required Changes:**
- Audit CBA AI prompt in `OpenAiServiceSecure`
- Update prompt to specifically ask: "What direct financial value does this project bring to the company?"
- Ensure prompt focuses on financial value calculation

---

## Summary of Critical Gaps

### Priority P0 (Critical - Must Fix Immediately)
1. ❌ **Icon Ergonomics**: Icons inside text fields obstructing typing
2. ❌ **Project Context Removal**: Section still displayed on Preferred Solution Analysis page
3. ❌ **Stakeholder Reordering**: External/Internal order reversed

### Priority P1 (High - Fix Soon)
4. ⚠️ **Auto-Bulleting**: Unified period bullet for list fields
5. ⚠️ **CBA Layout**: Data table not at top
6. ⚠️ **CBA Scaling**: Font/padding sizes too large
7. ⚠️ **CBA Header Alignment**: Not center-aligned
8. ⚠️ **Global Regenerate**: Missing on some screens

### Priority P2 (Medium - Fix When Possible)
9. ⚠️ **Infrastructure AI Prompt**: May suggest software instead of hardware
10. ⚠️ **State Persistence**: Need verification of blur save
11. ⚠️ **AI Persona CBA**: Prompt may not focus on financial value

---

## Next Steps

1. **Create Implementation Plan**: Prioritize fixes based on P0/P1/P2
2. **Begin Implementation**: Start with P0 critical gaps
3. **Test Each Fix**: Verify requirements met after each change
4. **Update Documentation**: Keep this gap analysis updated as fixes are implemented

---

**End of Gap Analysis**
