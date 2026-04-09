# Implementation Plan: Add New PPPC Keys

**Branch**: `002-add-pppc-keys` | **Date**: 2026-04-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-add-pppc-keys/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add three new PPPC service keys (BluetoothAlways, SystemPolicyAppBundles, SystemPolicyAppData) to the PPPC Utility, following the existing pattern of data-driven service registration. Each key requires additions to the JSON service registry, Swift enum, KVC-bound Policy class, storyboard UI, and view controller wiring. All three are standard Allow/Deny services with no special behaviors (confirmed via Apple MDM documentation).

## Technical Context

**Language/Version**: Swift 6.0 (main targets), Swift 5.0 (UI test target)
**Primary Dependencies**: AppKit (storyboard-based NSViewController), Cocoa Bindings (KVC)
**Storage**: N/A (in-memory model, file-based export/import)
**Testing**: Swift Testing (unit tests), XCTest/XCUITest (UI tests)
**Target Platform**: macOS 13.0+
**Project Type**: Desktop app (macOS)
**Performance Goals**: N/A (data-addition change, no performance-sensitive paths)
**Constraints**: Must follow existing storyboard + Cocoa Bindings pattern for UI; KVC requires `@objc dynamic` properties
**Scale/Scope**: 3 new services added to existing 21 (→ 24 total)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Simplicity | ✅ PASS | Pure data additions following existing patterns. No new abstractions, helpers, or compatibility shims. |
| II. macOS Platform Compliance | ✅ PASS | UI additions follow existing storyboard layout with accessibility identifiers and HIG-compliant popup buttons. Target remains macOS 13.0+. |

**Quality Gates**:
| Gate | Plan |
|------|------|
| Compiler warnings | Baseline before changes; compare after. |
| Unit tests | Update existing suites + add new assertions. All must pass. |
| UI tests | Add column count test. All must pass. |
| Constitution check | Re-verify after Phase 1 design. |

## Project Structure

### Documentation (this feature)

```text
specs/002-add-pppc-keys/
├── spec.md              # Feature specification
├── clarifications.md    # Clarification log
├── plan.md              # This file
├── research.md          # Phase 0 output (trivial — no unknowns)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
# Files requiring changes (existing — no new files in production code)
Resources/
├── PPPCServices.json                    # Add 3 new service entries
└── Base.lproj/Main.storyboard           # Add UI elements for 3 new services

Source/
├── Model/
│   ├── TCCProfile.swift                 # Add 3 new ServicesKeys enum cases
│   └── Executable.swift                 # Add 3 new @objc dynamic Policy properties
└── View Controllers/
    └── TCCProfileViewController.swift   # Add IBOutlets, setup calls, descriptions

# Test files requiring changes
Resources/
└── TestTCCUnsignedProfile.mobileconfig  # Update with 3 new service keys

PPPC UtilityTests/
├── ModelTests/
│   ├── PPPCServicesManagerTests.swift   # Update service count (21 → 24)
│   ├── ExecutableTests.swift            # Update policy default count
│   ├── ModelTests.swift                 # Add export/import round-trip tests
│   └── TCCProfileTests.swift            # (if needed for serialization)
├── TCCProfileImporterTests/
│   ├── TestTCCUnsignedProfile.mobileconfig        # NEW: all 24 services
│   ├── TestTCCUnsignedProfile-Legacy.mobileconfig  # RENAMED: original without new keys
│   ├── TestTCCUnsignedProfile-allLower.mobileconfig # Update with new keys lowercase
│   └── TCCProfileImporterTests.swift    # Add legacy import test
└── Helpers/
    └── TCCProfileBuilder.swift          # Add new keys to built policies

PPPC UtilityUITests/
└── AppLaunchTests.swift                 # Add column count test
```

**Structure Decision**: No new directories or modules needed. All changes extend existing files following established patterns.

## Complexity Tracking

> No violations. All changes are data-driven additions within existing architecture.
