# macOS 27 — Declarative Privacy Management Generation

**Status**: Future / net-new · **Size**: Large · **Depends on**: nothing, but naturally
follows [macos-27-annotate-deprecated-keys.md](macos-27-annotate-deprecated-keys.md)

## Context

macOS 27's replacement for the deprecated PPPC privacy keys is the declarative
`com.apple.configuration.app.settings` config, with a `Privacy → PermissionDefaults`
block. It is **additive** — it sets a first-launch consent default (one consolidated
prompt), it does **not** enforce — and it ships on the **user channel**, so it requires
an MDM-capable / supervised user. Only AppKit apps on macOS support it.

This is genuinely net-new for the codebase: there is **no** declarative-config concept
today (a grep for `declarative` / `com.apple.configuration` finds nothing in product
code). The entire app is built around the single
`com.apple.TCC.configuration-profile-policy` payload. Treat this as its own feature.

### Replacement schema (Apple `device-management`, `seed_OS_27_0`)

`declarative/declarations/configurations/app.settings.yaml` — introduced 27.0, macOS
**user** scope, supervised. `Payload → Privacy → PermissionDefaults` is a dict keyed by
app composed-identifier. Each app entry:

- `OrganizationJustification` (required string, shown in the consent prompt)
- Optional per-permission strings: `Accessibility` (`None`|`Allow`), `Bluetooth`,
  `Camera`, `Dictation`, `LocalNetwork`, `Microphone` (all `None`|`Allow`),
  `Location` (`None`|`WhileUsing`|`Always`), `LocationAccuracy`
  (`None`|`Approximate`|`Precise`; macOS n/a).

macOS composed-identifier formats: `"Bundle-ID"`, `"Bundle-ID (Team-ID)"`, or
`"Bundle-ID {Designated-Requirement}"`.

## Work

### 1. Model — new declaration type

New file `Source/Model/AppSettingsDeclaration.swift`, mirroring `TCCProfile.swift`
conventions (Codable, `CodingKeys` mapping to Apple's PascalCase keys, a JSON `Data`
serializer — declarations are **JSON**, not plist; see the examples under
`examples/declarative/declarations/configurations/app.settings/`):

- `Type = "com.apple.configuration.app.settings"`, `Identifier`, `ServerToken`.
- `Payload.Privacy.PermissionDefaults: [String: AppPrivacyDefaults]` keyed by composed
  identifier.
- `AppPrivacyDefaults`: `OrganizationJustification` + optional permission enums
  (`Accessibility`, `Bluetooth`, `Camera`, `Dictation`, `LocalNetwork`, `Microphone`,
  `Location`, `LocationAccuracy`) with the exact rangelist values above. String-backed
  enums to match Apple's `None` / `Allow` / `WhileUsing` / etc.

### 2. Reuse existing executable / identifier plumbing

- The composed-identifier formats map cleanly onto the app's existing `Executable`
  (bundle id + code requirement). Reuse `Executable` / `Model.selectedExecutables` to
  populate `PermissionDefaults` keys rather than building a new picker.

### 3. UI

- Add a Privacy-Management editor (new tab/section). The app is storyboard-driven
  AppKit, but prefer a **SwiftUI** view hosted via `NSHostingController` (the project
  already imports SwiftUI in `TCCProfileViewController.swift`) — a dynamic key/value
  list fits SwiftUI far better than more hardcoded IBOutlets.
- Per-app row: composed-identifier + required justification + the permission popups
  (macOS-supported subset only: Accessibility, Bluetooth, Camera, Dictation,
  LocalNetwork, Location, Microphone — omit `LocationAccuracy`, macOS n/a).
- Clearly label the **user-channel / supervised** requirement and "AppKit apps only"
  caveat in the UI.

### 4. Export / save

- `SaveViewController.swift` and `UploadManager.swift` currently assume a signed
  `.mobileconfig` PPPC profile. Declarations are distinct artifacts (JSON, delivered via
  DDM). At minimum, export the declaration JSON to disk. Jamf Pro upload of DDM
  declarations is a separate API and is **out of scope** for the first cut —
  export-to-file only, note the limitation in the UI.

## Files

- `Source/Model/AppSettingsDeclaration.swift` *(new)*
- New SwiftUI Privacy-Management editor + `NSHostingController` wiring
- `Source/View Controllers/SaveViewController.swift`

## Testing / verification

- Unit: round-trip encode `AppSettingsDeclaration` and compare against Apple's
  `example1.json` / `example2.json` (from the `seed_OS_27_0` device-management repo) as
  golden fixtures, mirroring the `TCCProfileTests` `xmlData()` assertions.
- Validate composed-identifier formatting for all three forms.
- Manual: generate a declaration, verify the JSON matches Apple's schema; confirm the
  user-channel / AppKit caveats render in the UI.

## Open questions

- Delivery target for declarations (export-only vs. Jamf Pro DDM API upload).
- Whether to unify PPPC + declaration authoring in one document or keep them separate.

## References

- `declarative/declarations/configurations/app.settings.yaml` (`seed_OS_27_0`) — schema
- `examples/declarative/declarations/configurations/app.settings/example1.json`, `example2.json`
