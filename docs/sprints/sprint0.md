# Sprint0

Start date: 2026-06-26

## Sprint Goal

Create the lightweight Scrum operating system for Rich War Online and make `v0.1-local-core-loop` testable:

- GitHub issue templates exist.
- Product Backlog exists.
- First issue batch is defined.
- `v0.1-local-core-loop` acceptance criteria are explicit.
- 4-player local test flow is ready to run.
- P0 blockers found during bootstrap are fixed or promoted.

## Timebox

Use a short prototype sprint of 2-3 days. If a task cannot be completed inside that window, split it instead of stretching the sprint.

## Scrum Rhythm

- Planning: pick one sprint goal and only the items needed to prove it.
- Daily check: blocker, next action, scope adjustment.
- Review: show the acceptance evidence or the failing blocker.
- Retro: keep one practice, change one practice.

## Sprint Backlog

| Backlog ID | Status | Work item | Acceptance |
| --- | --- | --- | --- |
| PB-001 | Done | Establish GitHub issue templates | Story, bug, and sprint task forms are committed. |
| PB-002 | Done | Create Product Backlog | `docs/PRODUCT_BACKLOG.md` is the source of ordered work. |
| PB-003 | Done | Define v0.1-local-core-loop acceptance | `docs/releases/v0.1-local-core-loop.md` defines pass/fail criteria. |
| PB-004 | Done | Run 4-player local core-loop test | Manual evidence records 20 local turns or a named P0 blocker. |
| PB-005 | Done | Fix serialized route-choice blocker | Route-choice payloads accept both packed and serialized direction arrays. |
| PB-006 | Done | Verify deterministic 4-player turn order | P1-P4 repeats across five full rounds. |
| PB-007 | Done | Verify local route-choice continuation | Route choice can be resolved and movement continues. |
| PB-008 | Done | Verify property decision flow | Buy, Skip, unaffordable Buy, and rent paths remain unstuck. |
| PB-009 | Done | Add GameState snapshot smoke coverage | Scripted smoke check covers core snapshot restore fields. |
| PB-010 | Done | Define same-seat reconnect baseline | P0.3 reconnect behavior and manual acceptance are documented. |
| PB-011 | Done | Separate legacy demo scenes from active baseline | README and docs clearly identify active scene versus legacy demos. |
| PB-012 | Done | Record manual test evidence format | First v0.1 manual test issue has a complete evidence comment. |
| PB-013 | Done | Clean up GDScript reload warnings | Five warning-only QA findings are removed without behavior changes. |

## First GitHub Issue Batch

Created against `benson94879453/rich-war-online`:

1. [#1 `[Sprint0] Run v0.1 4-player local core-loop test`](https://github.com/benson94879453/rich-war-online/issues/1)
2. [#2 `[v0.1] Verify deterministic 4-player turn order`](https://github.com/benson94879453/rich-war-online/issues/2)
3. [#3 `[v0.1] Verify route-choice continuation in local play`](https://github.com/benson94879453/rich-war-online/issues/3)
4. [#4 `[v0.1] Verify property Buy / Skip / rent flow`](https://github.com/benson94879453/rich-war-online/issues/4)
5. [#5 `[v0.1] Add smoke coverage for GameState snapshot restore`](https://github.com/benson94879453/rich-war-online/issues/5)
6. [#6 `[P0.3] Define same-seat reconnect baseline`](https://github.com/benson94879453/rich-war-online/issues/6)
7. [#7 `[QA] Record manual test evidence format`](https://github.com/benson94879453/rich-war-online/issues/7)
8. [#8 `[Tech Debt] Mark legacy demo scenes outside active baseline`](https://github.com/benson94879453/rich-war-online/issues/8)
9. [#9 `[Chore] Clean up GDScript reload warnings`](https://github.com/benson94879453/rich-war-online/issues/9)

## Sprint0 Review Checklist

- Product Backlog is readable and ordered.
- Issue templates are selectable in GitHub.
- First GitHub issue batch exists.
- `v0.1-local-core-loop` has pass/fail criteria.
- 4-player local manual run is completed or blocked by a named P0 issue.
- Any blocker found during the run is fixed before new feature work.

## Current Verification Note

The local machine does not expose a `godot` command on PATH, so the 4-player manual run still needs to be executed from the Godot editor or a configured runner. The acceptance path and evidence format are ready.
