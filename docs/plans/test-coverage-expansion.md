# Test Coverage Expansion — Phased Plan

## Context

PPPC Utility has ~50 tests covering roughly 35–40% of production code. Coverage is strong for model import/export, profile serialization, token handling, and semantic versioning, but zero coverage exists for:
- Pure logic in `Executable`, `Policy`, `TCCPolicy`, `JamfProVersion`, and the `Array` extension
- HTTP response handling and error paths in `Networking`
- `JamfProAPIClient` endpoints beyond the OAuth request body
- The `UploadManager` connection-verification and upload workflow
- `TCCProfile.jamfProAPIData` XML structure

The goal is to close these gaps in four small, independently reviewable pull requests, progressing from zero-dependency unit tests up to component tests that mock only the network edge.

**Honest coverage estimate after all 4 phases: ~55–65%.** See "Remaining gaps" at the bottom.

---

## Phase 1 — Pure Unit Tests

**Branch:** `test/phase-1-unit-tests`
**No production code changes.**

### New files
| File | What it tests |
|------|---------------|
| `PPPC UtilityTests/ModelTests/ExecutableTests.swift` | `generateDisplayName` (bundle ID, path, single component); `generateIconPath` (path vs bundle); `Policy.allPolicyValues()` — 20 values, all default `"-"` |
| `PPPC UtilityTests/ModelTests/TCCPolicyTests.swift` | `identifierType` and `receiverIdentifierType` auto-detection in `TCCPolicy.init` |
| `PPPC UtilityTests/ExtensionTests/ArrayExtensionTests.swift` | `appendIfNew` — appends new, skips duplicate, works on empty array |
| `PPPC UtilityTests/NetworkingTests/JamfProVersionTests.swift` | `mainVersionInfo()` suffix stripping; `semantic()` component parsing; `init(fromHTMLString:)` success + nil/no tag/malformed failure cases |

### Key source under test
- `Source/Model/Executable.swift` — `generateDisplayName`, `generateIconPath`, `Policy.allPolicyValues`
- `Source/Model/TCCProfile.swift` — `TCCPolicy.init` identifier type detection
- `Source/Extensions/ArrayExtensions.swift` — `appendIfNew`
- `Source/Networking/JamfProAPITypes.swift` — `JamfProVersion` parsing

### Verification
```
xcodebuild test -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS"
```
All new test files build and pass. No new compiler warnings.

---

## Phase 2 — URLSession Injection + Mock Infrastructure

**Branch:** `test/phase-2-urlsession-injection`
**Production changes only — no new tests.**

### Production changes
| File | Change |
|------|--------|
| `Source/Networking/Networking.swift` | Add `session: URLSession = .shared` to `init`; replace all `URLSession.shared.data(for:)` call sites with `session.data(for:)` |
| `Source/Networking/JamfProAPIClient.swift` | Replace `URLSession.shared.data(for: simpleRequest)` in the HTML version fallback with `session.data(for: simpleRequest)` |
| `Source/Networking/UploadManager.swift` | Add `session: URLSession = .shared` to `init`; pass `session` when constructing `JamfProAPIClient` (2 call sites) |

### New test helper
| File | What it provides |
|------|-----------------|
| `PPPC UtilityTests/Helpers/MockURLProtocol.swift` | `MockURLProtocol: URLProtocol` with static `requestHandler`; `URLSession.mock(handler:)` factory method; `HTTPURLResponse.ok(url:)` and `.status(_:url:)` convenience helpers |

### Verification
Build succeeds, all existing 50 tests still pass, no new warnings. No behavioral change — `URLSession.shared` remains the default for all production paths.

---

## Phase 3 — Networking & JamfProAPIClient Tests

**Branch:** `test/phase-3-networking-tests`
**Depends on Phase 2.**

### New / expanded files
| File | What it tests |
|------|---------------|
| `PPPC UtilityTests/NetworkingTests/NetworkingTests.swift` | `url(forEndpoint:)` URL construction; `badServerUrl` error on invalid URL; `loadPreAuthorized` — 401 → `invalidUsernamePassword`, 500 → `serverResponse(500)`, 200 → decodes value; `loadBearerAuthorized` — 401 triggers refresh and retry, second 401 → `invalidToken`; `sendBearerAuthorized` / `sendBasicAuthorized` response handling |
| `PPPC UtilityTests/NetworkingTests/JamfProAPIClientTests.swift` | Expand existing suite: `getJamfProVersion` JSON path; `getJamfProVersion` HTML fallback when API returns 404; `getOrganizationName` JSON decoding; `getBearerToken` basic auth path; `getBearerToken` client credentials path; `load()` bearer→basic fallback when token endpoint returns 404 |

### Key source under test
- `Source/Networking/Networking.swift` — `url(forEndpoint:)`, `loadPreAuthorized`, `loadBearerAuthorized`, `sendBearerAuthorized`, `sendBasicAuthorized`
- `Source/Networking/JamfProAPIClient.swift` — `getJamfProVersion`, `getOrganizationName`, `getBearerToken`, `load()`

### Verification
Run tests. All new tests pass with no real network calls.

---

## Phase 4 — UploadManager & TCCProfile XML Tests

**Branch:** `test/phase-4-component-tests`
**Depends on Phase 2.**

### New / expanded files
| File | What it tests |
|------|---------------|
| `PPPC UtilityTests/NetworkingTests/UploadManagerTests.swift` | `verifyConnection`: version ≥ 10.7.1 → `mustSign=false`; version < 10.7.1 → `mustSign=true`; 401 → `anyError("Invalid credentials.")`; 500 → `anyError("Jamf Pro server is unavailable.")`; `upload`: no site → no `<site>` in XML; with site → correct `<site><id>…</id><name>…</name></site>` block |
| `PPPC UtilityTests/TCCProfileImporterTests/TCCProfileTests.swift` | Expand existing suite: `jamfProAPIData(site: nil)` has no `<site>`; `jamfProAPIData(site:)` has correct site block; `<general>`, `<payloads>`, `<name>`, `<description>` all present |

### Key source under test
- `Source/Networking/UploadManager.swift` — `verifyConnection`, `upload`
- `Source/Model/TCCProfile.swift` — `jamfProAPIData`

### MockURLProtocol dispatch pattern for UploadManager tests
```swift
MockURLProtocol.requestHandler = { request in
    let path = request.url?.path ?? ""
    if path.hasSuffix("auth/token")               { return (tokenResponse, tokenJSON) }
    if path.contains("jamf-pro-version")           { return (ok, versionJSON) }
    if path.contains("activationcode")             { return (ok, orgJSON) }
    if path.hasSuffix("osxconfigurationprofiles")  { capturedBody = request.httpBody; return (ok, Data()) }
    throw URLError(.badURL)
}
```

### Verification
Run tests. All new tests pass with no real network or Security framework calls.

---

## Files touched across all phases

```
Source/Networking/Networking.swift                              (Phase 2)
Source/Networking/JamfProAPIClient.swift                        (Phase 2)
Source/Networking/UploadManager.swift                           (Phase 2)
PPPC UtilityTests/Helpers/MockURLProtocol.swift                 (Phase 2, new)
PPPC UtilityTests/ModelTests/ExecutableTests.swift              (Phase 1, new)
PPPC UtilityTests/ModelTests/TCCPolicyTests.swift               (Phase 1, new)
PPPC UtilityTests/ExtensionTests/ArrayExtensionTests.swift      (Phase 1, new)
PPPC UtilityTests/NetworkingTests/JamfProVersionTests.swift     (Phase 1, new)
PPPC UtilityTests/NetworkingTests/NetworkingTests.swift         (Phase 3, new)
PPPC UtilityTests/NetworkingTests/JamfProAPIClientTests.swift   (Phase 3, expand)
PPPC UtilityTests/NetworkingTests/UploadManagerTests.swift      (Phase 4, new)
PPPC UtilityTests/TCCProfileImporterTests/TCCProfileTests.swift (Phase 4, expand)
```

---

## Remaining gaps after all 4 phases (~35–45% uncovered)

### Doable with more test work
- `NetworkAuthManager` concurrent refresh de-duplication (`if let task = refreshTask` path)
- `Model.fallbackIconPath` switch (`.app`, `.bundle`/`.xpc`, unknown extension)
- `LoadExecutableError` / `TCCProfileImportError` localized descriptions

### Hard without Security framework mocking
- `SecurityWrapper` (entire file) — keychain CRUD, CMS signing, `copyDesignatedRequirement`, `loadSigningIdentities`
- `Model.loadExecutable(url:)` — calls `SecurityWrapper.copyDesignatedRequirement`
- `Model.getAppleEventChoices()` — loads real system apps from disk

### Impractical for unit tests
- View controllers (`TCCProfileViewController`, `SaveViewController`, `OpenViewController`) — AppKit bindings and file panels
- `UploadInfoView` — SwiftUI UI layer
