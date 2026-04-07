# PPPC Utility

## Swift Concurrency

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set on both app and test targets — don't add explicit `@MainActor` to production code or test structs/functions, it's already the default

## Swift Testing Conventions

- Place `@Test` and `@Suite` annotations on the line **above** the declaration, not inline
- Use `// when` and `// then` comment blocks; skip `// given` (assumed from context)
- When XCTest assertions have message strings, preserve them as `#expect` messages, not code comments (e.g. `#expect(x == false, "reason")`)
- Avoid `#require` on `Bool?` — it's ambiguous; use `#expect(x == true)` instead
- Capture a baseline of compiler warnings before each phase, then verify no new warnings after. Use this command and compare the output before/after:
  ```
  xcodebuild clean build-for-testing -project "PPPC Utility.xcodeproj" -scheme "PPPC Utility" -destination "platform=macOS" 2>&1 | grep -i "warning:" | grep -v "xcodebuild: WARNING"
  ```
- Test mocks must be parallel-safe. For URLProtocol mocks, use a per-session handler registry keyed by a unique session ID (e.g., a request header), with thread-safe storage and teardown reset; do not rely on a single static handler when tests can run in parallel.
- Use parameterized tests with Traits where it reduces duplication; 1–2 args is ideal, max 3
- Beyond 3 params: create separate tests with some values hard-coded
