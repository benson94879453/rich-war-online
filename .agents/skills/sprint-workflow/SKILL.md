---
name: sprint-workflow
description: Use when planning, refining, creating, reviewing, implementing, validating, or closing Agile/Scrum-like sprint work in a GitHub repository. Trigger for requirement issues, specification issues, sprint planning, issue PRs, sprint branches, acceptance criteria, manual QA evidence, sprint reviews, or merging sprint work back to main.
---

# Sprint Workflow

Use this skill to keep sprint work structured, traceable, and reviewable. The default workflow is:

1. Requirement issue
2. Concrete specification or sprint issue
3. Issue-sized PR into the sprint integration branch
4. Sprint acceptance evidence
5. Sprint-end PR from the sprint branch to `main`

## Workflow State

At the start of the task, state the current stage:

- `Requirement`: the user has an idea or goal, but implementation is not concrete.
- `Specification`: the goal is clear, but acceptance criteria, affected modules, or test plan are missing.
- `Implementation`: a concrete issue/spec exists and code or docs should be changed.
- `Acceptance`: the implementation exists and needs automated/manual verification evidence.
- `Sprint Review`: sprint items need status, risks, evidence, and merge readiness.
- `Merge Back`: the sprint branch is ready to merge to `main`.

Also state the decision: `Needs issue`, `Needs spec`, `Ready for implementation`, `Ready for acceptance`, `Ready for sprint review`, or `Ready to merge`.

## Issue Types

### Requirement Issue

Use when the user asks for a feature, system, or broad improvement without enough implementation detail.

Include:

```md
# [REQ] Title

## Background
Why this feature or change exists.

## Goal
The desired outcome.

## User Story
As a [role], I want [capability], so that [benefit].

## Scope
### In Scope
- ...

### Out of Scope
- ...

## Notes
Constraints, references, assumptions, or open questions.

## Next Step
Create a concrete specification issue before implementation.
```

### Specification Or Sprint Issue

Use when the requirement is understood but not yet ready for implementation.

Include:

```md
# [SPEC] Title

## Linked Requirement
- Related requirement issue: #

## Objective
What this implementation must accomplish.

## Functional Requirements
- ...

## Non-Functional Requirements
- Performance:
- Maintainability:
- Compatibility:
- Security / safety:

## Data / State Changes
New data structures, state fields, save data, protocol changes, or schema changes.

## UI / UX Behavior
Visible behavior, screens, buttons, messages, animations, or feedback.

## System Design
Affected modules, classes, nodes, APIs, files, or architecture.

## Edge Cases
- ...

## Acceptance Criteria
- [ ] ...

## Test Plan
- [ ] Automated tests:
- [ ] Manual tests:
- [ ] Regression checks:

## Definition of Done
- [ ] Code implemented
- [ ] Acceptance criteria satisfied
- [ ] Verification completed or explicitly marked pending
- [ ] No unrelated refactor
- [ ] Ready for sprint review
```

## Branch And PR Rules

- Treat `main` as stable.
- Use a sprint integration branch for sprint work, for example `codex/sprint2-reconnect-baseline`.
- Use issue branches for individual sprint items, for example `codex/issue-24-reconnect-acceptance-pass`.
- Issue PRs target the sprint integration branch, not `main`.
- The sprint branch targets `main` only after the sprint acceptance pass.
- Keep issue PRs scoped to one issue-sized outcome.
- Do not close a QA/acceptance issue when required manual QA was not actually executed; mark it pending or use `Refs #issue` instead of `Closes #issue`.

## When Asked To Implement

Classify the request before editing files.

### Vague Requirement

1. Do not code yet.
2. Draft or create a `[REQ]` issue.
3. Draft the next `[SPEC]` outline.
4. Make assumptions explicit.
5. Ask only for decisions that block a safe next step.

### Clear Requirement But No Concrete Spec

1. Draft or create a `[SPEC]` issue.
2. Include acceptance criteria, affected modules/files, and a test plan.
3. Stop before implementation unless the user explicitly asks to continue.

### Concrete Spec Exists

1. Sync the sprint integration branch.
2. Create an issue branch from the sprint branch.
3. Implement the smallest change satisfying the issue.
4. Avoid unrelated refactors.
5. Run available checks.
6. Open a draft PR to the sprint branch.
7. Summarize changes, validation, and remaining risks.

## Acceptance Work

For automated validation:

- Run the most relevant smoke/unit checks.
- Record exact commands and pass/fail results.
- Include `git diff --check` when code or docs changed.

For manual validation:

- Record what was actually executed.
- Record required observations.
- Mark unexecuted manual QA as pending.
- Do not claim manual acceptance passed unless it was performed.

## Sprint-End Behavior

When closing a sprint, prepare a review summary:

```md
# Sprint Review

## Sprint Branch
`codex/sprint...`

## Completed Issues
- #...

## Implemented Changes
- ...

## Not Completed
- ...

## Known Risks
- ...

## Test Summary
- ...

## Recommended Merge Decision
Ready / Not ready

## Merge Back To Main Checklist
- [ ] Sprint branch is up to date
- [ ] Tests pass
- [ ] Manual acceptance is complete or explicitly deferred
- [ ] No unfinished debug code
- [ ] Release notes or sprint docs updated if needed
- [ ] Open final PR from sprint branch to `main`
```

## Output Style

When this skill is active, include a compact workflow block when useful:

```md
## Workflow State
Current stage: Implementation
Decision: Ready for implementation
Next action: Create an issue branch from the sprint branch and implement the scoped change.
```

Keep final responses concise. Lead with the PR/issue/result, then list verification and remaining next steps.

## Important Rules

- Do not skip specification for normal feature work.
- Do not silently expand scope during implementation.
- Do not mark manual QA as passed unless it was actually run.
- Keep sprint issue PRs targeting the sprint branch until sprint closeout.
- If the user asks for a hotfix, summarize why the sprint workflow is being bypassed and still verify the change.
