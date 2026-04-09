# Quickstart: Verify Deprecation Fixes

## Prerequisites

- Xcode installed with macOS SDK
- Project cloned and on branch `001-fix-deprecations`

## Step 1: Capture the baseline

```bash
xcodebuild clean build-for-testing \
  -project "PPPC Utility.xcodeproj" \
  -scheme "PPPC Utility" \
  -destination "platform=macOS" 2>&1 \
  | grep -i "warning:" | grep -v "xcodebuild: WARNING"
```

Expected: 10 warnings (see `research.md` for the full list).

## Step 2: Apply fixes

Make the changes described in `research.md`. See `tasks.md` for the task
breakdown once generated.

## Step 3: Verify zero warnings

Re-run the same command from Step 1.

Expected: **no output** (zero warnings).

## Step 4: Run the test suite

```bash
xcodebuild test \
  -project "PPPC Utility.xcodeproj" \
  -scheme "PPPC Utility" \
  -destination "platform=macOS" 2>&1 \
  | grep -E "(Test Suite|PASSED|FAILED|error:)"
```

Expected: All test suites pass, no failures.

## Definition of Done

- [ ] Zero deprecation warnings in build output
- [ ] Zero concurrency warnings introduced or remaining
- [ ] All unit tests pass
- [ ] All UI tests pass
- [ ] No behaviour changes observable in the app
