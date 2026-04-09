# Feature Specification: Fix Deprecation Warnings

**Feature Branch**: `001-fix-deprecations`
**Created**: 2026-04-09
**Status**: Draft
**Input**: User description: "I want to fix all the deprecation warnings in the project"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Clean Build Output (Priority: P1)

A developer builds the project and sees zero deprecation warnings in the build
output. All deprecated API usages have been replaced with their recommended
modern equivalents, so the build compiles cleanly without requiring suppressions
or workarounds.

**Why this priority**: Deprecation warnings are early signals of future
breakage. Eliminating them now prevents forced migrations under time pressure
when deprecated APIs are eventually removed. A warning-free build is also a
baseline quality gate that makes genuine new warnings visible.

**Independent Test**: Build the project from a clean state and confirm no
deprecation warnings appear in the output.

**Acceptance Scenarios**:

1. **Given** the project is built from a clean state, **When** the build
   completes, **Then** zero deprecation warnings appear in the build log.
2. **Given** the project tests are run, **When** the test suite completes,
   **Then** zero deprecation warnings appear during compilation or execution.
3. **Given** any deprecated API has been replaced, **When** the replacement is
   used, **Then** existing functionality behaves identically to the previous
   implementation.

---

### User Story 2 - No Regression for End Users (Priority: P2)

A user of PPPC Utility — a macOS administrator creating and uploading
configuration profiles — experiences no change in behaviour. All features
(adding bundles, saving profiles, uploading to Jamf Pro, importing profiles)
continue to work exactly as before.

**Why this priority**: The deprecation fixes must be transparent to the end
user. A regression introduced while silencing warnings would be worse than the
warnings themselves.

**Independent Test**: Launch the app, perform the primary workflows (add
bundle, save profile locally, upload to Jamf Pro, import a profile), and
confirm all work correctly.

**Acceptance Scenarios**:

1. **Given** a profile has been built with bundle entries, **When** the profile
   is saved locally, **Then** the saved file is valid and matches the expected
   format.
2. **Given** valid Jamf Pro credentials are entered, **When** the profile is
   uploaded, **Then** the upload succeeds and the profile appears in Jamf Pro.
3. **Given** an existing signed or unsigned profile, **When** it is imported,
   **Then** all entries are displayed correctly in the UI.

---

### Edge Cases

- What happens if a deprecated API has no direct drop-in replacement and
  requires a behaviour change? Each such case must be documented and the
  replacement must produce equivalent observable results.
- What if a fix for one deprecated API introduces a warning in a different
  category (e.g., a newer API unavailable on the minimum OS target)? Such
  trade-offs must be flagged and resolved before the change is accepted.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All deprecation warnings in the project MUST be resolved — no
  suppression, no `@available` guards that merely hide the warning.
- **FR-002**: Each deprecated API call MUST be replaced with the recommended
  modern equivalent as documented by the platform vendor.
- **FR-003**: All existing unit tests MUST continue to pass after replacements
  are applied.
- **FR-004**: All existing UI tests MUST continue to pass after replacements
  are applied.
- **FR-005**: The project MUST build without deprecation warnings on the
  minimum deployment target (macOS 13.0).
- **FR-006**: No new warnings of any category MUST be introduced while fixing
  existing ones.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The build produces zero deprecation warnings (count: 0) when
  compiled for the minimum supported OS version.
- **SC-002**: 100% of the existing automated test suite passes after all
  replacements are applied.
- **SC-003**: No user-visible behaviour changes are introduced — confirmed by
  the UI test suite and manual smoke testing of the primary workflows.
- **SC-004**: The warning-free state is durable — no deprecated API usage
  remains that would re-surface as warnings in a future toolchain update.

## Assumptions

- Deprecated APIs used in the project have available, documented replacements
  that work on macOS 13.0 and newer.
- The scope is limited to deprecation warnings; other warning categories (e.g.,
  unused variables, Swift naming conventions) are out of scope unless they
  appear as a direct consequence of a deprecation fix.
- Test coverage already exists for the code paths affected; if a deprecated
  call is in an untested path, the replacement is still applied but no new
  tests are added as part of this feature.
- Production code is not restructured beyond what is necessary to replace the
  deprecated call.
