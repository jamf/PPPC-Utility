---
name: "speckit-implement"
description: "Execute tasks from tasks.md by running each phase (Setup, Tests, Core, Integration, Polish) in dependency order with TDD-first approach. Use when the user asks to implement a feature, run the implementation plan, execute pending tasks, build from the task list, or start coding from a spec."
argument-hint: "Optional implementation guidance or task filter"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/implement.md"
user-invocable: true
disable-model-invocation: true
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before implementation)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_implement` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    
    Wait for the result of the hook command before proceeding to the Outline.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

4. **Project Setup Verification** — create/verify ignore files for detected tooling:
   - Run `git rev-parse --git-dir 2>/dev/null` — if git repo, verify `.gitignore` has essential patterns for the tech stack in plan.md
   - Detect other tooling (Dockerfile → `.dockerignore`, .eslintrc → `.eslintignore`, .prettierrc → `.prettierignore`, package.json → `.npmignore` if publishing, *.tf → `.terraformignore`, helm charts → `.helmignore`)
   - If ignore file exists: append only missing critical patterns
   - If ignore file missing: create with standard patterns for the detected technology and stack

5. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

6. **Execute implementation phase-by-phase** following the task plan:
   - Complete each phase before moving to the next
   - Run sequential tasks in order; parallel tasks marked `[P]` can run together
   - Follow TDD: execute test tasks before their corresponding implementation tasks
   - Tasks affecting the same files must run sequentially

   Example execution from a tasks.md:
   ```
   ## Phase: Setup
   - [X] T001: Initialize project with `npm init` and install deps from plan.md
   - [X] T002: Create directory structure per plan.md file tree
   ## Phase: Tests
   - [ ] T003: Write unit tests for UserService based on contracts/user-api.md
   - [ ] T004 [P]: Write integration test for database connection
   ## Phase: Core
   - [ ] T005: Implement UserService (depends on T003 tests passing first)
   ```
   For T003→T005: write the test (T003), verify it compiles/fails as expected, then implement (T005) until the test passes.

7. **Progress tracking**: Report progress after each completed task. Mark completed tasks as `[X]` in tasks.md. Halt on sequential task failure; for parallel `[P]` tasks, continue with successful ones and report failures with context.

8. **Completion validation**: Verify all tasks completed, features match the spec, tests pass, and implementation follows plan.md. Report final status summary.

   If tasks.md is incomplete or missing, suggest running `/speckit.tasks` first.

9. **Post-implementation extension hooks**: Follow the same hook-checking process described in Pre-Execution Checks above, but read the `hooks.after_implement` key instead of `hooks.before_implement`. Label output blocks as "Post-Hook" / "Automatic Post-Hook" instead of "Pre-Hook" / "Automatic Pre-Hook".
