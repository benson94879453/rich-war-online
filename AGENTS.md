# AGENTS.md

## Development Workflow

This project follows a fast Agile/Scrum-like sprint workflow.

Codex must treat substantial feature work as a managed workflow, not as a one-step coding task. Normal feature work moves through:

1. Requirement issue
2. Concrete specification or sprint issue
3. Issue-sized implementation PR into the sprint branch
4. Sprint acceptance evidence
5. Sprint-end PR from the sprint branch back to `main`

## Branch Rules

- `main` is the stable branch.
- Do not commit feature work directly to `main`.
- Use a sprint integration branch for active sprint work, usually named like `codex/sprint2-reconnect-baseline`.
- Use issue branches for individual sprint items, usually named like `codex/issue-24-reconnect-acceptance-pass`.
- During a sprint, issue PRs target the sprint integration branch.
- Merge the sprint integration branch to `main` only after sprint acceptance is complete.

## Issue Rules

Before implementation, Codex should check whether there is a concrete issue or specification.

If only a rough requirement exists, first convert it into a concrete issue or specification before editing code.

Implementation-ready issues should include:

- Goal
- Scope
- Acceptance criteria
- Affected files or modules
- Edge cases or risks
- Test plan
- Definition of done

## Default Behavior

When the user asks Codex to implement a feature:

1. Identify whether the request is a requirement, specification, implementation task, acceptance task, or sprint closeout.
2. If the request is vague, draft or create a requirement issue first.
3. If the requirement is clear but not implementable, draft or create a concrete specification issue.
4. If the issue is concrete, implement the smallest useful change on an issue branch targeting the sprint branch.
5. After implementation, summarize what changed, which issue it satisfies, how it was verified, and whether it is ready for sprint review.

## Acceptance And Closeout

- Record automated checks with exact commands and results.
- Record manual checks honestly; do not mark manual QA as passed unless it was actually executed.
- If manual QA remains, leave the issue or sprint item open or explicitly mark it pending.
- Final sprint closeout should list completed issues, remaining risks, validation evidence, and the recommended merge decision.

## Exceptions

Hotfixes may bypass the full sprint flow only when the user explicitly says the work is a hotfix, emergency fix, production breakage, or urgent patch.

Even for hotfixes, summarize the reason, risk, and verification steps.
