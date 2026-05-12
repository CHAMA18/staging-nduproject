# Business Case Module – Implementation Summary

This document describes in detail all changes made after the “Green Light” audit, and confirms that the modified code has no known errors (linter-clean).

---

## 1. P0: Navigation & solutions (data no longer disappears)

### Problem
When users clicked **Back** or **Next** in the Business Case flow, Risk, IT, Infrastructure, Core Stakeholders, and Cost Analysis were recreated with **empty `solutions`**. Those screens depend on `solutions` to show rows. Empty `solutions` → no rows → “data disappeared” (e.g. risks, tech, infrastructure).

### Changes

**`lib/utils/business_case_navigation.dart`**
- Imported `project_data_model.dart`.
- Added **`_buildSolutionItems(ProjectDataModel data)`**:
  - Uses `potentialSolutions` → `preferredSolutionAnalysis.solutionAnalyses` → `solutionTitle` / `solutionDescription` fallback (same logic as the sidebar).
  - Returns `List<AiSolutionItem>` for downstream screens.
- **`_navigateToScreen`** now:
  - Calls `_buildSolutionItems(projectData)` once.
  - Passes **`solutions`** into Risk, IT, Infrastructure, Core Stakeholders, and Cost Analysis (no more `const []`).
  - Uses **section-specific notes** where relevant:
    - IT: `itConsiderationsData?.notes ?? projectData.notes`
    - Infrastructure: `infrastructureConsiderationsData?.notes ?? projectData.notes`
    - Core Stakeholders: `coreStakeholdersData?.notes ?? projectData.notes`
  - Preferred Solution still receives `solutions` built the same way.

**`lib/widgets/initiation_like_sidebar.dart`**
- **`_openCostAnalysis`** no longer uses `CostAnalysisScreen(notes: '', solutions: [])`.
- It now passes **`data.notes`** and **`_buildSolutionItems(data)`** into `CostAnalysisScreen`, same pattern as IT / Infrastructure / Stakeholders.

### Result
- Back/Next and sidebar navigation **preserve solutions and section-specific notes**.
- Risk, IT, Infrastructure, Stakeholders, and Cost Analysis always receive the correct solution list and notes, so data no longer “disappears” when moving between sections.

---

## 2. P1: CBA 3 – compact category labels

### Problem
Cost Benefit Analysis used long labels **“Operational Efficiency”** and **“Stakeholder Commitment”** instead of the requested compact labels.

### Changes

**`lib/screens/cost_analysis_screen.dart`**
- In **`_projectValueFields`**:
  - `ops_efficiency`: **“Operational Efficiency”** → **“Ops Eff.”**
  - `stakeholder_commitment`: **“Stakeholder Commitment”** → **“SH Comm.”**

### Result
- Dropdowns, Project Benefits Review, and Value Summary use **“Ops Eff.”** and **“SH Comm.”** everywhere these categories appear.

---

## 3. P1: First-time hints (Risk & Preferred Solution)

### Problem
Risk Identification and Preferred Solution Analysis had no first-time hint dialog.

### Changes

**`lib/screens/risk_identification_screen.dart`**
- Imported **`page_hint_dialog.dart`**.
- In **`addPostFrameCallback`** (after load/bootstrap/generate):
  - **`PageHintDialog.showIfNeeded`** with:
    - `pageId`: `'risk_identification'`
    - `title`: `'Risk Identification'`
    - `message`: explains up to 3 risks per solution, “Generate risks,” and auto-save.

**`lib/screens/preferred_solution_analysis_screen.dart`**
- Imported **`page_hint_dialog.dart`**.
- **`addPostFrameCallback`** now **`await`s `_loadExistingDataAndAnalysis()`**, then:
  - **`PageHintDialog.showIfNeeded`** with:
    - `pageId`: `'preferred_solution_analysis'`
    - `title`: `'Preferred Solution Analysis'`
    - `message`: review each solution, use “View More Details,” complete before WBS.

### Result
- First visit to Risk Identification and Preferred Solution Analysis shows the hint (subject to existing hint settings: “Disable hints for pages I’ve viewed before,” “Enable all hints”).

---

## 4. P2: Prose vs list & period bulleting

### Problem
- Auto-bullet used **`• `** (bullet character) instead of **`.`** (period).
- **Prose** fields (Notes, Scope, Business Case, etc.) were using auto-bullet; they should not.

### Changes

**`lib/utils/auto_bullet_text_controller.dart`**
- Introduced **`kListBullet = '. '`** (period + space).
- **`AutoBulletTextController`** and **`_autoBulletListener`** now use **`kListBullet`** instead of **`• `** (empty start, after newline, prefix when no bullet).
- Comments state: **list fields only**; **do not** use for prose.

**Screens – prose (auto-bullet removed)**
- **Risk**: `_notesController` – no `enableAutoBullet`.
- **Core Stakeholders**: `_notesController` – no `enableAutoBullet`.
- **IT Considerations**: `_notesController` – no `enableAutoBullet`.
- **Initiation Phase**: `_notesController`, `_businessCaseController` – no `enableAutoBullet`.
- **Front-End Planning Summary**: `_notes`, `_summaryNotes` – no `enableAutoBullet`.

**Screens – list fields (keep auto-bullet, now `. `)**
- **Risk**: risk controllers still use `enableAutoBullet` (including bootstrap and **Add**).
- **Core Stakeholders**: internal/external stakeholder controllers unchanged.
- **IT**: tech field controllers unchanged.

**`lib/screens/cost_analysis_screen.dart`**
- Imported **`auto_bullet_text_controller.dart`**.
- When appending AI savings into category notes, **`• `** replaced with **`kListBullet`**.

### Result
- **List** fields use **`. `** bulleting; **prose** fields have no auto-bullet.
- AI-appended list content in CBA uses **`. `** as well.

---

## 5. P2: Core Stakeholders – title and reminders

### Problem
- Section title above the table could be read as “Internal Stakeholders” only; it should be clear that the section covers **Core Stakeholders** (internal + external).
- Need a **reminder** to update text in each box.

### Changes

**`lib/screens/core_stakeholders_screen.dart`**
- Under **“Core Stakeholders”** heading:
  - Added **“Reminder: update text within each box.”** (italic, grey).
- Subheadings:
  - **“Internal Stakeholders”** → **“Internal”**
  - **“External Stakeholders”** → **“External”**
- Table column headers (e.g. “Internal Stakeholders” / “External Stakeholders”) are unchanged.

### Result
- **“Core Stakeholders”** is the main title; **“Internal”** / **“External”** clarify the two blocks.
- Reminder prompts users to update each stakeholder box.

---

## 6. P2: Preferred Solution – “View More Details”

### Problem
Users could not see **full** solution details (all costs, technologies, infrastructure, etc.) before selecting a preferred solution.

### Changes

**`lib/screens/preferred_solution_analysis_screen.dart`**
- In **`_buildSolutionDetail`** (each solution tab):
  - Added a **“View More Details”** `TextButton` (with `Icons.read_more`) next to the AI tag.
- **`_showViewMoreDetails(context, data, index)`**:
  - Opens a **scrollable dialog** (max width 560, max height 640).
  - Shows **full** content:
    - Title and **full description**
    - **Key stakeholders** (all)
    - **Top risks** (all)
    - **Technologies** (if any)
    - **Infrastructure** (if any)
    - **Investment overview**: **all** cost items (no `take(4)`), each with Est. cost, ROI, NPV.
- **`_buildFullCostsSection`**:
  - Builds the full cost list for the dialog (reuses **`_buildCostBadge`** and **`_formatCurrency`**).

### Result
- Users can open **“View More Details”** per solution and see the **complete** information before choosing a preferred option.

---

## 7. P2: IT & Infrastructure – “update text” reminders

### Problem
IT Considerations and Infrastructure Considerations had no reminder to **update text within each box**.

### Changes

**`lib/screens/it_considerations_screen.dart`**
- After **“IT Considerations for each potential solution”** and before the table:
  - **“Reminder: update text within each Core Technology box.”** (italic, grey).
- Shown for both mobile and desktop (title + reminder are above the `isMobile` branch).

**`lib/screens/infrastructure_considerations_screen.dart`**
- **Mobile**: before the list of rows, **“Reminder: update text within each box.”** (italic, grey).
- **Desktop**: after **“Main Infrastructure Consideration for each potential solution”**, same reminder, then the table.

### Result
- Both screens remind users to update text in each Core Technology / infrastructure box.

---

## 8. P2: Save-before-undo (avoid data loss)

### Problem
When users clicked **Undo** in the text-formatting toolbar, the **current** state (before undo) was not saved. That could cause data loss.

### Changes

**`lib/widgets/text_formatting_toolbar.dart`**
- Added optional **`onBeforeUndo`** (`VoidCallback?`).
- **`_undo()`** now:
  1. Calls **`widget.onBeforeUndo?.call()`**
  2. Then performs the undo (revert to previous history entry).

**Screens using the toolbar**
- **IT Considerations**  
  - Notes toolbar and each **Core Technology** toolbar:  
    **`onBeforeUndo: () => _saveITConsiderationsData()`**
- **Infrastructure Considerations**  
  - Each infrastructure text area toolbar:  
    **`onBeforeUndo: () => _saveInfrastructureConsiderationsData()`**
- **Initiation Phase**  
  - **`_saveBeforeUndo()`**:
    - Updates provider with **`_notesController.text`** and **`_businessCaseController.text`** via **`updateInitiationData`**.
    - Calls **`saveToFirebase(checkpoint: 'business_case')`** (fire-and-forget).
  - Both **Notes** and **Business Case** toolbars use **`onBeforeUndo: _saveBeforeUndo`**.

### Result
- Before **any** undo in those toolbars, the **current** state is saved (provider + Firebase for initiation; IT/Infrastructure各自 save).
- Reduces risk of losing edits when using Undo.

---

## 9. Error check

- **Linter**: No issues reported for the modified files.
- **Modified files**:
  - `lib/utils/business_case_navigation.dart`
  - `lib/widgets/initiation_like_sidebar.dart`
  - `lib/screens/cost_analysis_screen.dart`
  - `lib/screens/risk_identification_screen.dart`
  - `lib/screens/preferred_solution_analysis_screen.dart`
  - `lib/utils/auto_bullet_text_controller.dart`
  - `lib/screens/core_stakeholders_screen.dart`
  - `lib/screens/it_considerations_screen.dart`
  - `lib/screens/infrastructure_considerations_screen.dart`
  - `lib/screens/initiation_phase_screen.dart`
  - `lib/widgets/text_formatting_toolbar.dart`

---

## 10. Not implemented (as per audit)

- **Internal/External column** for Core Stakeholders: would require a single table with a per-row Internal/External choice and a different data model. Current design keeps separate Internal and External sections.
- **Global visible Save** on every Business Case page: CBA and Preferred Solution already have Save; others use auto-save. No extra Save buttons were added elsewhere.

---

## 11. How to verify

1. **Back/Next data persistence**  
   Add risks (or IT / infra / stakeholders), go to another section via Back/Next, then return. Risks and other data should still be present.

2. **CBA labels**  
   Confirm **“Ops Eff.”** and **“SH Comm.”** in benefit category dropdowns and Project Benefits Review.

3. **Hints**  
   Clear hint state (or use “Enable all hints”), then open Risk Identification and Preferred Solution Analysis for the first time. The new hints should appear.

4. **Bulleting**  
   In list fields (e.g. risks, stakeholders), new lines should get **`. `**; in Notes/Business Case, no auto-bullet.

5. **View More Details**  
   On Preferred Solution Analysis, use **“View More Details”** and confirm full description, stakeholders, risks, technologies, infrastructure, and **all** costs.

6. **Reminders**  
   Check IT, Infrastructure, and Core Stakeholders for the new “Reminder: update text…” lines.

7. **Save-before-undo**  
   Edit Notes (or Business Case / IT / Infrastructure), then Undo. Confirm the **pre-undo** content is persisted (e.g. reload or check Firebase).

---

*Last updated: after Green Light implementation.*
