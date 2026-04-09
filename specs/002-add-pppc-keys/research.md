# Research: Add New PPPC Keys

**Feature**: 002-add-pppc-keys
**Date**: 2026-04-09

## Status: Complete — No Unknowns

All technical details were resolved during the specification and clarification phases. No NEEDS CLARIFICATION items existed in the Technical Context.

## Research Findings

### 1. Apple MDM Key Definitions

**Source**: Apple Developer Documentation — `PrivacyPreferencesPolicyControl.Services` (official JSON API)

| Key | Description | Introduced | Deny-Only | AllowStandardUsers |
|-----|-------------|------------|-----------|-------------------|
| BluetoothAlways | Specifies the policies for the app to access Bluetooth devices. | macOS 10.14 (MDM schema), macOS 14 (Jamf Pro support) | No | No |
| SystemPolicyAppBundles | Allows the application to update or delete other apps. Available in macOS 13 and later. | macOS 10.14 (MDM schema), macOS 13 (OS support) | No | No |
| SystemPolicyAppData | Specifies the policies for the app to access the data of other apps. | macOS 10.14 (MDM schema), macOS 14 (Jamf Pro support) | No | No |

- **Decision**: All three are standard Allow/Deny services.
- **Rationale**: Apple's MDM documentation does not include deny-only language for any of the three keys. `AllowStandardUserToSetSystemService` is explicitly restricted to `ListenEvent` and `ScreenCapture` only.
- **Alternatives considered**: None — Apple's documentation is authoritative.

### 2. Service Registration Pattern

**Source**: Codebase exploration of existing 21 services.

- **Decision**: Follow the existing pattern — JSON registry + enum + KVC property + storyboard UI.
- **Rationale**: All 21 existing services follow this exact pattern. No architectural changes needed.
- **Alternatives considered**: Dynamic column generation (rejected — would require rewriting the storyboard-based UI and Cocoa Bindings, violating Simplicity principle).

### 3. Entitlements

**Source**: Apple MDM documentation (Services schema).

- **Decision**: None of the three new keys specify associated entitlements in Apple's documentation.
- **Rationale**: The `entitlements` field in `PPPCServiceInfo` is optional. Services without entitlements (e.g., Accessibility, PostEvent, Reminders) simply omit the field.
- **Alternatives considered**: N/A.

### 4. English Names for Display

**Source**: Apple support documentation + Jamf Pro release notes.

| MDM Key | English Name (for UI) |
|---------|-----------------------|
| BluetoothAlways | Bluetooth Always |
| SystemPolicyAppBundles | App Bundles |
| SystemPolicyAppData | App Data |

- **Decision**: Use concise names consistent with the naming pattern of existing services (e.g., "Full Disk Access" for SystemPolicyAllFiles, "Administrator Files" for SystemPolicySysAdminFiles).
- **Rationale**: Names should be recognizable to IT administrators familiar with macOS TCC terminology.
- **Alternatives considered**: "Bluetooth" (too generic, could confuse with future keys), "Application Bundles" / "Application Data" (longer than necessary).
