---
description: Implement a feature from spec with tests and coverage verification
argument-hint: <feature-or-area>
---

You are implementing a feature for the LibreRadio iOS app. The user has requested: **$ARGUMENTS**

Follow these 12 steps in order. Do not skip steps.

---

## Step 1: Understand

Read the project spec and plan to understand requirements and architecture:

1. Read `SPEC.md` — this is the **behavioral truth**. Every UI behavior, API call, and edge case defined here must be matched exactly.
2. Read `PLAN.md` — this is the **architectural guide**. It defines the file structure, patterns, and phased delivery.
3. Scan existing source files in `LibreRadio/` and `LibreRadioTests/` to understand what is already built and what conventions are in use.
4. Create a task to track your progress through these steps.

Identify which parts of SPEC.md and PLAN.md relate to **$ARGUMENTS**.

---

## Step 2: Plan

Determine exactly what needs to be built:

1. List every file to create or modify, organized by layer:
   - **Models** (`LibreRadio/Models/`) — `Codable, Identifiable, Hashable` structs
   - **Services** (`LibreRadio/Services/`) — `actor` types (except audio service which is `@MainActor`)
   - **ViewModels** (`LibreRadio/ViewModels/`) — `@MainActor final class` conforming to `ObservableObject`
   - **Views** (`LibreRadio/Views/`) — SwiftUI views
   - **Tests** (`LibreRadioTests/`) — mirroring the source structure
2. Identify dependencies on features that are not yet built. If a dependency is missing and small, build it. If large, note it and implement what you can.
3. Update your task with the plan.

---

## Step 3: Implement

Write the code following these project conventions:

- **Architecture:** MVVM with SwiftUI
- **Concurrency:** Swift concurrency (`async/await`, `actor`). **No Combine.**
- **ViewModels:** `@MainActor final class SomethingViewModel: ObservableObject` with `@Published` properties
- **Services:** `actor` isolation (except `AudioPlayerService` which is `@MainActor` due to AVPlayer requirements)
- **Models:** `struct` conforming to `Codable, Identifiable, Hashable`
- **Views:** SwiftUI, iOS 16+ APIs only
- **No third-party dependencies** — pure Apple SDK

**IMPORTANT:** After adding or removing any `.swift` file, you MUST run:
```bash
xcodegen generate
```
This regenerates `LibreRadio.xcodeproj` from `project.yml`. Forgetting this is the #1 cause of build failures.

---

## Step 4: Write Tests

Write thorough tests following established patterns in the project:

- Use `MockURLProtocol` for network mocking (defined in `LibreRadioTests/Helpers/MockURLProtocol.swift`)
- Use `TestFixtures` for test data (defined in `LibreRadioTests/Helpers/TestHelpers.swift`)
- Use `TestFixtures.makeMockSession()` to create a mock `URLSession`
- Add `@MainActor` on test classes that test `@MainActor` view models
- Test all logic branches: success paths, error paths, edge cases, empty states
- Mirror the source directory structure in the test target

**IMPORTANT:** After adding test files, run `xcodegen generate` again.

---

## Step 5: Build & Test

Run the build first, then tests with coverage:

```bash
# Build
xcodebuild -project LibreRadio.xcodeproj -scheme LibreRadio -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build 2>&1

# Test with coverage
xcodebuild -project LibreRadio.xcodeproj -scheme LibreRadioTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -enableCodeCoverage YES test 2>&1 | grep -E '(error:.*\.swift|Executed|TEST SUCCEEDED|TEST FAILED)'
```

---

## Step 6: Fix & Iterate

If there are build errors or test failures:

1. Read the error output carefully
2. Fix the issues in the source or test code
3. Run `xcodegen generate` if you added/removed files
4. Go back to Step 5

**Keep looping Steps 5–6 until:**
- Zero build errors
- All tests pass
- All logic branches are covered by tests

---

## Step 7: Final Verification

Before declaring done:

1. **Re-read the relevant sections of SPEC.md** — verify every behavioral detail described in the spec is correctly implemented. Check edge cases, error messages, UI states.
2. **Re-read the relevant sections of PLAN.md** — verify the implementation follows the prescribed architecture (correct layers, correct patterns, correct file locations).
3. **Run the full test suite one final time** to confirm everything passes.
4. **Summarize** what was built: files created/modified, features implemented, test coverage, and any known limitations or deferred work.

---

## Step 8: Self Code Review

Re-read every file you created or modified in this implementation. Review with a critical eye as if reviewing someone else's PR:

1. **Bugs** — Logic errors, off-by-one, missing guards, incorrect state transitions, race conditions, unhandled edge cases. Pay special attention to:
   - Parameters accepted but never used
   - State that can become inconsistent (e.g., offset advances but data doesn't load)
   - Task cancellation paths that leave dirty state or show wrong errors
   - Async code that doesn't check for cancellation after an `await`
2. **Spec compliance** — Compare each behavior against SPEC.md line by line. Are all states handled? Are error messages correct? Are sort orders, page sizes, and limits exactly as specified?
3. **Conventions** — Does the code follow the project's established patterns? Correct architecture layer, naming, isolation (`actor` vs `@MainActor`), no Combine, etc.
4. **Design** — Unnecessary complexity, dead code, unused parameters, duplicated logic, missing abstractions (or premature abstractions).

**Fix every bug you find.** For design observations that don't warrant a fix, note them briefly. After fixing, re-run `xcodegen generate` (if files changed) and the full test suite to confirm nothing broke.

---

## Step 9: Update Docs

Update `SPEC.md` and `PLAN.md` with any decisions and edge cases discovered during implementation:

1. **SPEC.md** — Add or refine behavioral details, edge cases, error scenarios, or UI states that were discovered or clarified during implementation but were not originally documented. Keep the same style and structure as the existing spec.
2. **PLAN.md** — Document architectural decisions made during implementation: API quirks encountered, patterns chosen over alternatives, deviations from the original plan with rationale, and any gotchas future implementers should know about. Add notes inline near the relevant component specifications.
3. **PLAN.md — Implementation Notes** — At the end of the relevant phase section, add an `**Implementation notes (Phase N):**` block capturing lessons learned during this implementation. Include:
   - **Mistakes made and how they were fixed** — build errors, incorrect assumptions, API misunderstandings, wrong patterns tried first. Be specific: what went wrong, why, and what the fix was.
   - **Non-obvious patterns that worked** — solutions that weren't obvious from the spec/plan but turned out to be necessary (e.g., workarounds for framework quirks, specific initialization orders, threading constraints).
   - **Corrections to the plan** — anywhere the plan was wrong, incomplete, or misleading. Fix the plan inline AND note what was wrong so the same mistake isn't repeated.
   - **Time sinks to avoid** — anything that took multiple iterations to get right, so future implementations can go straight to the working approach.

   The goal is to make PLAN.md a living document that gets smarter with each implementation pass. Future runs of `/implement` read these notes and avoid repeating the same mistakes.

**Do not** rewrite existing content that is still accurate — only add new information or correct details that turned out to be wrong. Keep additions concise and factual.

---

## Step 10: Code Review

Review the full changeset as a cohesive unit — not file-by-file as in Step 8, but as a complete diff representing what would be merged. Use `git diff` to see every line changed, then evaluate:

1. **Correctness** — Does the change as a whole do what was requested? Are there logical gaps between files (e.g., a service method added but never called, a model field decoded but never displayed)?
2. **Consistency** — Do naming conventions, error handling patterns, and architectural boundaries remain consistent across the entire change? No file should introduce a pattern that contradicts another file in the same changeset.
3. **Completeness** — Is anything half-done? Check for TODO/FIXME comments you left, placeholder values, empty implementations, or test stubs that don't assert anything meaningful.
4. **Regression risk** — Could any of these changes break existing functionality? Look for modified shared types, changed function signatures, or altered service behavior that other parts of the app depend on.
5. **Test quality** — Do the tests actually validate the behavior, or do they just exercise code paths without meaningful assertions? Are failure modes tested, not just happy paths?

**Fix every issue you find.** After fixing, re-run the full test suite to confirm nothing broke. If you made changes, do another pass of this review until the diff is clean.

---

## Step 11: Update Changelog

Append a new entry to `CHANGELOG.md` in the project root. **This file is append-only** — never modify or remove existing entries.

If `CHANGELOG.md` does not exist yet, create it with a `# Changelog` header before adding the first entry.

Each entry should follow this format:

```markdown
## YYYY-MM-DD — Brief title of the change

**Prompt:** `/implement $ARGUMENTS`

**Changes:**
- Bullet list summarizing what was built, modified, or fixed
- Include files created, features added, and notable decisions
```

Use today's date and the exact `$ARGUMENTS` the user provided. The changes summary should be concise but complete enough that someone reading the changelog can understand what was delivered without reading the code.

---

## Step 12: Final Consistency Check

Re-read `SPEC.md`, `PLAN.md`, and `CHANGELOG.md` in full. Verify they are mutually consistent and accurately reflect the current implementation:

1. **SPEC.md vs code** — Every behavior described in SPEC.md should match what the code actually does. If the implementation revealed that a spec detail was wrong, incomplete, or needed adjustment, the spec should already reflect that (from Step 9). Catch anything missed.
2. **PLAN.md vs code** — The architecture, file structure, and patterns described in PLAN.md should match reality. Phase statuses should be up to date. No plan section should describe components that were removed, renamed, or never built.
3. **CHANGELOG.md vs code** — The changelog entry from Step 11 should accurately describe what was actually delivered. Cross-check against `git diff` — if you fixed bugs or added features during review steps that aren't mentioned, update the entry.
4. **SPEC.md vs PLAN.md** — The two documents should not contradict each other. If SPEC.md defines a behavior, PLAN.md should describe how it's architecturally supported (and vice versa). Resolve any drift.
5. **CHANGELOG.md vs SPEC.md/PLAN.md** — The changelog should not claim features that aren't documented in the spec, and shouldn't omit features that are.

**Fix any inconsistencies you find.** Keep corrections minimal and factual — do not rewrite sections that are already accurate.
