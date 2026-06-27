# Product Backlog

Baseline date: 2026-06-26

This backlog is the working Scrum planning surface for Rich War Online. `docs/MVP_SCOPE.md` remains the product baseline, while this file tracks the ordered work that can move into short sprints.

## Product Goal

Prove a stable multiplayer board-game core loop that can later support intervention cards:

- 1-4 players can take turns on one shared board.
- Players can roll, move, choose routes, buy or skip properties, and pay rent.
- The game state remains readable, recoverable, and testable.
- Blocking bugs are fixed before expanding feature scope.

## Cadence

- Sprint length: 2-3 days during prototype discovery.
- Sprint planning: choose one narrow goal and the smallest useful story set.
- Daily check: identify blockers, next action, and whether scope needs to shrink.
- Review: demonstrate the current acceptance target.
- Retro: record one process improvement for the next sprint.

## Priority Scale

- P0: blocks v0.1-local-core-loop acceptance.
- P1: needed for the next playable baseline.
- P2: useful soon, but can wait.
- P3: polish, cleanup, or future expansion.

## Epic Structure

- Epic 1: Prototype Map Pipeline.
- Epic 2: Local Core Loop.
- Epic 3: Online Authority.
- Epic 4: Special Events, Buildings, And Cards.
- Epic 5: Original Map Authoring.

## First Backlog Slice

| ID | Issue | Priority | Type | Status | Target | Title | Acceptance summary |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PB-001 | - | P0 | Task | Done | sprint0 | Establish GitHub issue templates | Story, bug, and sprint task issue forms exist under `.github/ISSUE_TEMPLATE`. |
| PB-002 | - | P0 | Task | Done | sprint0 | Create Product Backlog | Ordered backlog exists and uses priority, status, target, and acceptance fields. |
| PB-003 | - | P0 | Task | Done | sprint0 | Define v0.1-local-core-loop acceptance criteria | `docs/releases/v0.1-local-core-loop.md` defines scope, pass criteria, and evidence format. |
| PB-004 | [#1](https://github.com/benson94879453/rich-war-online/issues/1) | P0 | QA | Done | v0.1-local-core-loop | Run 4-player local core-loop test | Manual evidence records 20 completed turns across P1-P4 without script errors or stuck pending actions. |
| PB-005 | - | P0 | Bug | Done | v0.1-local-core-loop | Restore route choices from serialized direction arrays | Route-choice UI accepts both `PackedInt32Array` and serialized Array payloads. |
| PB-006 | [#2](https://github.com/benson94879453/rich-war-online/issues/2) | P0 | Story | Done | v0.1-local-core-loop | Verify deterministic 4-player turn order | P1, P2, P3, P4 order repeats across at least five full rounds. |
| PB-007 | [#3](https://github.com/benson94879453/rich-war-online/issues/3) | P0 | Story | Done | v0.1-local-core-loop | Verify local route-choice continuation | A route choice blocks rolling, exposes valid direction buttons, resumes movement, and clears controls after selection. |
| PB-008 | [#4](https://github.com/benson94879453/rich-war-online/issues/4) | P0 | Story | Done | v0.1-local-core-loop | Verify local property decision flow | Buy, Skip, unaffordable purchase, and rent paths do not leave stale controls or rejected-action noise. |
| PB-009 | [#5](https://github.com/benson94879453/rich-war-online/issues/5) | P1 | Test | Done | v0.1-local-core-loop | Add automated smoke coverage for snapshot restore | A lightweight test or script validates GameState restore for turn, players, money, properties, and pending route data. |
| PB-010 | [#6](https://github.com/benson94879453/rich-war-online/issues/6) | P1 | Story | Done | next | Improve same-seat reconnect baseline | A reconnecting client can reclaim or clearly fail to reclaim its previous seat with visible state. |
| PB-011 | [#8](https://github.com/benson94879453/rich-war-online/issues/8) | P2 | Tech Debt | Done | next | Separate legacy demo scenes from active baseline | README and docs clearly identify active scene versus legacy demos. |
| PB-012 | [#7](https://github.com/benson94879453/rich-war-online/issues/7) | P0 | QA | Done | sprint0 | Record manual test evidence format | First v0.1 manual test issue has a complete evidence comment. |
| PB-013 | [#9](https://github.com/benson94879453/rich-war-online/issues/9) | P1 | Chore | Done | sprint0 | Clean up GDScript reload warnings | The five warnings recorded during v0.1 manual QA are removed without behavior changes. |
| PB-014 | [#10](https://github.com/benson94879453/rich-war-online/issues/10) | P1 | Docs | Done | sprint1 | Document map pipeline | `docs/MAP_PIPELINE.md` describes source, internal concepts, current resources, and validation rules. |
| PB-015 | [#10](https://github.com/benson94879453/rich-war-online/issues/10) | P1 | Docs | Done | sprint1 | Define RichWarMap schema draft | A schema draft names map, node, tile, connection, spawn, and effect fields. |
| PB-016 | [#11](https://github.com/benson94879453/rich-war-online/issues/11) | P1 | Docs | Done | sprint1 | Inventory active board resource | Current `starq_board.tres` assumptions and known gaps are documented. |
| PB-017 | [#12](https://github.com/benson94879453/rich-war-online/issues/12) | P1 | QA | Done | sprint1 | Add map validation checklist | Manual checklist covers spawns, directions, junctions, tile mappings, and blocked movement risks. |
| PB-018 | [#13](https://github.com/benson94879453/rich-war-online/issues/13) | P2 | Test | Done | sprint1 | Plan map validation smoke script | Script inputs, checks, pass/fail behavior, and implementation follow-up are defined. |
| PB-019 | [#14](https://github.com/benson94879453/rich-war-online/issues/14) | P3 | Cleanup | Done | later | Decide stale Godot temporary file cleanup | Stale `.tmp` files were confirmed, removed, and similar Godot temp artifacts are ignored. |
| PB-020 | [#16](https://github.com/benson94879453/rich-war-online/issues/16) | P2 | Test | Done | sprint1 | Implement map validation smoke script | Headless Godot script runs the planned active-map validation checks and exits non-zero on failure. |
| PB-021 | [#20](https://github.com/benson94879453/rich-war-online/issues/20) | P1 | Story | Done | sprint2 | Add reconnect identity token lifecycle | Client creates and reuses a prototype reconnect token for the active session and can send it during join/reconnect. |
| PB-022 | [#21](https://github.com/benson94879453/rich-war-online/issues/21) | P1 | Story | Done | sprint2 | Add Host seat reservation model | Host reserves disconnected player seats and excludes reserved seats from normal open-seat assignment. |
| PB-023 | [#22](https://github.com/benson94879453/rich-war-online/issues/22) | P1 | Story | Done | sprint2 | Reassign matching reconnect token to reserved seat | A reconnecting Client with a known token returns to the same player seat and receives a fresh Host snapshot. |
| PB-024 | [#23](https://github.com/benson94879453/rich-war-online/issues/23) | P1 | QA/UX | Done | sprint2 | Refresh snapshot and debug status after reconnect | Reconnect status is visible enough for manual QA, and restored UI state matches Host after snapshot sync. |
| PB-025 | [#24](https://github.com/benson94879453/rich-war-online/issues/24) | P1 | QA | Done | sprint2 | Run same-seat reconnect acceptance pass | Automated reconnect smoke evidence is recorded; manual two-window QA was reported passed on issue #24 after the reserved-seat token mismatch bug was fixed. |
| PB-026 | [#31](https://github.com/benson94879453/rich-war-online/issues/31) | P1 | Docs | Done | sprint3 | Update post-Sprint2 planning baseline | Roadmap, MVP scope, Sprint3 plan, and backlog reflect that P0.3 reconnect is complete and Sprint3 targets online-core stability. |
| PB-027 | [#32](https://github.com/benson94879453/rich-war-online/issues/32) | P1 | QA | Done | sprint3 | Define networked 10-turn acceptance pass | Manual checklist and evidence format define how to validate 2-4 networked players for 10 turns without divergence. |
| PB-028 | [#33](https://github.com/benson94879453/rich-war-online/issues/33) | P1 | QA | In Progress | sprint3 | Run networked 10-turn acceptance pass | Evidence records at least 10 networked turns or a named blocker, including Host/Client state comparison. |
| PB-029 | [#34](https://github.com/benson94879453/rich-war-online/issues/34) | P2 | QA/UX | Planned | sprint3 | Review network authority failure visibility | Testers can clearly record joined/reconnected/spectator status, snapshot sync, rejected intents, and pending-action failures. |
| PB-030 | [#35](https://github.com/benson94879453/rich-war-online/issues/35) | P1 | Review | Planned | sprint3 | Record v0.2-online-core readiness review | Sprint3 evidence is summarized with a clear ready/not-ready recommendation for moving toward events, buildings, or cards. |

## Ready Criteria

A backlog item is ready for sprint work when:

- It has one clear outcome.
- Acceptance criteria are observable.
- Dependencies are named.
- QA path is known, even if manual.
- Scope fits inside one short sprint or can be split.

## Done Criteria

A backlog item is done when:

- The implementation or document change is merged into the working branch.
- Acceptance criteria are met or the remaining gap is explicitly documented.
- Relevant manual checklist steps are updated.
- Blocking bugs discovered during verification are either fixed or promoted to P0.

## Blocker Policy

A bug is P0 if it prevents the local core loop from completing:

- The game cannot start from `res://scenes/StarQGame.tscn`.
- A player turn cannot advance.
- Movement reaches a route choice and cannot continue.
- Buy, Skip, or rent leaves the game in a stuck pending state.
- A script error invalidates the current manual test run.
