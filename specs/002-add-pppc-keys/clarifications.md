# Clarification Log: Add New PPPC Keys

**Feature**: 002-add-pppc-keys  
**Date**: 2026-04-09  
**Topic**: Unit testing and UI testing plans

## Questions & Resolutions

### Q1: Unit test scope for the 3 new keys

**Options presented**: (A) All: services manager, policy defaults, export/import round-trip; (B) Minimal: only services manager + policy defaults; (C) Export/import only.

**Resolution**: **A — Full coverage** across all existing service-related test areas. Services manager count assertion (21→24), policy defaults, and export/import round-trip with both Allow and Deny values.

---

### Q2: UI test updates

**Options presented**: (A) Add UI assertions for each new column; (B) No new UI tests; (C) Minimal — one test verifying total column count increased.

**Resolution**: **C — Minimal**. One UI test verifying the total column count increased. Column-level assertions would be brittle.

---

### Q3: Special behaviors (deny-only, allowStandardUsers)

**Options presented**: (A) All 3 are standard; (B) One or more have special behavior.

**Resolution**: **A — All 3 are standard**. Confirmed via Apple's official MDM documentation:
- None of the 3 new keys contain "can't be given in a profile; it can only be denied" language.
- `AllowStandardUserToSetSystemService` is explicitly limited to `ListenEvent` and `ScreenCapture` only.

User initially selected B but confirmed A after reviewing Apple docs.

---

### Q4: Test fixture strategy

**Options presented**: (A) Update existing fixtures; (B) Create new fixtures; (C) Both.

**Resolution**: **A+legacy — Update existing fixtures AND maintain a legacy fixture**. Existing `.mobileconfig` fixtures should be updated to include the 3 new keys. A legacy fixture (without the new keys) must be kept or added to verify backward-compatible import (new columns default to "–").

## Spec Changes Made

- Added **Testing Requirements** section (TR-001 through TR-006) to the spec.
- Updated FR-005 to explicitly state all 3 keys are standard (not deny-only, no allowStandardUsers) — confirmed fact rather than assumption.
- Updated Assumptions to reflect confirmed deny-only/allowStandardUsers status from Apple docs.

---

## Clarification Round 2 — 2026-04-09

**Topic**: Test fixture strategy for legacy import testing

### Q5: How to test legacy import without adding a test file?

**Context**: The plan called for both updating existing `.mobileconfig` fixtures (TR-004) and maintaining a legacy fixture (TR-005), but these goals conflicted without adding a new file.

**Resolution**: Use a **rename + replace** approach:
- **Rename** the existing `TestTCCUnsignedProfile.mobileconfig` → `TestTCCUnsignedProfile-Legacy.mobileconfig` (preserves the original without new keys)
- **Create** a new `TestTCCUnsignedProfile.mobileconfig` with all 24 services
- **Update** `TestTCCUnsignedProfile-allLower.mobileconfig` with the 3 new keys in lowercase
- **Update** `Resources/TestTCCUnsignedProfile.mobileconfig` (app-bundled UI test profile) with new keys
- **Add** a test in `TCCProfileImporterTests` that imports the legacy fixture and verifies new columns default to "–"

### Spec & Plan Changes Made

- Updated TR-004 and TR-005 in spec to reflect the rename + new file strategy.
- Updated plan project structure to show `TestTCCUnsignedProfile-Legacy.mobileconfig`.
