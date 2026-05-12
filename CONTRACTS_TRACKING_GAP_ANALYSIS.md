# Contracts Tracking Module - Gap Analysis

**Date:** January 28, 2026  
**Objective:** Refactor Contracts Tracking to integrate with Staff Needs, sync with Progress Tracking, add AI capabilities, and implement full CRUD with proper formatting

---

## Executive Summary

This document identifies all gaps between the current Contracts Tracking implementation and the specified requirements for data integration, visual UI improvements, CRUD enhancements, and AI capabilities.

---

## 1. Current State Analysis

### 1.1 Current Implementation

**File:** `lib/screens/contracts_tracking_screen.dart`

**Current Structure:**
- Uses `ContractService` for contracts CRUD (Firestore-based)
- Has summary cards (Active contracts, Renewal due, Total value, At risk)
- Uses `DataTable` for contract display
- Has filter chips (All contracts, Renewal due, At risk, Pending sign-off, Archived)
- Uses dialog-based forms for Add/Edit
- Auto-saves renewal lanes, risk signals, approval checkpoints (debounced)

**Data Structure:**
- `ContractModel` includes: name, description, contractType, paymentType, status, estimatedValue, startDate, endDate, scope, discipline, notes
- Contracts stored in `projects/{projectId}/contracts/{contractId}`
- No integration with Staff Needs
- No sync with Progress Tracking budget

---

## 2. CRITICAL GAPS: Data Integration

### 2.1 Missing Staff Integration

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- No connection to Staff Needs section
- No auto-suggestion of External/Contractor roles

**Required Changes:**
- Fetch all "External" or "Contractor" roles from `staffNeeds` (via `ExecutionPhaseService.loadStaffingRows`)
- Auto-suggest these roles as contract entries when adding new contracts
- Display suggested roles in the "Add Contract" dialog

**Files to Modify:**
- `lib/screens/contracts_tracking_screen.dart` - Add staff integration logic
- `lib/widgets/contracts_table_widget.dart` (NEW) - Add suggestion logic

---

### 2.2 Missing Financial Sync

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Contract values stored independently
- No connection to Progress Tracking budget

**Required Changes:**
- When contract value is saved, sync to Progress Tracking budget section
- Ensure contract values feed into budget tracking
- Update budget totals when contracts are added/updated/deleted

**Files to Modify:**
- `lib/services/contract_service.dart` - Add sync method
- `lib/services/execution_phase_service.dart` - Add budget sync method
- `lib/screens/contracts_tracking_screen.dart` - Call sync on save

---

## 3. CRITICAL GAPS: Visual UI

### 2.1 Contract Health Cards

**Status:** ⚠️ **PARTIAL IMPLEMENTATION**

**Current Implementation:**
- Has 4 summary cards: Active contracts, Renewal due, Total value, At risk
- Cards display correctly

**Required Changes:**
- Rename "Renewal due" to "Upcoming Renewals" (30-60 days)
- Ensure cards match exactly: "Active Contracts", "Total Committed Value", "Upcoming Renewals"
- Keep "At Risk" as 4th card (optional)

**Files to Modify:**
- `lib/screens/contracts_tracking_screen.dart` - Update card labels

---

### 2.2 Interactive Contracts Table

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Uses standard `DataTable` with dialog-based editing
- Headers not center-aligned
- No inline editing
- No Undo/Regenerate/Delete icons per row

**Required Changes:**
- Replace `DataTable` with custom table widget
- Center-align all headers and cell content
- Implement inline editing (click-to-edit)
- Add hover effects with action icons (Undo, Regenerate, Delete)
- Columns: Vendor/Party Name, Contract Type (dropdown), Status (visual pills), Effective Date & Expiry, Total Value
- Use compact font sizes

**Files to Create:**
- `lib/widgets/contracts_table_widget.dart` - Custom table with inline editing

**Files to Modify:**
- `lib/screens/contracts_tracking_screen.dart` - Replace DataTable with custom widget

---

### 2.3 Status Pills

**Status:** ⚠️ **PARTIAL IMPLEMENTATION**

**Current Implementation:**
- Has `_statusChip` method with color coding
- Statuses: Active, Renewal due, At risk, Pending sign-off, Archived

**Required Changes:**
- Update status options to: Draft, Signed, Active, Expired
- Ensure color coding: Green for Active, Yellow for Draft, Red for Expired, Blue for Signed
- Use visual pills (not chips) with proper styling

**Files to Modify:**
- `lib/screens/contracts_tracking_screen.dart` - Update status options and styling
- `lib/widgets/contracts_table_widget.dart` - Implement status pills

---

## 4. CRITICAL GAPS: CRUD Operations

### 4.1 Missing Inline Editing

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Editing requires separate dialog (`_showContractDialog`)
- No inline editing capability

**Required Changes:**
- Implement inline editing: clicking any text turns it into an input field instantly
- Use `InlineEditableText` widget (already created for Progress Tracking)
- Auto-save on blur (1.5s debounce)

**Files to Modify:**
- `lib/widgets/contracts_table_widget.dart` - Add inline editing

---

### 4.2 Missing Row Action Icons

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Has Edit and Delete icons in Actions column
- No Undo icon
- No Regenerate icon
- Icons always visible (not on hover)

**Required Changes:**
- Add Undo, Regenerate, Delete icons
- Show icons only on row hover
- Position icons in top-right of row
- Implement undo functionality (5-second snackbar)

**Files to Modify:**
- `lib/widgets/contracts_table_widget.dart` - Add action icons with hover

---

### 4.3 Missing Smart Delete with Undo

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- Delete removes item immediately with confirmation dialog
- No undo functionality

**Required Changes:**
- Deleting an item shows subtle "Undo" snackbar at bottom
- Snackbar lasts 5 seconds
- Clicking "Undo" restores the deleted contract
- After 5 seconds, deletion is permanent

**Files to Modify:**
- `lib/widgets/contracts_table_widget.dart` - Add undo snackbar

---

## 5. CRITICAL GAPS: AI Capabilities

### 5.1 Missing AI Regeneration for Key Terms

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- No AI regeneration functionality
- No "Regenerate" icon for Key Terms

**Required Changes:**
- Add "Regenerate" icon next to Key Terms field
- Clicking it allows AI to draft standard terms based on Contract Type and Preferred Solution
- Use `OpenAiServiceSecure` with new method `generateContractKeyTerms`

**Files to Create:**
- Add method to `lib/services/openai_service_secure.dart`: `generateContractKeyTerms`

**Files to Modify:**
- `lib/widgets/contracts_table_widget.dart` - Add regenerate icon and handler

---

## 6. CRITICAL GAPS: Text Formatting

### 6.1 Missing "." Bullet Rule

**Status:** ❌ **CRITICAL GAP**

**Current Implementation:**
- No distinction between list fields and prose fields
- No auto-bullet functionality

**Required Changes:**
- "Key Terms" (scope field) must use "." bullet format
- "Contract Notes" (notes field) must be prose (no bullets)
- Use `AutoBulletTextController` for Key Terms
- Use regular `TextEditingController` for Contract Notes

**Files to Modify:**
- `lib/widgets/contracts_table_widget.dart` - Apply bullet rule
- `lib/screens/contracts_tracking_screen.dart` - Update dialog to use correct controllers

---

## 7. CRITICAL GAPS: Firebase Mentions

### 7.1 Firebase References in UI

**Status:** ✅ **NO ISSUES FOUND**

**Current Implementation:**
- No "Submit to Firebase" buttons visible
- No Firebase mentions in UI text
- Auto-save is already implemented (debounced)

**Required Changes:**
- Verify no Firebase mentions remain
- Ensure all saves are silent (no user-facing messages)

**Files to Verify:**
- `lib/screens/contracts_tracking_screen.dart` - Check for any Firebase UI mentions

---

## 8. CRITICAL GAPS: Contract Model

### 8.1 Missing Key Terms Field

**Status:** ⚠️ **PARTIAL GAP**

**Current Implementation:**
- Has `scope` field (could be repurposed for Key Terms)
- Has `notes` field (for Contract Notes)

**Required Changes:**
- Option 1: Add `keyTerms` field to `ContractModel`
- Option 2: Use `scope` for Key Terms (with "." bullet) and `notes` for Contract Notes (prose)
- Recommend Option 2 to avoid breaking changes

**Files to Modify:**
- `lib/services/contract_service.dart` - Document field usage
- `lib/widgets/contracts_table_widget.dart` - Use scope for Key Terms

---

## 9. Summary of Critical Gaps

### Priority P0 (Critical - Must Fix Immediately)
1. ❌ **Staff Integration**: No connection to Staff Needs for External/Contractor roles
2. ❌ **Financial Sync**: No sync with Progress Tracking budget
3. ❌ **Inline Editing**: No click-to-edit functionality
4. ❌ **Row Action Icons**: Missing Undo/Regenerate icons, not on hover
5. ❌ **Smart Delete**: No undo snackbar
6. ❌ **AI Regeneration**: No AI for Key Terms
7. ❌ **Text Formatting**: "." bullet rule not applied
8. ❌ **Status Pills**: Need to update to Draft/Signed/Active/Expired
9. ❌ **Table Headers**: Not center-aligned

### Priority P1 (High - Fix Soon)
10. ⚠️ **Contract Health Cards**: Minor label updates needed
11. ⚠️ **Contract Type Dropdown**: Needs to be: SLA, NDA, Procurement, Employment

---

## 10. Files Requiring Changes

### High Priority (Core Functionality)
1. **`lib/screens/contracts_tracking_screen.dart`**
   - Add staff integration logic
   - Update summary cards labels
   - Replace DataTable with custom widget
   - Update status options
   - Remove any Firebase UI mentions

2. **`lib/widgets/contracts_table_widget.dart`** (NEW)
   - Custom table with inline editing
   - Center-aligned headers
   - Hover effects with action icons
   - Undo/Regenerate/Delete functionality
   - Status pills
   - Apply "." bullet rule to Key Terms

3. **`lib/services/contract_service.dart`**
   - Add method to sync contract values to budget
   - Document field usage (scope = Key Terms, notes = Contract Notes)

4. **`lib/services/openai_service_secure.dart`**
   - Add `generateContractKeyTerms` method

5. **`lib/services/execution_phase_service.dart`**
   - Add method to update budget with contract values

---

## 11. Implementation Strategy

### Phase 1: Data Integration (P0)
1. Add staff integration to fetch External/Contractor roles
2. Add financial sync to Progress Tracking budget
3. Update ContractModel documentation

### Phase 2: Visual UI (P0)
4. Create custom contracts table widget
5. Update summary cards labels
6. Implement status pills (Draft/Signed/Active/Expired)
7. Center-align headers

### Phase 3: CRUD Enhancements (P0)
8. Implement inline editing
9. Add row action icons (Undo/Regenerate/Delete) with hover
10. Implement smart delete with undo snackbar

### Phase 4: AI & Formatting (P0)
11. Add AI regeneration for Key Terms
12. Apply "." bullet rule to Key Terms
13. Ensure Contract Notes remain prose

---

## 12. Verification Checklist

Before implementation, verify:
- [ ] Staff Needs integration fetches External/Contractor roles correctly
- [ ] Contract values sync to Progress Tracking budget
- [ ] Inline editing works for all fields
- [ ] Undo snackbar appears and functions correctly
- [ ] AI regeneration icons visible and functional
- [ ] "." bullet rule applied to Key Terms only
- [ ] Contract Notes remain prose (no bullets)
- [ ] Status pills display correctly (Draft/Signed/Active/Expired)
- [ ] Headers are center-aligned
- [ ] No Firebase mentions in UI

---

**End of Gap Analysis**
