# UI Testing — Phased Plan

## Context

PPPC Utility has 98 unit tests at ~45% production code coverage, but zero UI test coverage. The app has four main UI surfaces:

| Surface | Framework | Lines | Role |
|---------|-----------|-------|------|
| `TCCProfileViewController` | AppKit (Storyboard) | 447 | Main window — executable table, policy popups, Apple Events table |
| `SaveViewController` | AppKit (Storyboard) | 171 | Modal sheet — profile name, signing identity, export |
| `OpenViewController` | AppKit (Storyboard) | 91 | Modal sheet — Apple Event destination picker |
| `UploadInfoView` | SwiftUI | 365 | Sheet — Jamf Pro connection, payload config, upload |

No UI test target exists yet. This plan adds one incrementally.

### Tools

- **XCUITest** for interaction tests (launch, tap, type, assert element state)
- **swift-snapshot-testing** (pointfreeco) for automated visual regression via screenshot comparison

### Test data strategy

`NSOpenPanel` and Finder drag-and-drop can't be reliably automated by XCUITest (the panel runs in a separate system process). Two complementary approaches:

1. **Launch argument (`-UITestMode`)** — app checks for the flag at startup and preloads a bundled test profile into `Model.shared`. Most tests use this for a deterministic starting state.
2. **Programmatic drop simulation** — a test hook calls the table's `performDragOperation` with a pasteboard containing a known app URL (e.g., Books.app). Tests the drop handler logic without automating Finder.

### Network stubbing strategy

Upload/connection tests use **scoped `URLSession` injection**. When the app detects `-UITestStubNetwork`, it creates an ephemeral `URLSession` wired to `MockURLProtocol` and passes it to `UploadManager(session:)`. Only upload-related calls are intercepted; `URLSession.shared` remains untouched.

---

## Quality gates (apply to every phase)

1. All existing unit tests still pass after each phase.
2. No new compiler warnings.
3. UI tests pass in a clean `xcodebuild test` run.
4. Snapshot references checked into the repo under a clearly named directory.

---

## Phase 1 — Infrastructure & App Launch

**Goal:** Create the UI test target, add swift-snapshot-testing, prove the app launches and the main window is testable.

### Work

| Item | Detail |
|------|--------|
| Add `PPPC UtilityUITests` target | Xcode UI Testing Bundle targeting `PPPC Utility.app` |
| Add `swift-snapshot-testing` SPM dependency | Test-only dependency on the UI test target |
| Add accessibility identifiers to `TCCProfileViewController` | Executables table, Apple Events table, Save button, Upload button, add/remove buttons |
| Add `-UITestMode` launch argument support | Check flag in `TCCProfileViewController.viewDidLoad`; when set, load a bundled test `.mobileconfig` into `Model.shared` |
| Add programmatic drop hook | Test-only method that synthesizes a drop operation on the executables table from a file URL |
| `AppLaunchTests.swift` | Verify app launches, main window exists, executables table visible, key buttons present |
| `MainWindowSnapshotTests.swift` | Snapshot of empty main window (no executables loaded) as visual baseline |

### Verification

```
xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" -only-testing:"PPPC UtilityUITests"
```

---

## Phase 2 — Profile Building Interactions

**Goal:** Test the core workflow — executables in the table, policy popup changes, drop handler.

### Accessibility identifiers needed

- Each of the ~20 policy popup buttons (e.g., `Policy.addressBookPopUp`)
- Executable detail labels (name, identifier, code requirement)
- Add/remove executable buttons

### New test files

| File | What it tests |
|------|---------------|
| `ExecutableManagementTests.swift` | Launch with `-UITestMode` → verify preloaded executable appears in table; select executable → verify detail labels populated; remove executable → verify table row gone |
| `DropHandlerTests.swift` | Programmatic drop of Books.app URL onto executables table → verify new row appears with correct name/identifier |
| `PolicySelectionTests.swift` | Select executable → change a policy popup → verify popup value persists after re-selecting the executable; verify initial state is "-" for all popups |
| `ProfileBuildingSnapshotTests.swift` | Snapshot of main window with one executable added and policies set |

---

## Phase 3 — Profile Import & Save Sheet

**Goal:** Test importing an existing profile and the save sheet flow.

### Accessibility identifiers needed

- `SaveViewController`: payload name field, organization field, signing identity popup, save button

### New test files

| File | What it tests |
|------|---------------|
| `ProfileImportTests.swift` | Launch with `-UITestMode` (preloaded profile) → verify executables table populated with expected rows; verify policy values match imported profile |
| `SaveSheetTests.swift` | Trigger save sheet → verify fields present (payload name, org, signing identity); verify save button disabled when required fields empty; verify save button enabled when fields filled |
| `SaveSheetSnapshotTests.swift` | Snapshot of save sheet in default state and with fields filled |

### Test data

- Bundle a sample `.mobileconfig` in the UI test target's resources.

---

## Phase 4 — Apple Events

**Goal:** Test Apple Event rule creation using the preloaded destination list.

### Accessibility identifiers needed

- `OpenViewController`: choices table (no browse button testing needed)
- Apple Events table, add/remove Apple Event buttons

### New test files

| File | What it tests |
|------|---------------|
| `AppleEventTests.swift` | Select executable → click Add Apple Event → OpenViewController appears → select destination from preloaded choices table → rule appears in Apple Events table; remove rule → table row gone |
| `AppleEventSnapshotTests.swift` | Snapshot of Apple Events table with one rule present |

---

## Phase 5 — Upload Sheet (SwiftUI)

**Goal:** Test the UploadInfoView form validation and field interactions. Network calls stubbed via scoped `URLSession` injection.

### Accessibility identifiers needed

- All SwiftUI fields and buttons in `UploadInfoView` (use `.accessibilityIdentifier()` modifier)

### Production change

- Add `-UITestStubNetwork` launch argument check where `UploadManager` is instantiated
- When set, create an ephemeral `URLSession` wired to `MockURLProtocol` and pass to `UploadManager(session:)`

### New test files

| File | What it tests |
|------|---------------|
| `UploadSheetTests.swift` | Open upload sheet → verify all fields present; verify "Check connection" button disabled with empty URL; enter URL + credentials → button enabled; verify auth type picker switches between Basic Auth and Client Credentials fields; verify "Use Site" toggle shows/hides site fields |
| `UploadSheetSnapshotTests.swift` | Snapshots: empty form, Basic Auth filled, Client Credentials filled, site fields visible |

---

## Phase 6 — Visual Regression Baseline

**Goal:** Capture light-mode snapshots of key screens as a regression baseline.

### New test files

| File | What it tests |
|------|---------------|
| `FullWorkflowSnapshotTests.swift` | End-to-end snapshots in default (light) mode: empty state → executable added → policies configured → Apple Event added → save sheet → upload sheet |

---

## Files touched across all phases

```
PPPC Utility.xcodeproj/project.pbxproj                          (Phase 1 — add UI test target)
Package.swift or SPM config                                       (Phase 1 — swift-snapshot-testing dep)
Source/View Controllers/TCCProfileViewController.swift            (Phase 1-4 — accessibility identifiers, test harness)
Source/View Controllers/SaveViewController.swift                  (Phase 3 — accessibility identifiers)
Source/View Controllers/OpenViewController.swift                  (Phase 4 — accessibility identifiers)
Source/SwiftUI/UploadInfoView.swift                               (Phase 5 — accessibility identifiers)
PPPC UtilityUITests/                                              (Phase 1-6 — all new test files)
```

---

## CI considerations

- macOS UI tests require a GUI session (not headless). GitHub Actions macOS runners support this.
- Snapshot tests are sensitive to OS version and screen scale. Pin to a specific macOS version in CI.
- On first run, snapshot tests generate reference images (test fails). Commit the references, then subsequent runs compare against them.

## What this plan does NOT cover

- Automating `NSOpenPanel` file selection (bypassed via launch argument)
- Drag-and-drop from Finder (bypassed via programmatic drop simulation)
- Dark mode visual regression (can be added later if needed)
- Real keychain / signing identity interactions
- Real Jamf Pro server upload (network stubbed via scoped injection)
