# macOS 27 — Annotate Deprecated PPPC Keys

**Status**: Ready to work · **Size**: Small · **Ships**: independently, before the declarative work

## Context

In the macOS 27 seed, Apple marked five keys in the classic PPPC payload
(`com.apple.TCC.configuration-profile-policy`) as **deprecated**. PPPC itself is *not*
going away — only these keys are affected, and only **Accessibility** actually loses
functionality (its ability to *grant* access; it can still deny). The rest of what this
tool manages (Full Disk Access, AppleEvents, ScreenCapture, file-access, etc.) is
unchanged in macOS 27.

Because PPPC-Utility generates profiles that may target older macOS too, the goal here
is to **annotate, not remove** — surface the deprecation and the forward path (the
declarative Privacy Management config) so admins understand what changed.

### Deprecated keys (Apple `device-management`, `seed_OS_27_0`)

`mdm/profiles/com.apple.TCC.configuration-profile-policy.yaml`, verbatim
`deprecated: '27.0'`:

| Key | Note |
|-----|------|
| `Camera` | Already deny-only in this app — no functional change. |
| `Microphone` | Already deny-only in this app — no functional change. |
| `Accessibility` | Lost **grant** ability as of macOS 26.2, removed in 27.0. Can still deny. → declarative `Privacy` |
| `SpeechRecognition` | → declarative `Privacy` in `com.apple.configuration.app.settings` |
| `BluetoothAlways` | → declarative `Privacy` in `com.apple.configuration.app.settings` |

## Work

### 1. Deprecation metadata in the service definition

- `Resources/PPPCServices.json` — add optional fields (e.g. `"deprecatedMacOS": "27.0"`
  and `"deprecationNote"`) to the five affected entries: `Camera`, `Microphone`,
  `Accessibility`, `SpeechRecognition`, `BluetoothAlways`.
- `Source/Model/PPPCServiceInfo.swift` — add matching optional properties
  (`deprecatedMacOS: String?`, `deprecationNote: String?`). Keep them optional so the
  other ~18 services decode unchanged. Fold the note into the existing `userHelp`
  computed property (append a "⚠️ Deprecated in macOS 27 — …" line).

### 2. Surface it in the UI help text

- `Source/View Controllers/TCCProfileViewController.swift` `setupDescriptions()`
  (~line 359+) already pulls `services.allServices["<key>"]?.userHelp` for each info
  button — once `userHelp` includes the deprecation note, the five buttons update
  automatically. No new outlets or layout work.

### 3. Accessibility Allow caveat (decision to record)

`Accessibility` currently sits in the `setupAllowDeny` group
(`TCCProfileViewController.swift:252-272`), offering Allow/Deny. In macOS 27 the Allow
value is ignored. **Leave the Allow option in place** — profiles may target macOS ≤26
where it still works — but cover it with the deprecation note from step 1. Do **not**
move it to the deny-only group; that would silently break older-OS profiles. Note this
in a code comment and CHANGELOG.

### 4. Docs

- `README.md` / `CHANGELOG.md` — short note on the macOS 27 deprecations and a pointer
  to the declarative Privacy Management follow-up.

## Files

- `Resources/PPPCServices.json`
- `Source/Model/PPPCServiceInfo.swift`
- `Source/View Controllers/TCCProfileViewController.swift`
- `README.md`, `CHANGELOG.md`

## Testing / verification

- Unit: extend `PPPCServicesManagerTests` / `ModelTests` to assert the five keys decode
  the new deprecation fields and that `userHelp` contains the note. Follow the Swift
  Testing conventions in CLAUDE.md (annotations above declarations, `// when` /
  `// then`, no snake_case names, parameterized test over the five keys).
- Manual: run the app, hover the five info buttons, confirm the deprecation note shows.
- Warning baseline: run the `xcodebuild clean build-for-testing … | grep warning:`
  command from CLAUDE.md before/after; no new warnings.

## Follow-up

See [macos-27-declarative-privacy-management.md](macos-27-declarative-privacy-management.md)
for the net-new declarative replacement.

## References

- `mdm/profiles/com.apple.TCC.configuration-profile-policy.yaml` (`seed_OS_27_0`) — deprecation notes
