# Tasks: Add New PPPC Keys

**Input**: Design documents from `/specs/002-add-pppc-keys/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, quickstart.md

**Tests**: Included — explicitly requested in spec (TR-001 through TR-006).

**Organization**: US1 (BluetoothAlways), US2 (SystemPolicyAppBundles), and US3 (SystemPolicyAppData) all modify the same files and are implemented together in shared phases. US4 (Round-Trip Consistency) is a separate testing phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Desktop app (macOS)**: `Source/`, `Resources/`, tests at `PPPC UtilityTests/`, `PPPC UtilityUITests/`

---

## Phase 1: Setup

**Purpose**: Capture baseline before any changes

- [X] T001 Capture baseline compiler warnings by running: `xcodebuild clean build-for-testing -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" 2>&1 | grep -i "warning:" | grep -v "xcodebuild: WARNING"`
- [X] T002 Run existing unit tests to confirm green baseline: `xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" -testPlan "PPPC Utility"`
- [X] T003 Run existing UI tests to confirm green baseline: `xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" -testPlan "PPPC Utility UI Tests"`

---

## Phase 2: Foundational — Data Model (All 3 Keys)

**Purpose**: Add BluetoothAlways, SystemPolicyAppBundles, and SystemPolicyAppData to the data layer. MUST be complete before UI or test work can begin.

**⚠️ CRITICAL**: No UI or test work can begin until this phase is complete.

- [X] T004 [P] [US1] [US2] [US3] Add 3 new service entries to `Resources/PPPCServices.json` — insert `BluetoothAlways` (after Accessibility, alphabetically), `SystemPolicyAppBundles` (after SystemPolicyAllFiles), and `SystemPolicyAppData` (after SystemPolicyAppBundles). Each entry has `mdmKey`, `englishName`, and `englishDescription` per data-model.md. No `entitlements`, `denyOnly`, or `allowStandardUsers` fields.
- [X] T005 [P] [US1] [US2] [US3] Add 3 new enum cases to `ServicesKeys` in `Source/Model/TCCProfile.swift` — add `case bluetoothAlways = "BluetoothAlways"`, `case appBundles = "SystemPolicyAppBundles"`, `case appData = "SystemPolicyAppData"`.
- [X] T006 [P] [US1] [US2] [US3] Add 3 new `@objc dynamic` properties to the `Policy` class in `Source/Model/Executable.swift` — add `@objc dynamic var BluetoothAlways: String = "-"`, `@objc dynamic var SystemPolicyAppBundles: String = "-"`, `@objc dynamic var SystemPolicyAppData: String = "-"`. Property names MUST exactly match MDM key strings (KVC requirement).

**Checkpoint**: Data model complete. Build should succeed with no new warnings. Existing tests may now fail (service count assertions) — expected.

---

## Phase 3: US1+US2+US3 — View Controller & Storyboard UI

**Goal**: Make all 3 new services visible and configurable in the PPPC Utility UI.

**Independent Test**: Open the app, add an executable, verify Bluetooth Always / App Bundles / App Data popups appear with Allow/Deny options.

### Implementation

- [X] T007 [US1] [US2] [US3] Add IBOutlet declarations for all 3 new services in `Source/View Controllers/TCCProfileViewController.swift` — for each service, add: `NSPopUpButton` outlet, `NSArrayController` outlet, `InfoButton` outlet, and `NSStackView` outlet. Follow the naming pattern of existing outlets (e.g., `bluetoothAlwaysPopUp`, `bluetoothAlwaysPopUpAC`, `bluetoothAlwaysHelpButton`, `bluetoothAlwaysStackView`).
- [X] T008 [US1] [US2] [US3] Wire new services into setup methods in `Source/View Controllers/TCCProfileViewController.swift` — add the 3 new `NSArrayController` outlets to the `setupAllowDeny()` call in `viewDidLoad()`. Add the 3 new `InfoButton` outlets to `setupDescriptions()` with their MDM keys. Add the 3 new `NSStackView` outlets to `setupStackViewsWithBackground()` (for alternating row backgrounds). Add accessibility identifiers for the 3 new popups in `setupAccessibilityIdentifiers()`.
- [X] T009 [US1] [US2] [US3] Add UI elements for all 3 new services in `Resources/Base.lproj/Main.storyboard` — for each service, duplicate an existing service row (e.g., the Reminders row pattern) and update: label text, popup button binding to the corresponding `Policy` property via Cocoa Bindings, NSArrayController connection, InfoButton connection, and NSStackView connection. Wire all IBOutlets to the view controller.

**Checkpoint**: All 3 services visible in UI. Build and launch app to verify popups appear. Cocoa Bindings functional (selecting Allow/Deny updates the Policy object).

---

## Phase 4: US1+US2+US3 — Unit Tests

**Goal**: Verify data model correctness for all 3 new keys via automated tests.

### Tests

- [X] T010 [P] [US1] [US2] [US3] Update service count assertion in `PPPC UtilityTests/ModelTests/PPPCServicesManagerTests.swift` — change expected `allServices.count` from 21 to 24. Add assertions that `allServices["BluetoothAlways"]`, `allServices["SystemPolicyAppBundles"]`, and `allServices["SystemPolicyAppData"]` are non-nil with correct `englishName` values. (Satisfies TR-001)
- [X] T011 [P] [US1] [US2] [US3] Update policy defaults test in `PPPC UtilityTests/ModelTests/ExecutableTests.swift` — verify that a new `Executable`'s `policy.BluetoothAlways`, `policy.SystemPolicyAppBundles`, and `policy.SystemPolicyAppData` all default to `"-"`. Update any existing count-based assertions for total policy properties. (Satisfies TR-002)
- [X] T012 [P] [US1] [US2] [US3] Add new keys to `buildTCCPolicies()` in `PPPC UtilityTests/Helpers/TCCProfileBuilder.swift` — add `"BluetoothAlways"`, `"SystemPolicyAppBundles"`, and `"SystemPolicyAppData"` entries to the returned dictionary so round-trip tests exercise the new keys.
- [X] T013 [US1] [US2] [US3] Add export/import round-trip tests in `PPPC UtilityTests/ModelTests/ModelTests.swift` — add tests verifying that for each of the 3 new keys, setting a policy to Allow or Deny, exporting, and re-importing preserves the value. Use `ModelBuilder` to create executables with specific policy settings. (Satisfies TR-003)

**Checkpoint**: Run unit test plan — all tests pass including updated service count, defaults, and round-trip assertions.

---

## Phase 5: US4 — Import Testing & Legacy Fixtures

**Goal**: Verify round-trip fidelity and backward-compatible import of older profiles.

**Independent Test**: Import a legacy profile (without new keys) — new columns default to "–". Import a modern profile (with new keys) — values correctly displayed.

### Test Fixtures

- [X] T014 [P] [US4] Rename existing fixture `PPPC UtilityTests/TCCProfileImporterTests/TestTCCUnsignedProfile.mobileconfig` to `TestTCCUnsignedProfile-Legacy.mobileconfig` — this preserves the original file (without new keys) as the legacy import fixture. Update the Xcode project file if the resource is referenced by name.
- [X] T015 [P] [US4] Create new `PPPC UtilityTests/TCCProfileImporterTests/TestTCCUnsignedProfile.mobileconfig` — copy from the legacy file and add `BluetoothAlways`, `SystemPolicyAppBundles`, and `SystemPolicyAppData` service entries with test policy dictionaries (Allowed: true, Identifier, CodeRequirement, IdentifierType, Comment). Follow the exact XML plist structure of existing service entries.
- [X] T016 [P] [US4] Update `PPPC UtilityTests/TCCProfileImporterTests/TestTCCUnsignedProfile-allLower.mobileconfig` — add `bluetoothalways`, `systempolicyappbundles`, and `systempolicyappdata` entries (lowercase keys) following the existing lowercase pattern.
- [X] T017 [P] [US4] Update `Resources/TestTCCUnsignedProfile.mobileconfig` — add the 3 new service entries (same as T015) so the app-bundled UI test profile includes all 24 services.

### Tests

- [X] T018 [US4] Add legacy import test in `PPPC UtilityTests/TCCProfileImporterTests/TCCProfileImporterTests.swift` — add a test that imports `TestTCCUnsignedProfile-Legacy.mobileconfig`, feeds it through `Model.importProfile()`, and verifies the 3 new policy columns default to `"-"` on all imported executables. (Satisfies TR-005)
- [X] T019 [US4] Verify existing `correctUnsignedProfileContentData` test passes with the new fixture in `PPPC UtilityTests/TCCProfileImporterTests/TCCProfileImporterTests.swift` — the test should now import a profile with all 24 services and succeed. (Satisfies TR-004)

**Checkpoint**: All importer tests pass. Legacy profile imports cleanly. Modern profile imports with all 24 services.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: UI test, final validation, quality gate checks

- [X] T020 [US1] [US2] [US3] Add or update a UI test in `PPPC UtilityUITests/AppLaunchTests.swift` to verify the policy table column count reflects the 3 new services. Use the `-UITestMode` launch argument (which loads the test profile) and assert expected popup/column count. (Satisfies TR-006)
- [X] T021 Compare compiler warnings against T001 baseline — verify no new warnings introduced by running the same command and diffing output.
- [X] T022 Run full unit test plan and verify all tests pass: `xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" -testPlan "PPPC Utility"`
- [X] T023 Run full UI test plan and verify all tests pass: `xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" -testPlan "PPPC Utility UI Tests"`
- [X] T024 Validate quickstart.md build and test commands still work per `specs/002-add-pppc-keys/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001-T003) — BLOCKS all subsequent phases
- **View Controller & UI (Phase 3)**: Depends on Phase 2 (data model must exist for bindings)
- **Unit Tests (Phase 4)**: Depends on Phase 2 (data model). Can overlap with Phase 3 (different files).
- **Import Testing (Phase 5)**: Depends on Phase 2 (data model). Can overlap with Phase 3 and 4 (different files).
- **Polish (Phase 6)**: Depends on Phases 3, 4, 5 all complete

### User Story Dependencies

- **US1, US2, US3 (all P1)**: Implemented together — same files, same pattern, no benefit to separation. All depend on Phase 2.
- **US4 (P2)**: Depends on Phase 2 data model only. Can be worked in parallel with Phase 3 (UI) and Phase 4 (unit tests).

### Within-Phase Task Dependencies

- **Phase 2**: T004, T005, T006 are all [P] — different files, run in parallel
- **Phase 3**: T007 → T008 → T009 (sequential within same files)
- **Phase 4**: T010, T011, T012 are [P] — different files. T013 depends on T012 (builder)
- **Phase 5**: T014, T015, T016, T017 are [P] — different files. T018, T019 depend on T014+T015

### Parallel Opportunities

```text
Phase 2 (all parallel):
  T004 (PPPCServices.json) ║ T005 (TCCProfile.swift) ║ T006 (Executable.swift)

Phase 4 + Phase 5 fixtures (overlap with Phase 3):
  T010 (ServicesManagerTests) ║ T011 (ExecutableTests) ║ T012 (TCCProfileBuilder)
  T014 (rename fixture) ║ T015 (new fixture) ║ T016 (allLower fixture) ║ T017 (Resources fixture)
```

---

## Implementation Strategy

### MVP First (Phase 1 + 2 + 3)

1. Complete Phase 1: Capture baselines
2. Complete Phase 2: Data model (3 parallel tasks)
3. Complete Phase 3: View controller + storyboard
4. **STOP and VALIDATE**: Launch app, add an executable, verify all 3 new popups appear with Allow/Deny

### Incremental Delivery

1. Setup + Foundational → Data model ready
2. View Controller + UI → All 3 services visible and functional (MVP!)
3. Unit Tests → Automated verification of data model
4. Import Tests + Legacy → Backward compatibility verified
5. Polish → Quality gates pass, ready to merge

---

## Notes

- [P] tasks = different files, no dependencies
- US1+US2+US3 are co-implemented because they share all files (PPPCServices.json, TCCProfile.swift, Executable.swift, TCCProfileViewController.swift, Main.storyboard). Splitting them would create constant same-file conflicts with no benefit.
- Storyboard changes (T009) are the highest-risk task due to XML merge fragility — do this in a focused commit.
- KVC property names in Policy class MUST exactly match MDM key strings — a mismatch causes silent binding failure.
