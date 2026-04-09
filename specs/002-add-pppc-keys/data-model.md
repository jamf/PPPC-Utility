# Data Model: Add New PPPC Keys

**Feature**: 002-add-pppc-keys
**Date**: 2026-04-09

## Entities

### PPPCServiceInfo (existing — 3 new instances)

Represents a single PPPC service definition loaded from `PPPCServices.json`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| mdmKey | String | Yes | MDM payload key (e.g., "BluetoothAlways") |
| englishName | String | Yes | Human-readable display name |
| englishDescription | String | Yes | Service description for help text |
| entitlements | [String]? | No | Related Apple entitlements (nil for these 3 keys) |
| denyOnly | Bool? | No | If true, only Deny is available (nil/false for these 3 keys) |
| allowStandardUsers | Bool? | No | If true, standard users can approve (nil/false for these 3 keys) |

**New instances**:

```json
{
    "mdmKey": "BluetoothAlways",
    "englishName": "Bluetooth Always",
    "englishDescription": "Specifies the policies for the app to access Bluetooth devices."
}
```

```json
{
    "mdmKey": "SystemPolicyAppBundles",
    "englishName": "App Bundles",
    "englishDescription": "Allows the app to update or delete other apps."
}
```

```json
{
    "mdmKey": "SystemPolicyAppData",
    "englishName": "App Data",
    "englishDescription": "Specifies the policies for the app to access the data of other apps."
}
```

### ServicesKeys Enum (existing — 3 new cases)

Maps human-readable case names to MDM key strings. Used for programmatic service identification.

| Case | Raw Value |
|------|-----------|
| bluetoothAlways | "BluetoothAlways" |
| appBundles | "SystemPolicyAppBundles" |
| appData | "SystemPolicyAppData" |

### Policy Class (existing — 3 new properties)

KVC-bound properties for Cocoa Bindings. Each property name must exactly match the MDM key.

| Property | Type | Default | KVC Binding |
|----------|------|---------|-------------|
| BluetoothAlways | String | "-" | Bound to popup via NSArrayController |
| SystemPolicyAppBundles | String | "-" | Bound to popup via NSArrayController |
| SystemPolicyAppData | String | "-" | Bound to popup via NSArrayController |

## Relationships

```
PPPCServices.json → PPPCServicesManager.allServices[mdmKey]
                         ↓
ServicesKeys.rawValue == mdmKey == Policy.propertyName
                         ↓
TCCProfile.Content.services[mdmKey] → [TCCPolicy]
                         ↓
Main.storyboard popup ← Cocoa Binding → Policy.{mdmKey}
```

## State Transitions

Policy values follow the existing state model:

```
"-" (not set) → "Allow" | "Deny"
"Allow"       → "-" | "Deny"
"Deny"        → "-" | "Allow"
```

No state persistence beyond the in-memory model and exported profile file.

## Validation Rules

- `mdmKey` must be unique across all services in `PPPCServices.json`.
- Policy property names must exactly match `mdmKey` values (KVC requirement).
- `ServicesKeys` enum raw values must exactly match `mdmKey` values.
- Exported profiles must only include services where the policy value is not "-".
