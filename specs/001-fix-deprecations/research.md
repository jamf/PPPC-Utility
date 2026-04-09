# Research: Fix Deprecation Warnings

## Deprecation Inventory

### Baseline warning count

Captured with:
```
xcodebuild clean build-for-testing -project "PPPC Utility.xcodeproj" \
  -scheme "PPPC Utility" -destination "platform=macOS" 2>&1 \
  | grep -i "warning:" | grep -v "xcodebuild: WARNING"
```

**10 warnings across 4 files** (see breakdown below).

---

## Deprecated API 1: `NSSavePanel/NSOpenPanel.allowedFileTypes`

**Deprecated in**: macOS 12.0
**Replacement**: `allowedContentTypes: [UTType]`
**Framework required**: `import UniformTypeIdentifiers`

### Affected sites

| File | Line | Current code | Replacement |
|------|------|-------------|-------------|
| `TCCProfileConfigurationPanel.swift` | 40 | `openPanel.allowedFileTypes = ["mobileconfig", "plist"]` | `openPanel.allowedContentTypes = [UTType(filenameExtension: "mobileconfig")!, .propertyList]` |
| `TCCProfileViewController.swift` | 204 | `panel.allowedFileTypes = [kUTTypeBundle, kUTTypeUnixExecutable] as [String]` | `panel.allowedContentTypes = [.bundle, .unixExecutable]` |
| `OpenViewController.swift` | 69 | `panel.allowedFileTypes = [kUTTypeBundle, kUTTypeUnixExecutable] as [String]` | `panel.allowedContentTypes = [.bundle, .unixExecutable]` |
| `SaveViewController.swift` | 80 | `panel.allowedFileTypes = ["mobileconfig"]` | `panel.allowedContentTypes = [UTType(filenameExtension: "mobileconfig")!]` |

**Decision**: Use `UTType(filenameExtension:)` for `mobileconfig`. This returns
an optional, but force-unwrapping is safe here: `mobileconfig` is a registered
Apple type (`com.apple.mobileconfig`) present on every supported OS version.
Using a force-unwrap keeps the call site minimal and matches how Apple's own
sample code handles known registered types.

**Rationale**: `allowedContentTypes` is the current API. `allowedFileTypes` was
a string-based extension filter that predates the `UniformTypeIdentifiers`
framework. The replacement is a direct substitution with no behaviour change.

---

## Deprecated API 2: `kUTTypeBundle` / `kUTTypeUnixExecutable` (CoreServices)

**Deprecated in**: macOS 12.0 (string constants from `MobileCoreServices`;
superseded by `UniformTypeIdentifiers`)
**Replacement**:
- `kUTTypeBundle` → `UTType.bundle` (for `[UTType]` contexts)
- `kUTTypeBundle` → `UTType.bundle.identifier` (for `[String]` / `[Any]`
  contexts such as `NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes`)
- `kUTTypeUnixExecutable` → `UTType.unixExecutable`
- `kUTTypeUnixExecutable` → `UTType.unixExecutable.identifier`

**Framework required**: `import UniformTypeIdentifiers`

### Affected sites

| File | Line | Context | Current code | Replacement |
|------|------|---------|-------------|-------------|
| `TCCProfileViewController.swift` | 204 | `allowedContentTypes` | `[kUTTypeBundle, kUTTypeUnixExecutable] as [String]` | `[.bundle, .unixExecutable]` |
| `TCCProfileViewController.swift` | 232 | `pasteboardOptions` dict | `[kUTTypeBundle, kUTTypeUnixExecutable]` | `[UTType.bundle.identifier, UTType.unixExecutable.identifier]` |
| `OpenViewController.swift` | 69 | `allowedContentTypes` | `[kUTTypeBundle, kUTTypeUnixExecutable] as [String]` | `[.bundle, .unixExecutable]` |

**Decision**: Two different call sites require different types:
1. `allowedContentTypes` takes `[UTType]` → use `UTType.bundle`, `UTType.unixExecutable`
2. `urlReadingContentsConformToTypes` in the `NSPasteboard.ReadingOptionKey`
   dictionary takes `[String]` (UTI identifiers) → use `.identifier` property

**Rationale**: Both `UTType.bundle` and `UTType.unixExecutable` are standard
static properties on `UTType` (available macOS 11.0+), well within the macOS
13.0 deployment target.

**Alternatives considered**:
- `UTType(exportedAs:)` or `UTType(importedAs:)` — rejected; those are for
  declaring new types, not referencing existing ones.
- String literals for `.identifier` values (`"com.apple.bundle"`, etc.) —
  rejected; type-safe static properties are preferable.

---

## Non-Deprecation Warning: KVO concurrency in `SaveViewController`

**Warning category**: Swift concurrency (main actor isolation), not a
deprecation warning. Included here because it appears in the same warning
baseline.

**Warning**: `saveProfileKVOContext` (a `static var` with implicit `@MainActor`
isolation) is accessed via `inout` in the `nonisolated` `observeValue` method.

**Affected site**:

| File | Line | Issue |
|------|------|-------|
| `SaveViewController.swift` | 127 | `context == &SaveViewController.saveProfileKVOContext` in `nonisolated` method |

**Decision**: Add `nonisolated(unsafe)` to the static variable declaration:
```swift
nonisolated(unsafe) private static var saveProfileKVOContext = 0
```

**Rationale**: The variable is used purely as a KVO context pointer — an opaque
integer whose value never changes after initialization. It is safe to access
from a nonisolated context. `nonisolated(unsafe)` is the standard annotation
for this pattern. The alternative — rewriting to use `NSKeyValueObservation`
with `observe(_:options:changeHandler:)` — would be a more substantial
restructuring that exceeds the scope of this maintenance task (Simplicity
principle).

**Alternatives considered**:
- Modern `observe(_:options:changeHandler:)` KVO — rejected; out of scope,
  restructuring beyond replacing a deprecated call.
- `Task { @MainActor in ... }` in the `observeValue` body — already present via
  `MainActor.assumeIsolated`; does not remove the `inout` access warning.
