# SwiftUI Migration Plan

**Created:** 2026-04-10
**Status:** Approved
**Branch:** `feature/swiftui-migration`

## Overview

This plan outlines the complete migration of PPPC Utility from AppKit (Storyboards + NSViewController) to a modern SwiftUI-based architecture. The goal is to modernize the UI, improve maintainability, and leverage SwiftUI's declarative patterns while maintaining all existing functionality.

## Current State

### Architecture
- **UI Framework:** AppKit with Main.storyboard
- **App Entry:** AppDelegate-based lifecycle
- **Main View:** TCCProfileViewController (~500 LOC, 70+ IBOutlets)
- **Modal Views:** SaveViewController, OpenViewController (AppKit)
- **Hybrid:** UploadInfoView (already SwiftUI ✓)
- **Model Layer:** Swift Concurrency with MainActor isolation
- **Deployment Target:** macOS 13.0

### Components Breakdown
```
AppKit Views (to migrate):
├── AppDelegate.swift
├── Main.storyboard
├── View Controllers/
│   ├── TCCProfileViewController.swift (main view)
│   ├── SaveViewController.swift (modal)
│   └── OpenViewController.swift (modal)
└── Views/
    ├── InfoButton.swift
    ├── Alert.swift
    └── FlippedClipView.swift

SwiftUI Views (existing):
└── SwiftUI/
    └── UploadInfoView.swift ✓

Model (no changes needed):
└── Model/
    ├── Model.swift
    ├── Executable.swift
    ├── AppleEventRule.swift
    ├── TCCProfile.swift
    └── PPPCServicesManager.swift
```

## Target State

### Architecture
- **UI Framework:** 100% SwiftUI
- **App Entry:** SwiftUI App lifecycle (`@main struct PPPCUtilityApp: App`)
- **Deployment Target:** macOS 14.0 (n-2 from current macOS 16)
- **Design Language:** Modern macOS design with native SwiftUI patterns
- **Model Layer:** Same (no changes needed)

### Benefits
- Modern, maintainable codebase
- Better hot-reload development experience
- Native SwiftUI animations and transitions
- Improved accessibility out of the box
- Easier to add new features
- Cleaner separation of concerns
- Fresh, modern UI that doesn't look dated

## Migration Strategy

**Approach:** Incremental migration with parallel development
- Build SwiftUI views alongside existing AppKit views
- Swap components one at a time
- Maintain functionality throughout
- Remove AppKit code once SwiftUI equivalent is stable

**Recommendation:** **Complete migration** — Since UploadInfoView is already SwiftUI and the model layer is well-architected with Swift Concurrency, a complete migration will result in a cleaner, more maintainable codebase. Half-AppKit/half-SwiftUI architectures are harder to maintain long-term.

## Phases

### Phase 1: Foundation & Infrastructure
**Goal:** Establish SwiftUI patterns and project structure
**Effort:** Small (~1-2 days)
**Risk:** Low

#### Tasks
1. **Update deployment target to macOS 14.0**
   - Update project settings
   - Verify all dependencies support macOS 14.0
   - Document any API changes needed

2. **Create SwiftUI directory structure**
   ```
   Source/SwiftUI/
   ├── App/
   │   └── PPPCUtilityApp.swift (created in Phase 5)
   ├── Views/
   │   ├── Main/
   │   ├── Modals/
   │   └── Components/
   └── Helpers/
       ├── ViewModifiers/
       └── Extensions/
   ```

3. **Create shared view modifiers and helpers**
   - `SheetPresentation.swift` — Helper for presenting modals
   - `PanelPresentation.swift` — Wrapper for NSOpenPanel/NSSavePanel
   - `AlertModifier.swift` — Reusable alert presentation
   - `KeyboardShortcuts.swift` — Consistent keyboard shortcuts

4. **Create design system tokens**
   - `DesignSystem.swift` — Colors, spacing, typography
   - Prepare for modern macOS design language
   - Define consistent padding/spacing values

#### Acceptance Criteria
- [ ] Deployment target set to macOS 14.0
- [ ] Directory structure created
- [ ] Helper files created and documented
- [ ] Design system tokens defined
- [ ] No build errors

---

### Phase 2: Custom Components
**Goal:** Create SwiftUI equivalents of custom AppKit views
**Effort:** Small (~1 day)
**Risk:** Low
**Depends on:** Phase 1

#### Tasks
1. **Create InfoButtonView** (`Components/InfoButtonView.swift`)
   - SwiftUI Button with popover
   - Display help text in modern popover (not NSHelpManager)
   - Match visual style (? icon)
   - Support both inline and trailing placement

2. **Create AlertHelper** (`Helpers/AlertHelper.swift`)
   - Consolidate alert presentation logic
   - SwiftUI `.alert()` modifier wrapper
   - Support for error alerts with LocalizedError
   - Backwards compatibility during migration

3. **Identify FlippedClipView usage**
   - Search storyboard for usage
   - Document replacement strategy (SwiftUI List handles this natively)

#### Acceptance Criteria
- [ ] InfoButtonView displays help text in popover
- [ ] InfoButtonView visually matches existing design
- [ ] AlertHelper works with LocalizedError
- [ ] Documentation for FlippedClipView replacement

#### Files Created
- `Source/SwiftUI/Views/Components/InfoButtonView.swift`
- `Source/SwiftUI/Helpers/AlertHelper.swift`

---

### Phase 3: Modal Views
**Goal:** Migrate SaveViewController and OpenViewController to SwiftUI
**Effort:** Medium (~2-3 days)
**Risk:** Low
**Depends on:** Phase 2

#### Tasks
1. **Create SaveView** (`Modals/SaveView.swift`)
   - Form with fields: organization, payload name, identifier, description
   - Signing identity picker (populated from SecurityWrapper)
   - Save button triggers NSSavePanel
   - Validation (required fields, ready-to-save state)
   - Import profile info loading (from Model.shared.importedTCCProfile)
   - Modern macOS form design (not just porting old UI)
   - Preview with mock data

2. **Create OpenView** (`Modals/OpenView.swift`)
   - List of executable choices
   - Browse button with NSOpenPanel
   - Selection handling with completion callback
   - Loading state while fetching Apple Event choices
   - Modern macOS list design
   - Preview with mock data

3. **Integration with TCCProfileViewController (temporary)**
   - Present SaveView in NSHostingController (like UploadInfoView)
   - Present OpenView in NSHostingController
   - Verify functionality matches old modals

4. **Create NSPanel wrappers**
   - `FileImporterPanel.swift` — Wrapper for NSOpenPanel
   - `FileSaverPanel.swift` — Wrapper for NSSavePanel
   - Support for setting default directories, file types

#### Acceptance Criteria
- [ ] SaveView displays all fields correctly
- [ ] SaveView validates input and enables/disables save
- [ ] SaveView saves profiles successfully
- [ ] SaveView imports profile info when available
- [ ] OpenView displays executable choices
- [ ] OpenView allows browsing for executables
- [ ] OpenView returns selected executable
- [ ] Both views can be presented from existing AppKit view controller
- [ ] Previews work for both views

#### Files Created
- `Source/SwiftUI/Views/Modals/SaveView.swift`
- `Source/SwiftUI/Views/Modals/OpenView.swift`
- `Source/SwiftUI/Helpers/FileImporterPanel.swift`
- `Source/SwiftUI/Helpers/FileSaverPanel.swift`

#### Files Modified
- `Source/View Controllers/TCCProfileViewController.swift` (temporarily call new modals)

---

### Phase 4: Main View — Part 1 (Structure & Display)
**Goal:** Create SwiftUI main interface with read-only data display
**Effort:** Large (~4-5 days)
**Risk:** Medium
**Depends on:** Phase 3

#### Tasks
1. **Create ExecutableListView** (`Main/ExecutableListView.swift`)
   - List of executables with icons
   - Selection binding
   - Display count
   - Empty state (no executables yet)
   - Highlight selected item
   - Modern macOS sidebar style

2. **Create ExecutableDetailView** (`Main/ExecutableDetailView.swift`)
   - Display selected executable details:
     - Icon (large)
     - Display name
     - Bundle identifier
     - Code requirement (truncated, expandable)
   - Empty state when no selection
   - Modern card-style design

3. **Create AppleEventsListView** (`Main/AppleEventsListView.swift`)
   - Table of Apple Event rules (source → destination)
   - Display allow/deny status
   - Empty state
   - Read-only initially
   - Modern macOS table design

4. **Create PPPCServiceRow** (`Components/PPPCServiceRow.swift`)
   - Single row: label + InfoButton + Picker
   - Reusable for all permission types
   - Picker values based on service constraints
   - Disabled state styling

5. **Create PPPCServicesView** (`Main/PPPCServicesView.swift`)
   - Grouped sections:
     - Privacy (Address Book, Photos, Calendar, etc.)
     - Accessibility
     - Files (All Files, Desktop, Documents, etc.)
     - Media (Camera, Microphone, Screen Capture)
   - Use PPPCServiceRow for each service
   - Modern macOS grouped form style
   - ScrollView for long lists
   - Read-only initially (binding but no updates)

6. **Create MainContentView** (`Main/MainContentView.swift`)
   - NavigationSplitView layout:
     - Sidebar: ExecutableListView
     - Detail: ExecutableDetailView + tabs/sections
   - Tab or split view for:
     - Permissions (PPPCServicesView)
     - Apple Events (AppleEventsListView)
   - Toolbar with placeholder buttons:
     - Add Executable
     - Remove Executable
     - Import Profile
     - Save
     - Upload
   - Bind to Model.shared
   - Modern macOS window chrome

7. **Test in isolation**
   - Create preview window to display MainContentView
   - Load test data from Model.shared
   - Verify layout on different window sizes
   - Test light/dark mode

#### Acceptance Criteria
- [ ] ExecutableListView displays all executables
- [ ] ExecutableDetailView shows selected executable info
- [ ] AppleEventsListView displays rules
- [ ] PPPCServicesView displays all permissions with correct options
- [ ] MainContentView layout works on various window sizes
- [ ] All views have empty states
- [ ] All views work in light and dark mode
- [ ] Can read and display existing profile data
- [ ] Toolbar buttons are visible (even if non-functional)
- [ ] Navigation between sections works

#### Files Created
- `Source/SwiftUI/Views/Main/MainContentView.swift`
- `Source/SwiftUI/Views/Main/ExecutableListView.swift`
- `Source/SwiftUI/Views/Main/ExecutableDetailView.swift`
- `Source/SwiftUI/Views/Main/AppleEventsListView.swift`
- `Source/SwiftUI/Views/Main/PPPCServicesView.swift`
- `Source/SwiftUI/Views/Components/PPPCServiceRow.swift`

---

### Phase 5: Main View — Part 2 (Editing & Actions)
**Goal:** Make main interface fully interactive with all editing capabilities
**Effort:** Large (~4-5 days)
**Risk:** Medium
**Depends on:** Phase 4

#### Tasks
1. **Add executable management to ExecutableListView**
   - Wire up Add Executable button → present OpenView
   - Wire up Remove Executable button → delete from Model.shared
   - Implement drag & drop:
     - Option A: Use `.fileImporter()` modifier
     - Option B: Custom NSViewRepresentable if fine-grained control needed
   - Handle LoadExecutableError (show alerts)
   - Update list when model changes

2. **Add Apple Event management to AppleEventsListView**
   - Wire up Add Apple Event button → present OpenView with context
   - Wire up Remove Apple Event button → delete rule
   - Implement drag & drop (same as above)
   - Validation (prevent duplicate rules)
   - Update list when model changes

3. **Enable permission editing in PPPCServicesView**
   - Make all Pickers editable
   - Update Model.shared on selection change
   - Handle policy constraints:
     - Allow/Deny only services
     - Deny only services (Camera, Microphone)
     - Standard User Approve services (Screen Capture, Listen Event)
   - Disable picker when no executable selected
   - Visual feedback on changes

4. **Implement top-level actions in MainContentView**
   - Import Profile button:
     - Call TCCProfileConfigurationPanel/Importer (existing code)
     - Show alert on error
     - Refresh UI after import
   - Save button:
     - Present SaveView
     - Pass completion handler
   - Upload button:
     - Present UploadInfoView (already SwiftUI)
   - Wire up keyboard shortcuts:
     - Cmd+O for Import
     - Cmd+S for Save
     - Cmd+U for Upload

5. **Handle edge cases**
   - Multiple executable selection (if needed)
   - Empty model state
   - Invalid executables
   - Concurrent modifications

6. **Test all interactions**
   - Add/remove executables
   - Add/remove Apple Events
   - Edit permissions
   - Import/save/upload profiles
   - Drag & drop
   - Keyboard shortcuts

#### Acceptance Criteria
- [ ] Can add executables via button and drag & drop
- [ ] Can remove executables
- [ ] Can add Apple Event rules via button and drag & drop
- [ ] Can remove Apple Event rules
- [ ] Can edit all permission pickers
- [ ] Changes persist to Model.shared
- [ ] Import Profile works
- [ ] Save works (presents SaveView)
- [ ] Upload works (presents UploadInfoView)
- [ ] All keyboard shortcuts work
- [ ] Error handling works (alerts display)
- [ ] Validation prevents invalid states
- [ ] UI updates reactively to model changes

#### Files Modified
- `Source/SwiftUI/Views/Main/MainContentView.swift`
- `Source/SwiftUI/Views/Main/ExecutableListView.swift`
- `Source/SwiftUI/Views/Main/AppleEventsListView.swift`
- `Source/SwiftUI/Views/Main/PPPCServicesView.swift`

---

### Phase 6: App Lifecycle Migration
**Goal:** Replace AppDelegate with SwiftUI App lifecycle
**Effort:** Medium (~2 days)
**Risk:** Medium
**Depends on:** Phase 5

#### Tasks
1. **Create PPPCUtilityApp** (`App/PPPCUtilityApp.swift`)
   - Define `@main struct PPPCUtilityApp: App`
   - Create WindowGroup with MainContentView
   - Set window properties:
     - Title: "PPPC Utility"
     - Min/default size
     - Quit on last window closed
   - Handle `-UITestMode` launch argument:
     - Load test profile into Model.shared
     - Set up any test-specific state

2. **Migrate menu bar (if custom menus exist)**
   - Review Main.storyboard for custom menus
   - Use `.commands` modifier if needed
   - Document standard menus (File, Edit, etc.)

3. **Remove storyboard from project**
   - Update Info.plist (remove NSMainStoryboardFile)
   - Remove Main.storyboard reference
   - Update build settings if needed

4. **Test app lifecycle**
   - App launches with SwiftUI interface
   - Window configuration correct
   - Quit on last window closed works
   - `-UITestMode` still works
   - Model initialization works

#### Acceptance Criteria
- [ ] App launches with PPPCUtilityApp entry point
- [ ] MainContentView displays as main window
- [ ] Window size and title correct
- [ ] App quits when last window closed
- [ ] `-UITestMode` loads test profile correctly
- [ ] No storyboard in project
- [ ] No build errors or warnings

#### Files Created
- `Source/SwiftUI/App/PPPCUtilityApp.swift`

#### Files Deleted (staged for Phase 7)
- `Source/AppDelegate.swift` (will delete in Phase 7)
- `Resources/Base.lproj/Main.storyboard` (will delete in Phase 7)

#### Files Modified
- `Info.plist` (remove NSMainStoryboardFile)

---

### Phase 7: Cleanup & Optimization
**Goal:** Remove all AppKit view code and optimize SwiftUI implementation
**Effort:** Small (~1-2 days)
**Risk:** Low
**Depends on:** Phase 6

#### Tasks
1. **Delete deprecated AppKit files**
   - `Source/AppDelegate.swift`
   - `Resources/Base.lproj/Main.storyboard`
   - `Source/View Controllers/TCCProfileViewController.swift`
   - `Source/View Controllers/OpenViewController.swift`
   - `Source/View Controllers/SaveViewController.swift`
   - `Source/Views/InfoButton.swift`
   - `Source/Views/Alert.swift`
   - `Source/Views/FlippedClipView.swift`

2. **Update project file**
   - Remove deleted files from Xcode project
   - Verify build phases
   - Clean up any storyboard references

3. **Optimize SwiftUI views**
   - Review performance (use Instruments if needed)
   - Add `@ViewBuilder` where appropriate
   - Optimize list rendering if needed
   - Reduce unnecessary view updates

4. **UI polish**
   - Fine-tune spacing, padding, colors
   - Ensure dark mode works perfectly
   - Match (or improve) original layout where it makes sense
   - Apply modern macOS design language
   - Animation polish (list updates, modal presentation, etc.)
   - Accessibility improvements

5. **Documentation**
   - Add doc comments to all public views
   - Document view models if created
   - Update README with SwiftUI information
   - Add screenshots to docs

6. **Compiler warning audit**
   - Run clean build
   - Fix any new warnings
   - Verify no warnings added from migration

#### Acceptance Criteria
- [ ] All AppKit view files deleted
- [ ] Project builds without errors or warnings
- [ ] No references to deleted files
- [ ] UI is polished and modern
- [ ] Dark mode works correctly
- [ ] Performance is good (no lag)
- [ ] Code is documented
- [ ] README updated

#### Files Deleted
- `Source/AppDelegate.swift`
- `Resources/Base.lproj/Main.storyboard`
- `Source/View Controllers/TCCProfileViewController.swift`
- `Source/View Controllers/OpenViewController.swift`
- `Source/View Controllers/SaveViewController.swift`
- `Source/Views/InfoButton.swift`
- `Source/Views/Alert.swift`
- `Source/Views/FlippedClipView.swift`

---

### Phase 8: Testing & Validation
**Goal:** Comprehensive testing to ensure quality
**Effort:** Medium (~3-4 days)
**Risk:** Low
**Depends on:** Phase 7

#### Tasks
1. **Functional testing**
   - Test all workflows end-to-end:
     - Add executable
     - Configure permissions
     - Add Apple Events
     - Import profile
     - Export profile (save)
     - Upload to Jamf Pro
   - Test drag & drop
   - Test file panels (open/save)
   - Test keyboard shortcuts
   - Test with edge cases (empty model, invalid files, etc.)

2. **Unit test verification**
   - Run all existing unit tests
   - Verify all tests pass
   - Model layer should be unchanged (tests should pass as-is)
   - Fix any broken tests (should be minimal)

3. **UI test updates** *(Optional — Nice to have)*
   - Review existing UI tests
   - Update for SwiftUI accessibility identifiers
   - Verify `-UITestMode` works with UI tests
   - Update test helpers if needed
   - Add new UI tests for SwiftUI-specific interactions

4. **Regression testing**
   - Compare behavior with original AppKit version
   - Ensure no features lost
   - Verify all edge cases handled
   - Test error handling

5. **Performance testing**
   - Profile with Instruments
   - Check memory usage
   - Test with large profiles (many executables/rules)
   - Ensure no memory leaks
   - Verify responsive UI (no hangs)

6. **Accessibility testing**
   - Test with VoiceOver
   - Verify keyboard navigation
   - Check accessibility labels
   - Test with reduced motion
   - Test with increased contrast

7. **Cross-version testing** *(if applicable)*
   - Test on macOS 14.0 (minimum)
   - Test on macOS 15.0
   - Test on macOS 16.0 (current)
   - Document any version-specific issues

#### Acceptance Criteria
- [ ] All functional workflows work correctly
- [ ] All unit tests pass
- [ ] UI tests updated and passing (if doing this phase)
- [ ] No regressions from original app
- [ ] Performance is acceptable
- [ ] No memory leaks
- [ ] Accessibility works correctly
- [ ] Works on all supported macOS versions

---

### Phase 9: Final Polish & Release Preparation
**Goal:** Prepare for production release
**Effort:** Small (~1 day)
**Risk:** Low
**Depends on:** Phase 8

#### Tasks
1. **Final UI review**
   - Walk through entire app
   - Check for visual inconsistencies
   - Verify all animations smooth
   - Ensure tooltips/help text correct
   - Test on different screen sizes/resolutions

2. **Code review**
   - Review all new SwiftUI code
   - Check for code smells
   - Ensure consistent style
   - Verify CLAUDE.md conventions followed

3. **Update CHANGELOG**
   - Document all changes
   - Note minimum macOS version change (13.0 → 14.0)
   - Highlight UI improvements
   - Credit contributors

4. **Update version number**
   - Bump version for release
   - Update CFBundleVersion
   - Update marketing version

5. **Create release notes**
   - Highlight SwiftUI migration
   - Note improved UI/UX
   - Document any breaking changes
   - List new features (if any)

6. **Merge preparation**
   - Squash/clean up commit history if desired
   - Write comprehensive merge commit message
   - Tag release

#### Acceptance Criteria
- [ ] UI is polished and consistent
- [ ] Code review complete
- [ ] CHANGELOG updated
- [ ] Version number bumped
- [ ] Release notes written
- [ ] Ready to merge to master

---

## Technical Considerations

### Deployment Target: macOS 14.0

**Why macOS 14.0?**
- Current target is macOS 13.0
- User wants n-2 support (macOS 14.0 from current macOS 16 in April 2026)
- macOS 14.0 provides:
  - `@Observable` macro (better than `ObservableObject`)
  - Inspector views
  - Improved `Form` and `Table` performance
  - Better SwiftUI stability

**Migration impact:**
- Some users on macOS 13.0 will need to upgrade
- Document in release notes
- Consider keeping macOS 13.0 on a maintenance branch if needed

### SwiftUI APIs to Use

**Layout:**
- `NavigationSplitView` — Three-column layout (sidebar, list, detail)
- `Form` — For modal views (Save, Upload)
- `Table` — For Apple Events list
- `List` — For executables list

**Components:**
- `Picker` — For permission dropdowns
- `TextField` / `SecureField` — For text input
- `Button` — For actions
- `Toggle` — For checkboxes
- `Popover` — For help buttons

**Modifiers:**
- `.sheet()` — For modal presentation
- `.alert()` — For error dialogs
- `.fileImporter()` / `.fileExporter()` — For file panels (or custom wrappers)
- `.keyboardShortcut()` — For shortcuts

**State Management:**
- `@Observable` (macOS 14+) — For view models
- `@State` — For local view state
- `@Binding` — For two-way bindings
- `@AppStorage` — For user defaults (already used in UploadInfoView)

### Integration with Existing Code

**Model Layer (no changes):**
- `Model.shared` with `@MainActor` isolation works perfectly with SwiftUI
- `Executable`, `AppleEventRule`, `TCCProfile` are value types (great for SwiftUI)
- Swift Concurrency already in place

**Networking (no changes):**
- `UploadManager`, `NetworkAuthManager`, `JamfProAPIClient` remain unchanged
- Already async/await based

**Security (no changes):**
- `SecurityWrapper`, `TCCProfileImporter` remain unchanged
- Can be called from SwiftUI views

**Only changes:** View layer (UI only)

### Design Philosophy

**Modern macOS Design:**
- Use native SwiftUI controls (don't mimic AppKit exactly)
- Embrace iOS/macOS design convergence where appropriate
- Use system colors, fonts, spacing
- Follow HIG (Human Interface Guidelines)
- Proper use of hierarchy (primary/secondary actions)
- Subtle animations for state changes

**Improvements over current UI:**
- Better visual hierarchy
- More breathing room (padding/spacing)
- Clearer grouping (cards, sections)
- Modern iconography
- Smooth animations
- Better empty states
- Improved error messaging

---

## Risk Mitigation

### Medium Risks
1. **Complex main view migration**
   - *Mitigation:* Break into two phases (read-only, then editing)
   - *Mitigation:* Extensive testing at each step

2. **Drag & drop functionality**
   - *Mitigation:* Test both `.fileImporter()` and custom NSViewRepresentable
   - *Mitigation:* Fallback to button-based adding if needed

3. **File panel integration**
   - *Mitigation:* Create reusable wrappers early
   - *Mitigation:* Test on all macOS versions

### Low Risks
4. **UI test compatibility**
   - *Mitigation:* UI tests are optional for now
   - *Mitigation:* Can be updated after main migration complete

5. **Performance**
   - *Mitigation:* SwiftUI is generally performant on macOS 14+
   - *Mitigation:* Profile with Instruments if issues arise

---

## Success Metrics

- [ ] 100% SwiftUI (no AppKit view code remaining)
- [ ] All features working (no regressions)
- [ ] All unit tests passing
- [ ] Modern, polished UI
- [ ] No performance degradation
- [ ] Positive user feedback on new design

---

## Timeline Estimate

| Phase | Effort | Days |
|-------|--------|------|
| Phase 1: Foundation | Small | 1-2 |
| Phase 2: Components | Small | 1 |
| Phase 3: Modals | Medium | 2-3 |
| Phase 4: Main View (Display) | Large | 4-5 |
| Phase 5: Main View (Editing) | Large | 4-5 |
| Phase 6: App Lifecycle | Medium | 2 |
| Phase 7: Cleanup | Small | 1-2 |
| Phase 8: Testing | Medium | 3-4 |
| Phase 9: Release Prep | Small | 1 |
| **Total** | | **19-29 days** |

*Note: Timeline assumes ~6 hours/day of focused development*

---

## Decision Log

### 2026-04-10: Migration Scope
**Decision:** Complete migration to SwiftUI (no hybrid approach)
**Rationale:** UploadInfoView is already SwiftUI, model layer uses Swift Concurrency, app is relatively simple. Full migration results in cleaner architecture and better maintainability.

### 2026-04-10: Deployment Target
**Decision:** Bump to macOS 14.0
**Rationale:** User wants n-2 support (14.0 from current 16.0). Provides `@Observable`, Inspector, and improved SwiftUI performance while maintaining broad compatibility.

### 2026-04-10: UI Design Approach
**Decision:** SwiftUI-native improvements (not pixel-perfect port)
**Rationale:** User wants fresh, modern design. Current UI is dated. SwiftUI patterns provide better UX and easier maintenance.

### 2026-04-10: UI Testing
**Decision:** Defer to optional final phase
**Rationale:** Not a blocker for migration. Can be updated after main work complete.

---

## Appendix

### Key Files to Migrate

**High Priority (Phase 3-5):**
- `TCCProfileViewController.swift` (~500 LOC) → `MainContentView.swift` + subviews
- `SaveViewController.swift` → `SaveView.swift`
- `OpenViewController.swift` → `OpenView.swift`

**Low Priority (Phase 2, 6):**
- `AppDelegate.swift` → `PPPCUtilityApp.swift`
- `InfoButton.swift` → `InfoButtonView.swift`
- `Alert.swift` → `AlertHelper.swift`
- `FlippedClipView.swift` → (delete, not needed)

**No Changes:**
- All files in `Model/`
- All files in `Networking/`
- All files in `TCCProfileImporter/`
- `SecurityWrapper.swift`
- All test files (except UI tests in Phase 8)

### Resources
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Observable Macro](https://developer.apple.com/documentation/observation)
- [Navigation Split View](https://developer.apple.com/documentation/swiftui/navigationsplitview)

---

**Last Updated:** 2026-04-10
