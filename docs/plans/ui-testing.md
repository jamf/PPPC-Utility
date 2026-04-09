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

### Conventions

- Prefer **multiple assertions per test** to minimize app launches — each test method relaunches the app, which is expensive
- Do not use `// when` / `// then` comment blocks in UI tests — they add noise in assertion-heavy tests
- The UI test target uses **Swift 5 with minimal concurrency checking** (XCTestCase lifecycle methods are nonisolated, incompatible with MainActor default isolation)
- No `SWIFT_DEFAULT_ACTOR_ISOLATION` on the UI test target

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

---

## Phase 1 — Infrastructure & App Launch ✅

**Goal:** Create the UI test target, prove the app launches and the main window is testable.

### Work

| Item | Detail |
|------|--------|
| Add `PPPC UtilityUITests` target | Xcode UI Testing Bundle targeting `PPPC Utility.app` |
| Add accessibility identifiers to `TCCProfileViewController` | Executables table, Apple Events table, Save button, Upload button, add/remove buttons |
| Add `-UITestMode` launch argument support | Check flag in `TCCProfileViewController.viewDidLoad`; when set, load a bundled test `.mobileconfig` into `Model.shared` |
| Add programmatic drop hook | `#if DEBUG` method that synthesizes a drop operation on the executables table from a file URL |
| `AppLaunchTests.swift` | Verify app launches, main window exists, tables visible, all key buttons present, and correct buttons disabled at empty startup (Save, Upload, Remove Executable, Add Apple Event, Remove Apple Event should be disabled; Add Executable should be enabled) |

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

---

## Files touched across all phases

```
PPPC Utility.xcodeproj/project.pbxproj                          (Phase 1 — add UI test target)
Source/View Controllers/TCCProfileViewController.swift            (Phase 1-4 — accessibility identifiers, test harness)
Source/View Controllers/SaveViewController.swift                  (Phase 3 — accessibility identifiers)
Source/View Controllers/OpenViewController.swift                  (Phase 4 — accessibility identifiers)
Source/SwiftUI/UploadInfoView.swift                               (Phase 5 — accessibility identifiers)
PPPC UtilityUITests/                                              (Phase 1-5 — all new test files)
```

---

## CI considerations

- macOS UI tests require a GUI session (not headless). GitHub Actions macOS runners support this.

## What this plan does NOT cover

- Automating `NSOpenPanel` file selection (bypassed via launch argument)
- Drag-and-drop from Finder (bypassed via programmatic drop simulation)
- Dark mode visual regression (can be added later if needed)
- Real keychain / signing identity interactions
- Real Jamf Pro server upload (network stubbed via scoped injection)
