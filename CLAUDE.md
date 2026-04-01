# PPPC Utility

## Swift Concurrency

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set on both app and test targets — don't add explicit `@MainActor` to production code or test structs/functions, it's already the default

## Swift Testing Migration

- Place `@Test` and `@Suite` annotations on the line **above** the declaration, not inline
- Use `// when` and `// then` comment blocks; skip `// given` (assumed from context)
