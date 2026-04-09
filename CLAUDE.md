# PPPC Utility

## Swift General

- Never force unwrap (`!`) or force cast (`as!`) — use `if let`, `guard let`, or `as?` instead

## Swift Concurrency

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set on both app and test targets — don't add explicit `@MainActor` to production code or test structs/functions, it's already the default
- Always use Swift Concurrency (actors, async/await, Sendable) — avoid locks, mutexes, or other low-level synchronization

## Swift Testing Conventions

- When adding unit tests, do not modify production code just to accommodate a test. If a genuine bug is found, fix it in a separate commit with its own justification.
- Place `@Test` and `@Suite` annotations on the line **above** the declaration, not inline
- Use `// when` and `// then` comment blocks; skip `// given` (assumed from context)
- When XCTest assertions have message strings, preserve them as `#expect` messages, not code comments (e.g. `#expect(x == false, "reason")`)
- Avoid `#require` on `Bool?` — it's ambiguous; use `#expect(x == true)` instead
- Capture a baseline of compiler warnings before each phase, then verify no new warnings after. Use this command and compare the output before/after:
  ```
  xcodebuild clean build-for-testing -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" 2>&1 | grep -i "warning:" | grep -v "xcodebuild: WARNING"
  ```
- Network test suites use `.serialized` trait. `MockURLProtocol` uses a simple single static handler — no per-session registry needed.
- Avoid snake_case in test names (e.g., `generateDisplayName_bundleIdentifier`). If a name is getting long, use a Trait with a sentence-style description instead.
- For complex tests, use a descriptive `@Test("...")` trait that explains the scenario and expected outcome so the test is understandable without reading the body.
- Use parameterized tests with Traits where it reduces duplication; 1–2 args is ideal, max 3
- Beyond 3 params: create separate tests with some values hard-coded
- Use `deinit` as teardown for repeated cleanup across tests in a suite. Use `class` for suites that need `deinit`; use `struct` otherwise.

## UI Testing Conventions

- UI tests use XCTest (XCUITest), not Swift Testing — the UI test target uses Swift 5 with minimal concurrency checking
- Prefer **multiple assertions per test** to minimize app launches. Each test method relaunches the app, which is expensive. Group related checks (e.g., verify all buttons exist in one test) rather than one assertion per test.
- Do not use `// when` / `// then` comment blocks in UI tests — they add noise without clarity in assertion-heavy tests
- Use accessibility identifiers set in `setupAccessibilityIdentifiers()` to locate UI elements
- The `-UITestMode` launch argument triggers test-specific setup (e.g., loading a test profile)

## Git

- Do not stage or commit changes in terminal sessions
