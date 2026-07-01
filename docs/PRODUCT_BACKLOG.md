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
| PB-028 | [#33](https://github.com/benson94879453/rich-war-online/issues/33) | P1 | QA | Done | sprint3 | Run networked 10-turn acceptance pass | Owner reported the networked 10-turn acceptance pass completed normally with no divergence, stuck pending action, or P0 blocker. |
| PB-029 | [#34](https://github.com/benson94879453/rich-war-online/issues/34) | P2 | QA/UX | Done | sprint3 | Review network authority failure visibility | Testers can clearly record joined/reconnected/spectator status, snapshot sync, rejected intents, and pending-action failures. |
| PB-030 | [#35](https://github.com/benson94879453/rich-war-online/issues/35) | P1 | Review | Done | sprint3 | Record v0.2-online-core readiness review | Sprint3 evidence is summarized with a clear ready/not-ready recommendation for moving toward events, buildings, or cards. |
| PB-031 | [#42](https://github.com/benson94879453/rich-war-online/issues/42) | P1 | Docs | Done | sprint4 | Record action/effect foundation planning baseline | Sprint4 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-032 | [#43](https://github.com/benson94879453/rich-war-online/issues/43) | P1 | Tech Debt | Done | sprint4 | Introduce ActionDispatcher baseline | Existing roll, route choice, Buy, and Skip actions can flow through a single dispatch entry point while Host authority remains intact. |
| PB-033 | [#44](https://github.com/benson94879453/rich-war-online/issues/44) | P1 | Tech Debt | Done | sprint4 | Introduce EffectService baseline | Current tile money effects keep working through a shared effect service entry point that can later support cards, events, statuses, and buildings. |
| PB-034 | [#45](https://github.com/benson94879453/rich-war-online/issues/45) | P1 | Tech Debt | Done | sprint4 | Expand TurnSystem FSM baseline | Turn phase vocabulary supports explicit future intervention windows while existing movement, route, property, and rent flows remain stable. |
| PB-035 | [#46](https://github.com/benson94879453/rich-war-online/issues/46) | P1 | Tech Debt | Done | sprint4 | Add GameState snapshot reserved fields | Future hand, deck, discard, status, pending-intervention, and game-over fields have stable defaults and survive snapshot round-trip. |
| PB-036 | [#47](https://github.com/benson94879453/rich-war-online/issues/47) | P2 | Test | Done | sprint4 | Add scenario smoke baseline | At least one narrow scenario smoke path exists and is documented as the extension point for later event/building/card scenarios. |
| PB-037 | [#56](https://github.com/benson94879453/rich-war-online/issues/56) | P1 | Docs | Done | sprint5 | Record event/building loop planning baseline | Sprint5 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-038 | [#57](https://github.com/benson94879453/rich-war-online/issues/57) | P1 | Tech Debt | Done | sprint5 | Add EventDefinition and EventService baseline | A small event service can resolve one fixed money event through the existing effect/result path without adding full decks or cards. |
| PB-039 | [#58](https://github.com/benson94879453/rich-war-online/issues/58) | P1 | Story | Done | sprint5 | Bind prototype event resolution to active tile landings | One selected active-map event-like tile resolves through the event service while existing property, rent, route, and money tile behavior stays stable. |
| PB-040 | [#61](https://github.com/benson94879453/rich-war-online/issues/61) | P2 | Test | Done | sprint5 | Add event landing scenario smoke coverage | A headless scenario smoke path proves the selected event landing resolves and round-trips through snapshot state. |
| PB-041 | [#59](https://github.com/benson94879453/rich-war-online/issues/59) | P1 | Review | Done | sprint5 | Record event/building loop acceptance review | Sprint5 evidence is summarized with a clear recommendation for moving from first event slice toward buildings or card timing windows. |
| PB-042 | [#68](https://github.com/benson94879453/rich-war-online/issues/68) | P1 | Docs | Done | sprint6 | Plan GameManager decomposition baseline | Sprint6 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-043 | [#69](https://github.com/benson94879453/rich-war-online/issues/69) | P1 | Tech Debt | Done | sprint6 | Extract snapshot summary tracking from GameManager | Snapshot UI summary state and formatting are delegated while snapshot payload compatibility remains intact. |
| PB-044 | [#70](https://github.com/benson94879453/rich-war-online/issues/70) | P1 | Tech Debt | Done | sprint6 | Extract property purchase and rent resolution boundary | Current Buy, Skip, insufficient-funds, purchase offer, and rent behavior live behind a focused boundary without behavior changes. |
| PB-045 | [#71](https://github.com/benson94879453/rich-war-online/issues/71) | P1 | Tech Debt | Done | sprint6 | Extract landing resolution orchestration boundary | Landing sequencing delegates through a focused resolver while property, rent, money tile, and `starq_chance` behavior remains stable. |
| PB-046 | [#72](https://github.com/benson94879453/rich-war-online/issues/72) | P1 | Review | Done | sprint6 | Record GameManager decomposition acceptance review | Sprint6 evidence is summarized with remaining risks and a clear recommendation for the next gameplay-system slice. |
| PB-047 | [#81](https://github.com/benson94879453/rich-war-online/issues/81) | P1 | Docs | Done | sprint7 | Plan v0.4 card intervention window baseline | Sprint7 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-048 | [#82](https://github.com/benson94879453/rich-war-online/issues/82) | P1 | Tech Debt | Done | sprint7 | Add CardDefinition and CardService baseline | One prototype card definition can be validated and resolved through a focused service boundary. |
| PB-049 | [#83](https://github.com/benson94879453/rich-war-online/issues/83) | P1 | Tech Debt | Done | sprint7 | Activate card state snapshot helpers | Prototype hand, discard, and pending intervention state can be represented and round-tripped without changing snapshot keys. |
| PB-050 | [#84](https://github.com/benson94879453/rich-war-online/issues/84) | P1 | Tech Debt | Done | sprint7 | Add Host-authoritative card action intent envelope | Card-play action payloads can be accepted or rejected through a narrow Host-authoritative path without regressing existing actions. |
| PB-051 | [#85](https://github.com/benson94879453/rich-war-online/issues/85) | P1 | Story | Done | sprint7 | Implement prototype pre-roll intervention card | One fixed card can resolve in a valid pre-roll window, apply its effect, consume/discard the card, and let turn flow continue. |
| PB-052 | [#86](https://github.com/benson94879453/rich-war-online/issues/86) | P2 | Test | Done | sprint7 | Add card window scenario smoke coverage | A headless scenario proves the valid card-window path and key rejection or continuation behavior. |
| PB-053 | [#87](https://github.com/benson94879453/rich-war-online/issues/87) | P1 | Review | Done | sprint7 | Record v0.4 card window baseline acceptance review | Sprint7 evidence is summarized with remaining risks and a clear recommendation for the next card-system slice. |
| PB-054 | [#96](https://github.com/benson94879453/rich-war-online/issues/96) | P1 | Docs | Done | sprint8 | Plan visible card playtest baseline | Sprint8 plan, scope, out-of-scope items, UI gate, issue order, validation expectations, and branch strategy are documented. |
| PB-055 | [#97](https://github.com/benson94879453/rich-war-online/issues/97) | P1 | Docs | Done | sprint8 | Define card test asset pipeline guide | Standard Godot asset paths, naming, ratio guidance, and fallback behavior are documented. |
| PB-056 | [#98](https://github.com/benson94879453/rich-war-online/issues/98) | P1 | Tech Debt | Done | sprint8 | Bind prototype card metadata to test asset reference | Prototype card metadata can support a visible card surface with optional test art and safe fallback behavior. |
| PB-057 | [#99](https://github.com/benson94879453/rich-war-online/issues/99) | P1 | Spec | Done | sprint8 | Draft visible card UI wireframe and implementation spec | Bottom-hand UI, disabled/active states, inspect behavior, tunable parameters, and user-confirmation gate are documented. |
| PB-058 | [#100](https://github.com/benson94879453/rich-war-online/issues/100) | P1 | Story | Done | sprint8 | Implement minimal active-scene card hand UI | After #99 confirmation, the prototype card can be seen, inspected, played during pre-roll, or skipped by rolling. |
| PB-059 | [#101](https://github.com/benson94879453/rich-war-online/issues/101) | P1 | QA | Done | sprint8 | Add visible card playtest manual checklist | Manual checks cover inactive/active hand states, inspect, card play, roll skip, and Host/Client pending status. |
| PB-060 | [#102](https://github.com/benson94879453/rich-war-online/issues/102) | P1 | Review | In Review | sprint8 | Record visible card playtest acceptance review | Sprint8 evidence is summarized with manual QA status, remaining risks, and a merge recommendation. |

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
