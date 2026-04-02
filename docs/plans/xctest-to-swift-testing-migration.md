# XCTest → Swift Testing Migration Plan

## Problem
Convert 52 test methods across 8 test files (plus 2 helpers) from XCTest to Swift Testing. The migration should be incremental and phased, starting with one file to establish patterns and build context.

## Approach
- Migrate one file at a time, review after each phase
- Order files from simplest → most complex
- Keep XCTest and Swift Testing coexisting (the frameworks run side-by-side)
- Update CLAUDE.md with learned patterns/context after the first phase
- Helpers (ModelBuilder, TCCProfileBuilder) don't need conversion — they're plain Swift

## Key Conversion Patterns

| XCTest | Swift Testing |
|--------|---------------|
| `class FooTests: XCTestCase` | `@Suite` (line above) `struct FooTests` |
| `import XCTest` | `import Testing` |
| `func testFoo()` | `@Test` (line above) `func foo()` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertTrue(x)` | `#expect(x)` |
| `XCTAssertFalse(x)` | `#expect(!x)` |
| `XCTAssertNil(x)` | `#expect(x == nil)` |
| `XCTAssertNotNil(x)` | `try #require(x)` (unwraps) |
| `XCTUnwrap(x)` | `try #require(x)` |
| `XCTFail("msg")` | `Issue.record("msg")` |
| `setUp()` | `init()` |

## Notes
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set — no explicit `@MainActor` needed
- `@testable import PPPC_Utility` stays the same
- Helpers (ModelBuilder, TCCProfileBuilder) are plain Swift — no changes needed
- `test` prefix on method names is dropped — `@Test` already marks them
- `@Test` and `@Suite` annotations go on the line above the declaration, not inline
- NetworkAuthManagerTests has async tests — Swift Testing supports `async throws` natively
- TCCProfileImporterTests uses callback-based patterns — may need `confirmation { }` macro

## Progress

- [x] **Phase 1: SemanticVersionTests** (3 tests)
- [x] **Phase 2: TokenTests** (5 tests)
- [x] **Phase 3: JamfProAPIClientTests + PPPCServicesManagerTests** (5 tests)
- [x] **Phase 4: NetworkAuthManagerTests** (7 tests)
- [x] **Phase 5: TCCProfileTests** (6 tests)
- [ ] **Phase 6: TCCProfileImporterTests** (5 tests)
- [ ] **Phase 7: ModelTests** (21 tests)

## Phases

### Phase 1: SemanticVersionTests (3 tests) ✅
- Simplest file: 3 test methods, no setUp/tearDown, no async, no mocks
- Only uses `XCTAssertTrue` and `XCTAssertFalse`
- Good candidate for parameterized tests (`@Test(arguments:)`) since each test runs multiple comparison assertions
- Establishes the basic conversion pattern for review

### Phase 2: TokenTests (5 tests) ✅
- Simple-medium: date checks and JSON decoding
- Uses `XCTAssertFalse`, `XCTAssertTrue`, `XCTAssertEqual`, `XCTAssertNotNil`, `XCTUnwrap`
- Introduces `try #require()` pattern (replacing XCTUnwrap)

### Phase 3: JamfProAPIClientTests (1 test) + PPPCServicesManagerTests (4 tests) ✅
- Both simple, batch together since JamfProAPIClientTests is only 1 test
- PPPCServicesManagerTests uses `XCTUnwrap` → `try #require()`

### Phase 4: NetworkAuthManagerTests (7 tests) ✅
- Async/await tests — Swift Testing handles these natively
- Has a MockNetworking class (stays as-is, it's not XCTest-specific)
- Error handling patterns with `do/catch` + `XCTFail` → `do/catch` + `Issue.record`

### Phase 5: TCCProfileTests (6 tests) ✅
- Serialization round-trip tests, uses TCCProfileBuilder helper
- Bundle resource loading (test bundle access pattern may need attention)

### Phase 6: TCCProfileImporterTests (5 tests)
- Most complex conversion: callback-based async patterns
- May need Swift Testing's `confirmation { }` macro for callback verification
- Bundle resource loading for .mobileconfig test files

### Phase 7: ModelTests (21 tests)
- Largest file (515 lines), saved for last
- Uses `setUp()` → convert to `init()`
- Heavy use of TCCProfileBuilder
- Comprehensive assertion coverage across all XCTAssert variants
