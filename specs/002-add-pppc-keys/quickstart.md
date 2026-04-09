# Quickstart: Add New PPPC Keys

**Feature**: 002-add-pppc-keys
**Branch**: `002-add-pppc-keys`

## Overview

Add BluetoothAlways, SystemPolicyAppBundles, and SystemPolicyAppData to the PPPC Utility. All three are standard Allow/Deny services following the identical pattern as the existing 21 services.

## Implementation Order

### Layer 1: Data Model (no UI impact, enables all tests)

1. **PPPCServices.json** — Add 3 new service entries (alphabetical placement)
2. **TCCProfile.swift** — Add 3 new `ServicesKeys` enum cases
3. **Executable.swift** — Add 3 new `@objc dynamic` properties to `Policy`

### Layer 2: View Controller Wiring

4. **TCCProfileViewController.swift** — Add IBOutlet declarations (popup, array controller, help button, stack view)
5. **TCCProfileViewController.swift** — Add to `setupAllowDeny()`, `setupDescriptions()`, `setupStackViewsWithBackground()`, `setupAccessibilityIdentifiers()`

### Layer 3: Storyboard UI

6. **Main.storyboard** — Add popup buttons, labels, info buttons, stack views for each new service, wire IBOutlets and Cocoa Bindings

### Layer 4: Tests

7. **Unit tests** — Update service count, policy defaults, add export/import round-trip tests
8. **Test fixtures** — Update .mobileconfig files with new keys; preserve legacy fixture
9. **UI tests** — Add column count verification

## Key Files

| File | Change |
|------|--------|
| `Resources/PPPCServices.json` | +3 entries |
| `Source/Model/TCCProfile.swift` | +3 enum cases |
| `Source/Model/Executable.swift` | +3 properties |
| `Source/View Controllers/TCCProfileViewController.swift` | +IBOutlets, setup calls |
| `Resources/Base.lproj/Main.storyboard` | +UI elements |
| `PPPC UtilityTests/` | Updated assertions + new tests |
| `PPPC UtilityUITests/AppLaunchTests.swift` | +column count test |

## Build & Test

```bash
# Build
xcodebuild clean build -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS"

# Unit tests
xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" -testPlan "PPPC Utility"

# UI tests
xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" -testPlan "PPPC Utility UI Tests"

# Compiler warnings check
xcodebuild clean build-for-testing -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" 2>&1 | grep -i "warning:" | grep -v "xcodebuild: WARNING"
```

## Risks

- **Storyboard merge conflicts**: The Main.storyboard is XML and prone to merge conflicts. Minimize changes and commit storyboard changes atomically.
- **KVC property name mismatch**: If a Policy property name doesn't exactly match the MDM key, Cocoa Bindings will silently fail. Verify by testing the UI after binding.
