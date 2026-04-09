---
description: "Task list for fixing deprecation warnings"
---

# Tasks: Fix Deprecation Warnings

**Input**: Design documents from `specs/001-fix-deprecations/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, quickstart.md ✅

**Tests**: No new tests — existing unit and UI test suites are the regression
gate (FR-003, FR-004). Verification tasks run the existing suite.

**Organization**: Phase 3 tasks are fully parallel (all touch different files).

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup

**Purpose**: Establish the warning baseline before making any changes.

- [X] T001 Capture warning baseline using the command in `specs/001-fix-deprecations/quickstart.md` Step 1 and record the output for comparison

**Checkpoint**: Baseline recorded — 10 warnings expected across 4 files.

---

## Phase 2: Foundational

No shared infrastructure required. All fixes are independent.

---

## Phase 3: User Story 1 — Clean Build Output (Priority: P1) 🎯 MVP

**Goal**: Replace all deprecated API usages so the project builds with zero
deprecation warnings.

**Independent Test**: Run `xcodebuild clean build-for-testing -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" 2>&1 | grep -i "warning:" | grep -v "xcodebuild: WARNING"` and confirm no output.

### Implementation for User Story 1

- [X] T002 [P] [US1] Fix `Source/TCCProfileImporter/TCCProfileConfigurationPanel.swift`:
  add `import UniformTypeIdentifiers` after the existing imports; replace line 40
  `openPanel.allowedFileTypes = ["mobileconfig", "plist"]` with
  `openPanel.allowedContentTypes = [UTType(filenameExtension: "mobileconfig")!, .propertyList]`

- [X] T003 [P] [US1] Fix `Source/View Controllers/TCCProfileViewController.swift`:
  add `import UniformTypeIdentifiers` after existing imports;
  replace line 204 `panel.allowedFileTypes = [kUTTypeBundle, kUTTypeUnixExecutable] as [String]`
  with `panel.allowedContentTypes = [.bundle, .unixExecutable]`;
  replace line 232 `[kUTTypeBundle, kUTTypeUnixExecutable]` in `pasteboardOptions`
  with `[UTType.bundle.identifier, UTType.unixExecutable.identifier]`

- [X] T004 [P] [US1] Fix `Source/View Controllers/OpenViewController.swift`:
  add `import UniformTypeIdentifiers` after `import Cocoa`;
  replace line 69 `panel.allowedFileTypes = [kUTTypeBundle, kUTTypeUnixExecutable] as [String]`
  with `panel.allowedContentTypes = [.bundle, .unixExecutable]`

- [X] T005 [P] [US1] Fix `Source/View Controllers/SaveViewController.swift`:
  add `import UniformTypeIdentifiers` after existing imports;
  replace line 80 `panel.allowedFileTypes = ["mobileconfig"]`
  with `panel.allowedContentTypes = [UTType(filenameExtension: "mobileconfig")!]`;
  add `nonisolated(unsafe)` to line 33: change
  `private static var saveProfileKVOContext = 0` to
  `nonisolated(unsafe) private static var saveProfileKVOContext = 0`

**Checkpoint**: All 4 files updated. Build should now produce zero warnings.

---

## Phase 4: User Story 2 — No Regression (Priority: P2)

**Goal**: Confirm that the deprecation fixes introduce no behaviour changes.

**Independent Test**: All existing unit and UI tests pass; zero warnings in
build output.

### Verification for User Story 2

- [X] T006 [US2] Build the project and verify zero warnings: run the baseline
  command from `specs/001-fix-deprecations/quickstart.md` Step 3 and confirm
  no output; compare against T001 baseline

- [X] T007 [US2] Run the full test suite per `specs/001-fix-deprecations/quickstart.md`
  Step 4 and confirm all unit and UI tests pass with no failures

**Checkpoint**: Zero warnings, all tests green — feature complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **User Story 1 (Phase 3)**: Depends on baseline being captured (T001)
  — T002, T003, T004, T005 are all parallel once T001 is done
- **User Story 2 (Phase 4)**: Depends on all Phase 3 tasks complete

### Parallel Opportunities

All Phase 3 tasks touch different files and can be executed simultaneously:

```
After T001 completes:
  Task: T002 — TCCProfileConfigurationPanel.swift
  Task: T003 — TCCProfileViewController.swift
  Task: T004 — OpenViewController.swift
  Task: T005 — SaveViewController.swift

After T002–T005 all complete:
  Task: T006 — Build verification
  Task: T007 — Test suite
```

---

## Implementation Strategy

### MVP (User Story 1 only)

1. T001: Capture baseline
2. T002–T005 in parallel: Apply all 4 fixes
3. T006: Verify zero warnings
4. **STOP and VALIDATE**: Zero warnings confirmed → US1 done

### Full Delivery

1. Complete MVP above
2. T007: Run full test suite
3. All green → feature complete

---

## Notes

- [P] tasks = different files, fully independent
- All fixes are minimal substitutions — no restructuring
- `UTType(filenameExtension: "mobileconfig")!` is safe to force-unwrap:
  `mobileconfig` is a registered Apple type available on all supported OS versions
- The `nonisolated(unsafe)` fix is a concurrency warning, not a deprecation;
  included because it appears in the same warning baseline captured by T001
