<!--
## Sync Impact Report

**Version change**: 1.0.0 → 1.1.0 — trimmed redundant principles; implementation
conventions now delegated to CLAUDE.md

### Modified Principles
- I. Swift Concurrency First → removed (covered by CLAUDE.md)
- II. Test-First Discipline → removed (covered by CLAUDE.md)
- III. UI Testing Standards → removed (covered by CLAUDE.md)
- IV. Simplicity → retained, renumbered I
- V. macOS Platform Compliance → retained, renumbered II

### Added Sections
- None

### Removed Sections
- Development Workflow (Git rule already in CLAUDE.md; pre-commit hook in README)

### Templates Requiring Updates
- All templates ✅ — no structural changes required.

### Deferred Items
- None.
-->

# PPPC Utility Constitution

## Core Principles

### I. Simplicity

All code MUST be as simple as the task requires — no more, no less.

- Speculative abstractions, premature helpers, and unused compatibility shims
  are prohibited.
- Do not add docstrings, comments, or type annotations to unchanged code.
- Do not add error handling for impossible scenarios; trust framework guarantees.
- Do not introduce feature flags or backwards-compatibility hacks when the code
  can simply change.
- Three similar lines of code are preferable to a premature abstraction.

**Rationale**: Speculative complexity increases maintenance burden without
delivering value. Simplicity is a feature.

### II. macOS Platform Compliance

PPPC Utility targets macOS 13.0 and newer. All UI MUST follow Apple's Human
Interface Guidelines. SwiftUI is the preferred UI framework; AppKit is
acceptable only for components without adequate SwiftUI coverage.

- Minimum deployment target: macOS 13.0.
- All interactive UI elements MUST have accessibility identifiers and labels.
- Profiles MUST be saveable locally (signed or unsigned) and uploadable to
  Jamf Pro (bearer token, basic auth fallback, or OAuth client credentials).

**Rationale**: Platform convention adherence ensures the application behaves
predictably and integrates naturally with macOS workflows and enterprise
management tools.

## Quality Gates

The following gates MUST pass before merging any change:

1. **Compiler warnings**: No new warnings introduced (compare baseline before
   and after per `CLAUDE.md`).
2. **Unit tests**: All Swift Testing suites pass.
3. **UI tests**: All XCUITest cases pass.
4. **Constitution check**: The change does not violate any principle above.

## Governance

This constitution supersedes all other development practices for this
repository. Implementation conventions (Swift Concurrency, testing, UI testing,
Git) are maintained in `CLAUDE.md`. Amendments require:

1. A written rationale explaining the change and its impact.
2. A version bump per the versioning policy below.
3. A migration note if existing code must be updated to comply.

**Versioning policy**:
- MAJOR: Backward-incompatible removal or redefinition of a principle.
- MINOR: New principle or section added, or material guidance expansion.
- PATCH: Clarifications, wording improvements, or typo fixes.

All PRs and code reviews MUST verify compliance with this constitution.
Complexity violations MUST be justified in the PR description.

**Version**: 1.1.0 | **Ratified**: 2026-04-09 | **Last Amended**: 2026-04-09
