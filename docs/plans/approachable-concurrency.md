# Approachable Concurrency — Implementation Plan

**Issue:** https://github.com/jamf/PPPC-Utility/issues/141

## Problem

PPPC Utility is on Swift 5.0 with zero concurrency checking. The goal is to adopt Swift 6.2 Approachable Concurrency so MainActor isolation is inferred by the compiler rather than manually annotated.

## Approach

**"Turn it on and see what breaks"** — enable Approachable Concurrency build settings first, then use compiler diagnostics to guide incremental fixes.

## PR/Stage Boundaries

**Every stage produces a buildable, functional app.** The build settings from Stage 1 are already applied and the app builds + tests pass with only warnings. Each subsequent stage resolves warnings and modernizes patterns — none are required for the app to function.

| PR | Stage | Status | Description |
|----|-------|--------|-------------|
| 1 | Stage 1 | ✅ Done | Enable Approachable Concurrency build settings |
| 2 | Stage 2 | Pending | Remove `NetworkAuthManager` actor → class |
| 3a | Stage 3a | Pending | Remove 3 `DispatchQueue.main.async` wrappers |
| 3b | Stage 3b | Pending | Convert `UploadManager` to async throws |
| 3c | Stage 3c | Pending | Convert `Model.loadExecutable` to direct return |
| 3d | Stage 3d | Pending | Convert `TCCProfileImporter` to direct return |
| 4 | Stage 4 | Pending | Add `@concurrent` for background I/O |
| 5 | Stage 5 | Pending | Enable Swift 6 language mode (warnings → errors) |

PRs 3a–3d can be one PR or individual PRs — each is independently functional. PR 4 depends on PR 3c. PR 5 depends on all prior stages.

## Stage 1: Enable Approachable Concurrency Build Settings ✅

Add to both app and test targets (Debug + Release):
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_STRICT_CONCURRENCY = complete`
- Keep `SWIFT_VERSION = 5.0`

Build, capture all warnings/errors, categorize them.

## Stage 1 Results: Compiler Diagnostics (reference)

Build + tests PASSED with only warnings. 2 concurrency warning categories found:
1. `Token.isValid` cross-isolation (actor ↔ MainActor)
2. XCTestCase/NSObject override isolation mismatch (all test classes + SaveViewController)

---

## Stage 2: Remove the `NetworkAuthManager` actor → class

**Goal:** With `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, all types are MainActor by default. The `NetworkAuthManager` actor's synchronization purpose (single-flight token refresh) is now provided by MainActor serialization. Convert it to a regular class.

### Changes:

**`Source/Networking/NetworkAuthManager.swift`**
- `actor NetworkAuthManager` → `class NetworkAuthManager`
- `bearerAuthSupported()` — drop `async`, it was only async for actor isolation. Return type stays `Bool`.
- `nonisolated func basicAuthString()` → `func basicAuthString()` — no longer an actor, `nonisolated` is unnecessary
- `validToken(networking:)` — stays `async throws` (does async work internally)
- `refreshToken(networking:)` — stays `async throws` (does async work internally)
- The `Task { }` inside `refreshToken` inherits MainActor isolation under Approachable Concurrency, so mutations to `refreshTask`, `currentToken`, `supportsBearerAuth` remain safe

**`Source/Networking/JamfProAPIClient.swift`**
- `await authManager.bearerAuthSupported()` → `authManager.bearerAuthSupported()` (2 locations, lines ~80, ~101) — drop `await` since no longer async

**`Source/Networking/Networking.swift`**
- No changes needed — `authManager` property is `let`, and all calls to async methods already use `await`

**`Source/SwiftUI/UploadInfoView.swift`**
- `makeAuthManager()` — no changes, just returns the new class instead of actor

**`PPPC UtilityTests/NetworkingTests/NetworkAuthManagerTests.swift`**
- `await authManager.bearerAuthSupported()` → `authManager.bearerAuthSupported()` (2 locations, lines ~91, ~104) — drop `await`
- Tests that are `async throws` stay that way (they still `await` async methods like `validToken`)

**Side effect:** Resolves the `Token.isValid` cross-isolation warning because `Token` and `NetworkAuthManager` are now both on MainActor — no isolation boundary to cross.

---

## Stage 3: Remove `DispatchQueue.main.async` and convert `Task{}` + completion handlers to async

**Goal:** With everything MainActor-isolated, manual dispatch to the main thread is redundant. Also, replace `Task{}` + completion handler patterns with direct async methods — callers can just `await`.

### 3a. Remove `DispatchQueue.main.async` wrappers (3 simple locations)

**1. `Source/Views/Alert.swift:32`** — `display(header:message:)`
- Remove `DispatchQueue.main.async { ... }` wrapper, keep the body inline
- `Alert` is MainActor by default, so `display()` is already on MainActor

**2. `Source/View Controllers/OpenViewController.swift:51`** — `tableView(_:selectionIndexesForProposedSelection:)`
- Remove `DispatchQueue.main.async { ... }` wrapper, keep the body inline
- NSTableViewDelegate method called on MainActor

**3. `Source/View Controllers/SaveViewController.swift:87`** — `savePressed(_:)` panel callback
- Remove `DispatchQueue.main.async { ... }` wrapper, keep `self.saveTo(url: panel.url!)`
- NSSavePanel.begin completion runs on main thread; SaveViewController is MainActor

### 3b. Convert `UploadManager` from Task/completion to async (larger refactor)

**Current pattern** — both methods use `Task{}` internally + call a `completionHandler`:
- `verifyConnection(authManager:completionHandler:)` — wraps async networking in `Task{}`, calls back via completion
- `upload(profile:authMgr:siteInfo:signingIdentity:completionHandler:)` — same pattern + `DispatchQueue.main.async` before callback

**New pattern** — make both methods `async throws` directly:
- `func verifyConnection(authManager:) async throws -> VerificationInfo` — no Task, no completion handler, just returns
- `func upload(profile:authMgr:siteInfo:signingIdentity:) async throws` — no Task, no completion handler, throws on error

**Caller update** — `UploadInfoView.swift`:
- `verifyConnection()` — currently synchronous, calls `uploadMgr.verifyConnection(...) { result in }`. Refactor to:
  ```swift
  func verifyConnection() async { ... let info = try await uploadMgr.verifyConnection(...) }
  ```
  Button action becomes: `Task { await verifyConnection() }`
  Note: This is the one place a `Task{}` remains necessary — bridging from SwiftUI button action to async. This is the idiomatic pattern.
- `performUpload()` — same pattern as above

### 3c. Convert `Model.loadExecutable` from completion handler to direct return

**Current:** `func loadExecutable(url:completion: @escaping LoadExecutableCompletion)` — synchronous with completion handler callback. This is not actually async work — it reads bundle info and code requirements synchronously.

**New:** `func loadExecutable(url: URL) throws -> Executable` — direct return, throws on error. No completion handler needed since the work is synchronous.

**Callers to update:**
- `Model.getAppleEventChoices(executable:)` — currently calls `loadExecutable(url:) { result in ... }` 3 times, switch on result. Simplify to `try loadExecutable(url:)` with do/catch.
- `Model.findExecutableOnComputerUsing(bundleIdentifier:completion:)` → `func findExecutable(bundleIdentifier:) throws -> Executable` — direct return
- `Model.getExecutableFrom(identifier:codeRequirement:)` — currently calls `findExecutableOnComputerUsing`. Update to use new direct call.
- `Model.getExecutablesFromAllPolicies(policies:)` — calls `getExecutableFrom`. Update.
- `TCCProfileViewController.promptForExecutables(_:)` — calls `model.loadExecutable(url:)`. Update to direct call.
- `TCCProfileViewController.tableView(_:acceptDrop:row:dropOperation:)` — calls `model.loadExecutable(url:)`. Update.
- `OpenViewController.prompt(_:)` — calls `Model.shared.loadExecutable(url:)`. Update.

### 3d. Convert `TCCProfileImporter` from completion handler to direct return

**Current:**
- `decodeTCCProfile(data:completion:)` — synchronous decode with completion callback
- `decodeTCCProfile(fileUrl:completion:)` — synchronous file read + decode with completion callback

**New:**
- `func decodeTCCProfile(data: Data) throws -> TCCProfile` — direct return
- `func decodeTCCProfile(fileUrl: URL) throws -> TCCProfile` — direct return
- Remove `TCCProfileImportCompletion` typealias (no longer needed)

**Caller update:**
- `TCCProfileConfigurationPanel.loadTCCProfileFromFile(importer:window:completion:)` — update to use direct calls inside the panel callback
- `TCCProfileViewController.importProfile(_:)` — update to use new direct return

---

## Stage 4: Identify and annotate `@concurrent` for background work

**Goal:** Find synchronous work that runs on MainActor and could block the UI. Mark it `@concurrent` to run on the cooperative thread pool.

### Candidates analysis:

**Networking layer (`Networking`, `JamfProAPIClient`)**
- `URLSession.shared.data(for:)` is an Apple async API — it suspends, doesn't block MainActor ✅
- JSON decoding after `await` runs synchronously on MainActor — payloads are tiny ✅
- **No `@concurrent` needed** for networking methods

**`SecurityWrapper` (static methods)**
- `sign(data:using:)` — CMS signing could be slow for large profiles → **candidate for `@concurrent`**
- `copyDesignatedRequirement(url:)` — reads code signatures from disk → **candidate for `@concurrent`**
- `loadSigningIdentities()` — queries keychain for all identities → **candidate for `@concurrent`**
- `loadCredentials()` / `saveCredentials()` / `removeCredentials()` — keychain ops, typically fast → **possible candidate**

**`Model.loadExecutable(url:)` (after Stage 3c refactor)**
- Reads bundle info from disk + calls `SecurityWrapper.copyDesignatedRequirement` → **candidate for `@concurrent`**
- After Stage 3c this is `throws -> Executable`. Making it `@concurrent async throws -> Executable` would move disk I/O off MainActor.
- Callers (`getAppleEventChoices`, `importProfile`, `promptForExecutables`, drag-drop handler) would need to `await`.

**`TCCProfile.xmlData()` / `TCCProfile.jamfProAPIData()`**
- PropertyListEncoder/XML encoding — fast for typical profile sizes → **likely not needed**

### Recommended `@concurrent` annotations:
1. `SecurityWrapper.copyDesignatedRequirement(url:)` → `@concurrent static func ... async throws`
2. `SecurityWrapper.sign(data:using:)` → `@concurrent static func ... async throws`
3. `SecurityWrapper.loadSigningIdentities()` → `@concurrent static func ... async throws`
4. `Model.loadExecutable(url:)` → `@concurrent func ... async throws -> Executable` (since it calls copyDesignatedRequirement)
5. All callers of the above need `await`
6. `Model.getAppleEventChoices` → `async` (calls loadExecutable), callers update
7. `Model.importProfile` → calls `getExecutableFrom` which calls `loadExecutable` — cascade of async

### Note on remaining `Task{}` usage after all stages:
The only `Task{}` calls that should remain are at **UI entry points** where we bridge from synchronous UI callbacks to async:
- SwiftUI button actions in `UploadInfoView` (Task { await verifyConnection() }, Task { await performUpload() })
- NSOpenPanel/NSSavePanel `.begin { }` callbacks if they need to call async methods
- These are idiomatic and unavoidable — UI callbacks are synchronous by nature

## Key Guidelines (from CLAUDE.md & swift-concurrency skill)

- Do NOT add explicit `@MainActor` annotations — isolation is inferred via build settings
- Do NOT annotate value types (structs, enums) as `Sendable` — they are Sendable by default
- Prefer `@concurrent` for background work instead of actor isolation opt-outs
- Avoid unnecessary `Task {}` — prefer async/await
- `nonisolated(nonsending)` for generic async utilities that should stay on caller's executor

---

## Stage 5: Enable Swift 6 Language Mode — Full Strict Concurrency

**Goal:** Flip `SWIFT_VERSION` from `5.0` to `6.0` so all concurrency warnings become hard errors. This is the capstone — the app and tests must compile with zero concurrency diagnostics.

**Depends on:** Stages 1–4 complete (zero concurrency warnings).

### 5a. Build setting change

**`PPPC Utility.xcodeproj/project.pbxproj`** — 4 locations (app Debug, app Release, test Debug, test Release):
- `SWIFT_VERSION = 5.0` → `SWIFT_VERSION = 6.0`

All other concurrency settings are already correct from Stage 1:
- `SWIFT_STRICT_CONCURRENCY = complete` ✅
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` ✅
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` ✅

### 5b. Fix override isolation mismatches (from Stage 1 diagnostics)

Stage 1 Results identified two warning categories. Category 1 (`Token.isValid` cross-isolation) is resolved by Stage 2. Category 2 — **override isolation mismatches** — is not addressed by Stages 2–4 and becomes an error in Swift 6.

The issue: With `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, our classes and their method overrides are MainActor-isolated. But some parent class methods from ObjC frameworks are not annotated for MainActor in the SDK. The compiler warns (Swift 5) / errors (Swift 6) about the isolation mismatch.

**Known locations from Stage 1 results:**

1. **`SaveViewController.swift`** — `override func observeValue(forKeyPath:of:change:context:)`
   - NSObject's `observeValue` is not MainActor-annotated in the SDK
   - Fix: Add `nonisolated` to the override, since KVO callbacks can fire from any context. The method body only accesses `self` (which is MainActor), so wrap the body access in `MainActor.assumeIsolated { }` — this is safe because KVO on `@objc dynamic` properties from MainActor objects delivers on MainActor.
   - Alternative: If Swift 6.2 SDK has annotated this method by the time we get here, no fix needed — verify by building first.

2. **Test classes** — `override func setUp()` in `ModelTests`
   - XCTestCase lifecycle methods (`setUp`, `tearDown`) are `nonisolated` in the XCTest header. With default MainActor isolation, test subclasses are MainActor, creating a mismatch on the override.
   - Fix: Add `nonisolated` to `override func setUp()`. If the body needs MainActor access, mark the override as `override func setUp() async throws` (XCTest supports async setUp in modern versions) or move setup work to a helper.

### 5c. Verification

1. **Build** both app and test targets (Debug + Release) — zero errors, zero warnings
2. **Run all tests** — all pass
3. **Manual smoke test** — launch app, add executables, configure TCC policies, save/export profile, import profile
4. Confirm no runtime isolation assertions (Swift 6 adds runtime checks for actor isolation violations)

### What should NOT be in Stage 5

- No explicit `@MainActor` annotations — isolation is inferred via `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- No `Sendable` annotations on value types (structs, enums) — they are Sendable by default
- No new `Task {}` wrappers — if something needs async bridging, it should have been handled in Stages 3–4
- No behavioral changes — Stage 5 is purely a compiler enforcement change
