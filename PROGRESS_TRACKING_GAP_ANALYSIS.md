# Progress Tracking Module - Gap Analysis

**Date:** January 28, 2026  
**Objective:** Transform Progress Tracking into a dashboard-first interface with visual data representations, full CRUD, and AI capabilities

---

## Executive Summary

This document identifies all gaps between the current Progress Tracking implementation and the specified requirements for a "Pulse" interface with dashboard-first layout, visual data representations, and standardized CRUD/AI interactions.

---

## 1. Current State Analysis

### 1.1 Current Implementation

**File:** `lib/screens/progress_tracking_screen.dart`

**Current Structure:**
- Uses `ExecutionPhasePage` widget (generic execution phase template)
- Three sections:
  1. **Deliverable status updates** (`deliverableUpdates`)
  2. **Recurring deliverables** (`recurring`)
  3. **Status reports & asks** (`reports`)
- Generic table layout via `LaunchEditableSection`
- "Submit to Firebase" button present
- No visual data representations
- No summary cards
- No AI regeneration per row
- No inline editing
- No undo functionality

**Data Structure:**
- Uses `LaunchEntry` model (title, details, status)
- Stored in `execution_phase_entries/progress_tracking` Firestore subcollection
- No specialized models for deliverables, milestones, budget, etc.

---

## 2. CRITICAL GAPS: Visual Design Strategy

### 2.1 Missing Dashboard-First Layout

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- No "Live Status" bar at top of page
- No summary cards showing completion %, budget spent, blockers
- No visual data representations (charts, timelines, heat maps)
- Generic table-only layout

**Required Changes:**
- Add "Progress Header" with live status bar showing completion percentage
- Add 3 summary cards at top (e.g., "Completion %", "Total Budget Spent", "Current Blockers")
- Replace tables with visual representations where appropriate:
  - **Deliverables:** Timeline/Gantt view
  - **Budget:** Donut charts for category spending, Bar charts for planned vs actual
  - **Risks:** Heat map (color-coded grid)

**Files to Modify:**
- `lib/screens/progress_tracking_screen.dart` - Complete refactor
- Create new widget: `lib/widgets/progress_tracking_dashboard.dart`
- Create models: `lib/models/deliverable_row.dart`, `lib/models/progress_milestone.dart`

---

### 2.2 Missing Visual Data Representations

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- No charts or visual representations
- All data shown as text tables

**Required Changes:**
- **Deliverables:** Vertical/horizontal Timeline or Gantt view
- **Budget Tracking:** Donut charts (category spending), Bar charts (planned vs actual)
- **Risk Tracking:** Heat map (color-coded grid showing high-impact risks)
- **Task Status:** Kanban cards (drag-and-drop: To Do, In Progress, Done)

**Implementation Notes:**
- App uses `CustomPaint` for charts (see `lib/widgets/chart_builder_workspace.dart`)
- No `fl_chart` package - use existing CustomPaint approach
- Create reusable chart components: `lib/widgets/progress_charts.dart`

---

### 2.3 Missing Action Hub

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Standard "Add" button in each section
- No floating Quick Action menu
- No Export functionality
- No centralized action hub

**Required Changes:**
- Replace standard buttons with floating "Quick Action" menu or icon-bar at top-right
- Actions: Add (+), Regenerate (AI), Export
- Position: Top-right corner, floating above content

**Files to Create:**
- `lib/widgets/progress_quick_actions.dart`

---

## 3. CRITICAL GAPS: CRUD Operations

### 3.1 Missing Inline Editing

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Editing requires separate dialog (`showLaunchEntryDialog`)
- No inline editing capability
- Clicking text does not turn into input field

**Required Changes:**
- Implement inline editing: clicking any text turns it into an input field instantly
- No separate "Edit" screen needed
- Auto-save on blur (1.5s debounce)

**Files to Modify:**
- Create `lib/widgets/inline_editable_text.dart` reusable component
- Update all progress tracking widgets to use inline editing

---

### 3.2 Missing Smart Delete with Undo

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Delete removes item immediately
- No undo functionality
- No snackbar feedback

**Required Changes:**
- Deleting an item shows subtle "Undo" snackbar at bottom
- Snackbar lasts 5 seconds
- Clicking "Undo" restores the deleted item
- After 5 seconds, deletion is permanent

**Files to Modify:**
- Update delete handlers in progress tracking widgets
- Create undo state management

---

### 3.3 Missing Individual AI Triggers

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- No AI regeneration per row
- No "Magic Wand" icon on rows

**Required Changes:**
- Every generated row should have a "Magic Wand" icon
- Clicking it regenerates only that row based on updated project context
- Icon placement: Floating above text field (similar to Staff Team implementation)

**Files to Modify:**
- Add AI regeneration methods to `OpenAiServiceSecure`
- Update progress tracking widgets to include regenerate icons

---

## 4. CRITICAL GAPS: Data Models

### 4.1 Missing Specialized Models

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Uses generic `LaunchEntry` model (title, details, status)
- No specialized models for:
  - Deliverables (with dates, milestones, dependencies)
  - Budget items (with planned vs actual, categories)
  - Risk items (with impact, likelihood, heat map data)
  - Task items (with status, assignee, kanban position)

**Required Changes:**
- Create `DeliverableRow` model with: title, description, dueDate, status, owner, dependencies, completionDate
- Create `BudgetRow` model with: category, plannedAmount, actualAmount, variance, period
- Create `RiskRow` model with: riskName, impact, likelihood, status, owner, mitigation
- Create `TaskRow` model with: title, description, status (To Do/In Progress/Done), assignee, dueDate

**Files to Create:**
- `lib/models/deliverable_row.dart`
- `lib/models/budget_row.dart`
- `lib/models/risk_row.dart`
- `lib/models/task_row.dart`

---

## 5. CRITICAL GAPS: Text Formatting

### 5.1 Missing "." Bullet Rule

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- No automatic bulleting for list-based fields
- No distinction between prose and list fields

**Required Changes:**
- List-based fields (e.g., "Next Steps", "Blockers") must auto-bullet with period "."
- Prose fields (descriptions, notes) remain clean (no bullets)
- Use existing `auto_bullet_text_controller.dart` pattern

**Files to Modify:**
- Update text field implementations in progress tracking widgets
- Ensure AI never generates text in "User Notes" sections

---

## 6. CRITICAL GAPS: Firebase Mentions

### 6.1 Firebase References in UI

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Uses `ExecutionPhasePage` which has "Submit to Firebase" button
- Subtitle mentions "submit to Firebase"

**Required Changes:**
- Remove all "Submit to Firebase" buttons
- Remove Firebase mentions from UI text
- Implement silent auto-save on blur (already implemented in ExecutionPhasePage, but needs verification)

**Files to Modify:**
- `lib/widgets/execution_phase_page.dart` - Already updated, verify no Firebase mentions remain
- `lib/screens/progress_tracking_screen.dart` - Will be refactored to not use ExecutionPhasePage

---

## 7. CRITICAL GAPS: Navigation & State

### 7.1 Missing Sub-Page Navigation

**Status:** ⚠️ **PARTIAL GAP**

**Current Implementation:**
- Single page with 3 sections (not true sub-pages)
- No navigation between sub-pages
- No state preservation between sub-pages

**Required Changes:**
- Implement tab-based or sidebar navigation for sub-pages:
  - Deliverable Status Updates
  - Recurring Deliverables
  - Status Reports & Asks
  - (Future: Milestones, Budget Burn, Task Health, Quality/KPIs)
- Fast navigation between sub-pages
- Preserve edited field state in ProjectDataProvider
- Add "Back/Next" navigation buttons

**Files to Create:**
- `lib/widgets/progress_tracking_tabs.dart` or similar navigation component

---

## 8. Sub-Page Specific Enhancements

### 8.1 Deliverable Status Updates

**Status:** ❌ **NOT IMPLEMENTED**

**Required Enhancements:**
- **Visual:** Timeline/Gantt view showing past and future targets
- **AI:** Predict potential delays based on current date
- **Data Model:** `DeliverableRow` with dates, dependencies, completion tracking

---

### 8.2 Recurring Deliverables

**Status:** ❌ **NOT IMPLEMENTED**

**Required Enhancements:**
- **Visual:** Recurring pattern visualization (calendar view or timeline)
- **AI:** Suggest cadence adjustments based on team velocity
- **Data Model:** `RecurringDeliverableRow` with frequency, next occurrence, history

---

### 8.3 Status Reports & Asks

**Status:** ❌ **NOT IMPLEMENTED**

**Required Enhancements:**
- **Visual:** Timeline of reports with stakeholder tags
- **AI:** Auto-summarize weekly wins from completed tasks
- **Data Model:** `StatusReportRow` with stakeholder, report type, asks, follow-ups

---

### 8.4 Future Sub-Pages (Not Yet Requested)

**Milestones:**
- Timeline View: Vertical line showing past and future targets
- AI: Predict potential delays based on current date

**Financials:**
- Burn Chart: Line graph showing money spent over time
- AI: Suggest cost-saving measures if spending exceeds plan

**Task Status:**
- Kanban Cards: Drag-and-drop (To Do, In Progress, Done)
- AI: Auto-summarize "Weekly Wins" based on completed tasks

**Quality/KPIs:**
- Radial Gauges: Visual dials showing proximity to quality targets
- AI: Identify "At Risk" KPIs based on team performance data

---

## 9. Summary of Critical Gaps

### Priority P0 (Critical - Must Fix Immediately)
1. ❌ **Dashboard-First Layout**: Missing Live Status bar and summary cards
2. ❌ **Visual Representations**: No charts, timelines, or heat maps
3. ❌ **Inline Editing**: No click-to-edit functionality
4. ❌ **Smart Delete**: No undo snackbar
5. ❌ **AI Per Row**: No individual regeneration icons
6. ❌ **Specialized Models**: Using generic LaunchEntry instead of domain-specific models
7. ❌ **Firebase Mentions**: Still present in UI (though ExecutionPhasePage was updated)

### Priority P1 (High - Fix Soon)
8. ⚠️ **Action Hub**: Missing floating Quick Action menu
9. ⚠️ **Sub-Page Navigation**: Single page instead of navigable sub-pages
10. ⚠️ **Export Functionality**: Not implemented
11. ⚠️ **Text Formatting**: "." bullet rule not applied

### Priority P2 (Medium - Fix When Possible)
12. ⚠️ **Kanban Drag-Drop**: Not implemented for Task Status
13. ⚠️ **Chart Library**: Need to create reusable chart components
14. ⚠️ **State Preservation**: Need to ensure state persists across navigation

---

## 10. Files Requiring Changes

### High Priority (Core Functionality)
1. **`lib/screens/progress_tracking_screen.dart`**
   - Complete refactor to dashboard-first layout
   - Remove ExecutionPhasePage dependency
   - Add summary cards and Live Status bar
   - Implement sub-page navigation

2. **`lib/models/deliverable_row.dart`** (NEW)
   - Create DeliverableRow model with dates, dependencies, status

3. **`lib/models/recurring_deliverable_row.dart`** (NEW)
   - Create RecurringDeliverableRow model with frequency, next occurrence

4. **`lib/models/status_report_row.dart`** (NEW)
   - Create StatusReportRow model with stakeholder, report type, asks

5. **`lib/widgets/progress_tracking_dashboard.dart`** (NEW)
   - Main dashboard widget with summary cards and Live Status bar

6. **`lib/widgets/progress_charts.dart`** (NEW)
   - Reusable chart components (Timeline, Donut, Bar, Heat Map)

7. **`lib/widgets/inline_editable_text.dart`** (NEW)
   - Reusable inline editing component

8. **`lib/widgets/progress_quick_actions.dart`** (NEW)
   - Floating Quick Action menu (Add, Regenerate, Export)

9. **`lib/services/execution_phase_service.dart`**
   - Add methods: `saveDeliverableRows()`, `loadDeliverableRows()`, etc.

10. **`lib/services/openai_service_secure.dart`**
    - Add AI methods for regenerating deliverables, predicting delays, etc.

### Medium Priority (UI Enhancements)
11. **`lib/widgets/progress_tracking_tabs.dart`** (NEW)
    - Tab navigation for sub-pages

12. **`lib/widgets/kanban_board.dart`** (NEW)
    - Drag-and-drop Kanban board for Task Status

13. **`lib/widgets/timeline_view.dart`** (NEW)
    - Timeline/Gantt visualization component

---

## 11. Implementation Strategy

### Phase 1: Foundation (P0)
1. Create specialized models (DeliverableRow, RecurringDeliverableRow, StatusReportRow)
2. Create inline editing component
3. Create progress tracking dashboard widget with summary cards
4. Refactor ProgressTrackingScreen to use new dashboard widget
5. Remove Firebase mentions and implement auto-save

### Phase 2: Visual Representations (P0)
6. Create chart components (Timeline, Donut, Bar, Heat Map)
7. Integrate charts into appropriate sub-pages
8. Add Live Status bar

### Phase 3: CRUD Enhancements (P0)
9. Implement inline editing for all fields
10. Add smart delete with undo snackbar
11. Add individual AI regeneration icons per row

### Phase 4: Navigation & Polish (P1)
12. Implement sub-page navigation (tabs or sidebar)
13. Add Quick Action menu
14. Add Export functionality
15. Apply "." bullet rule to list fields

---

## 12. Verification Checklist

Before implementation, verify:
- [ ] All Firebase mentions removed from UI
- [ ] Auto-save on blur working correctly
- [ ] Inline editing works for all text fields
- [ ] Undo snackbar appears and functions correctly
- [ ] AI regeneration icons visible and functional
- [ ] Summary cards update in real-time
- [ ] Charts render correctly with actual data
- [ ] Navigation between sub-pages preserves state
- [ ] "." bullet rule applied to list fields only
- [ ] Prose fields remain clean (no bullets)

---

**End of Gap Analysis**
