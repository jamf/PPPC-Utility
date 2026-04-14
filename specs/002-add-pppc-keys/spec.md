# Feature Specification: Add New PPPC Keys

**Feature Branch**: `002-add-pppc-keys`  
**Created**: 2026-04-09  
**Status**: Draft  
**Input**: User description: "Add 3 new PPPC keys (BluetoothAlways, SystemPolicyAppBundles, SystemPolicyAppData) to the PPPC Utility, as introduced in Jamf Pro 11.23.0 release notes."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Bluetooth Access Policy (Priority: P1)

An IT administrator needs to control which applications can access Bluetooth devices on managed Macs running macOS 14 or later. Using PPPC Utility, the administrator adds an application to the profile and sets the "Bluetooth Always" permission to Allow or Deny, then exports the configuration profile for deployment via Jamf Pro.

**Why this priority**: Bluetooth access is a significant privacy and security concern. Unauthorized Bluetooth access can expose device pairing data and enable unwanted wireless communication. This was the specific key the user requested.

**Independent Test**: Can be fully tested by adding an application in PPPC Utility, selecting a Bluetooth Always policy value, exporting the profile, and verifying the `BluetoothAlways` key appears in the exported payload with the correct authorization value.

**Acceptance Scenarios**:

1. **Given** the PPPC Utility is open and an application has been added, **When** the administrator selects a policy value for Bluetooth Always, **Then** the selected value (Allow/Deny) is stored and displayed in the policy table.
2. **Given** a profile with a Bluetooth Always policy set, **When** the administrator exports the profile, **Then** the exported configuration profile contains a `BluetoothAlways` key under the TCC services payload with the correct authorization value.
3. **Given** the administrator imports an existing profile that includes a `BluetoothAlways` key, **When** the profile loads, **Then** the Bluetooth Always policy value is correctly displayed in the UI.

---

### User Story 2 - Configure App Bundles Access Policy (Priority: P1)

An IT administrator needs to control which applications can update or delete other applications on managed Macs running macOS 13 or later. Using PPPC Utility, the administrator sets the "App Bundles" permission for a given application, then exports the profile for deployment.

**Why this priority**: Controlling which apps can modify other app bundles is a critical security concern — unauthorized modification of application bundles could introduce malware or compromise system integrity.

**Independent Test**: Can be fully tested by adding an application in PPPC Utility, selecting a policy value for App Bundles, exporting the profile, and verifying the `SystemPolicyAppBundles` key appears in the exported payload.

**Acceptance Scenarios**:

1. **Given** the PPPC Utility is open and an application has been added, **When** the administrator selects a policy value for App Bundles, **Then** the selected value is stored and displayed in the policy table.
2. **Given** a profile with an App Bundles policy set, **When** the administrator exports the profile, **Then** the exported configuration profile contains a `SystemPolicyAppBundles` key under the TCC services payload with the correct authorization value.
3. **Given** the administrator imports an existing profile that includes a `SystemPolicyAppBundles` key, **When** the profile loads, **Then** the App Bundles policy value is correctly displayed in the UI.

---

### User Story 3 - Configure App Data Access Policy (Priority: P1)

An IT administrator needs to control which applications can access the data of other applications on managed Macs running macOS 14 or later. Using PPPC Utility, the administrator sets the "App Data" permission for a given application, then exports the profile for deployment.

**Why this priority**: Controlling cross-application data access is essential for data privacy — without it, a compromised application could read sensitive data from other apps (e.g., password managers, financial tools).

**Independent Test**: Can be fully tested by adding an application in PPPC Utility, selecting a policy value for App Data, exporting the profile, and verifying the `SystemPolicyAppData` key appears in the exported payload.

**Acceptance Scenarios**:

1. **Given** the PPPC Utility is open and an application has been added, **When** the administrator selects a policy value for App Data, **Then** the selected value is stored and displayed in the policy table.
2. **Given** a profile with an App Data policy set, **When** the administrator exports the profile, **Then** the exported configuration profile contains a `SystemPolicyAppData` key under the TCC services payload with the correct authorization value.
3. **Given** the administrator imports an existing profile that includes a `SystemPolicyAppData` key, **When** the profile loads, **Then** the App Data policy value is correctly displayed in the UI.

---

### User Story 4 - Round-Trip Consistency (Priority: P2)

An IT administrator creates a profile with all three new PPPC keys configured, exports it, and then re-imports it. All three new service policies should be preserved exactly as configured.

**Why this priority**: Data integrity on export/import is fundamental to administrator trust in the tool, but this is a natural consequence of correct implementation of the individual keys.

**Independent Test**: Can be tested by creating a profile with all three new keys set, exporting to a file, re-importing the file, and comparing all policy values.

**Acceptance Scenarios**:

1. **Given** a profile with BluetoothAlways, SystemPolicyAppBundles, and SystemPolicyAppData policies set to specific values, **When** the profile is exported and then re-imported, **Then** all three policy values match the originally configured values.

---

### Edge Cases

- What happens when an existing profile created before these keys were added is imported? The three new service columns should default to "–" (not set) for those applications.
- What happens when a profile exported from another tool includes these keys with unexpected or unrecognized authorization values? The system should handle gracefully, applying known values and defaulting unknown values.
- What happens when the user sets a new key and then clears it back to the default? The key should not appear in the exported profile if set to the default/unset value.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST include "Bluetooth Always" as a configurable PPPC service with the MDM key `BluetoothAlways`.
- **FR-002**: The system MUST include "App Bundles" as a configurable PPPC service with the MDM key `SystemPolicyAppBundles`.
- **FR-003**: The system MUST include "App Data" as a configurable PPPC service with the MDM key `SystemPolicyAppData`.
- **FR-004**: Each new service MUST appear in the policy table as a selectable column alongside existing services.
- **FR-005**: Each new service MUST support Allow, Deny, and "not set" policy values. None of the three new keys are deny-only or support allowStandardUsers (confirmed via Apple MDM documentation).
- **FR-006**: Exported configuration profiles MUST include the correct MDM key and authorization value for each new service when a policy value has been set.
- **FR-007**: Imported configuration profiles containing any of the three new MDM keys MUST correctly parse and display the policy values in the UI.
- **FR-008**: The service description for each new key MUST accurately describe what the permission controls, consistent with Apple's MDM documentation.

### Testing Requirements

- **TR-001**: Unit tests MUST verify the services manager loads all services including the 3 new keys (expected count increases from 21 to 24).
- **TR-002**: Unit tests MUST verify that each new key's Policy property defaults to "–" (not set) on a new Executable.
- **TR-003**: Unit tests MUST verify export/import round-trip fidelity for each of the 3 new keys with both Allow and Deny authorization values.
- **TR-004**: A new `TestTCCUnsignedProfile.mobileconfig` fixture MUST be created in TCCProfileImporterTests/ containing all 24 services (21 existing + 3 new keys). The `TestTCCUnsignedProfile-allLower.mobileconfig` fixture MUST also be updated with the 3 new keys in lowercase. The `Resources/TestTCCUnsignedProfile.mobileconfig` (app-bundled UI test profile) MUST be updated with the 3 new keys.
- **TR-005**: The original `TestTCCUnsignedProfile.mobileconfig` fixture (without the new keys) MUST be preserved as `TestTCCUnsignedProfile-Legacy.mobileconfig` in TCCProfileImporterTests/. A test MUST verify that importing this legacy fixture defaults the 3 new service columns to "–" (not set) without errors.
- **TR-006**: One UI test MUST be added (or an existing test updated) to verify the total column count in the policy table has increased to reflect the 3 new services.

### Key Entities

- **PPPC Service (BluetoothAlways)**: Controls app access to Bluetooth devices. MDM key: `BluetoothAlways`. Description: Specifies the policies for the app to access Bluetooth devices.
- **PPPC Service (SystemPolicyAppBundles)**: Controls whether an app can update or delete other applications. MDM key: `SystemPolicyAppBundles`. Description: Allows the app to update or delete other apps.
- **PPPC Service (SystemPolicyAppData)**: Controls whether an app can access data belonging to other applications. MDM key: `SystemPolicyAppData`. Description: Specifies the policies for the app to access the data of other apps.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All three new PPPC services are visible and configurable in the PPPC Utility policy table without requiring any workaround by the administrator.
- **SC-002**: A configuration profile exported with any of the three new keys set produces a valid payload that Jamf Pro accepts and deploys successfully.
- **SC-003**: 100% round-trip fidelity — any profile created with the new keys, exported, and re-imported retains all configured values.
- **SC-004**: Existing profiles without the new keys import without errors or data loss; the new service columns default to "not set."

## Assumptions

- The three new keys follow the same TCC payload structure (`com.apple.TCC.configuration-profile-policy`) as existing PPPC services — no new payload types or structures are required.
- BluetoothAlways and SystemPolicyAppData require macOS 14 or later; SystemPolicyAppBundles requires macOS 13 or later. The PPPC Utility does not enforce minimum OS version per service (consistent with existing behavior).
- The existing service infrastructure (service registry, policy model, profile export/import) supports adding new services without architectural changes — only data additions are needed.
- None of the three new services are "deny only" or "allow standard users" — confirmed via Apple's official MDM documentation (the `AllowStandardUserToSetSystemService` authorization value is explicitly limited to `ListenEvent` and `ScreenCapture` only).
- The alphabetical or categorical ordering of services in the UI will incorporate the new services naturally based on existing sort logic.
