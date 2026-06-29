# Sprint4

Start date: 2026-06-28
Closeout date: 2026-06-29

## Sprint Goal

Establish the `v0.3-event-building-loop` foundation by separating gameplay action submission, effect resolution, turn phase vocabulary, snapshot reserved fields, and scenario validation before adding full events, special buildings, or cards.

The sprint should reduce pressure on `GameManager` and `NetworkManager` without attempting a full architecture rewrite.

## Sprint Integration Branch

Use `codex/sprint4-action-effect-foundation` as the Sprint4 integration branch.

Issue workflow:

1. Branch each Sprint4 issue from `codex/sprint4-action-effect-foundation`.
2. Open each issue PR with base branch `codex/sprint4-action-effect-foundation`.
3. Merge only issue-sized PRs into the Sprint4 branch during the sprint.
4. Open one final Sprint4 PR from `codex/sprint4-action-effect-foundation` into `main` after Sprint4 acceptance is complete.

## Sprint Scope

- Record the Sprint4 planning baseline and issue order.
- Introduce an `ActionDispatcher` baseline so gameplay intents have one Host-authoritative submission path.
- Introduce an `EffectService` baseline so tile, event, card, status, and building effects can later share one resolution path.
- Expand `TurnSystem` phase vocabulary toward an explicit finite-state-machine baseline.
- Reserve multiplayer snapshot fields for future cards, decks, statuses, pending intervention windows, and game-over state.
- Add a minimal scenario smoke baseline so future validation can cover complete flows instead of only isolated smoke checks.

## Out Of Scope

- No full card system.
- No full event deck.
- No full special building implementation.
- No stock market system.
- No broad `StarQGame.gd` presenter/animator decomposition.
- No full multiplayer simulation framework.
- No UI redesign beyond the minimum needed to keep existing flows working.

## Sprint Backlog

| Backlog ID | Issue | Status | Work item | Acceptance |
| --- | --- | --- | --- | --- |
| PB-031 | [#42](https://github.com/benson94879453/rich-war-online/issues/42) | Done | Record action/effect foundation planning baseline | Sprint4 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-032 | [#43](https://github.com/benson94879453/rich-war-online/issues/43) | Done | Introduce ActionDispatcher baseline | Existing roll, route choice, Buy, and Skip actions can flow through a single dispatch entry point while Host authority remains intact. |
| PB-033 | [#44](https://github.com/benson94879453/rich-war-online/issues/44) | Done | Introduce EffectService baseline | Current tile money effects keep working through a shared effect service entry point that can later support cards, events, statuses, and buildings. |
| PB-034 | [#45](https://github.com/benson94879453/rich-war-online/issues/45) | Done | Expand TurnSystem FSM baseline | Turn phase vocabulary supports explicit future intervention windows while existing movement, route, property, and rent flows remain stable. |
| PB-035 | [#46](https://github.com/benson94879453/rich-war-online/issues/46) | Done | Add GameState snapshot reserved fields | Future hand, deck, discard, status, pending-intervention, and game-over fields have stable defaults and survive snapshot round-trip. |
| PB-036 | [#47](https://github.com/benson94879453/rich-war-online/issues/47) | Done | Add scenario smoke baseline | At least one narrow scenario smoke path exists and is documented as the extension point for later event/building/card scenarios. |

## Recommended Order

1. Planning baseline.
2. `ActionDispatcher` baseline.
3. `EffectService` baseline.
4. `TurnSystem` FSM baseline.
5. `GameState` snapshot reserved fields.
6. Scenario smoke baseline.

This order keeps the riskiest dependency first: actions must have a narrow Host-authoritative entry point before future event, building, stock, or card actions expand the gameplay surface.

## Acceptance Criteria

- Sprint4 planning is committed and linked to issue #42.
- Existing local and networked core actions remain stable after introducing the dispatcher and effect service baselines.
- `NetworkManager` remains focused on peer/RPC/snapshot transport rather than gameplay rules.
- `GameManager` remains behaviorally compatible with existing flows while new service boundaries are introduced incrementally.
- Turn phase names are explicit enough to support a future pre-roll intervention window.
- Reserved snapshot fields have stable defaults and round-trip correctly.
- Scenario smoke documentation or scripts identify how future event/building/card scenario checks should be added.
- Any failed automated or manual check is recorded as a named blocker or explicitly deferred risk.

## Validation Expectations

Minimum automated checks before Sprint4 closeout:

- `git diff --check`
- Existing GameState snapshot smoke check.
- Existing reconnect smoke checks relevant to snapshot and seat restoration.
- Existing map validation smoke check if movement or tile effect behavior changes.
- New scenario smoke command if implemented during Sprint4.

Manual checks should be recorded only if actually executed:

- Local active scene turn flow.
- Host/Client roll, route choice, Buy, Skip, rent, snapshot join, or reconnect where touched by the issue.

## Known Risks

- `GameManager` already owns many responsibilities; Sprint4 should reduce coupling incrementally instead of forcing a large service split.
- `NetworkManager` action routing changes can regress Host-authoritative rejection behavior if dispatch boundaries are unclear.
- `TurnSystem` phase expansion can create stale pending-action states if existing route and property decision flows are moved too aggressively.
- Snapshot reserved fields must remain inert until their owning systems exist.
- Scenario smoke scripts may expose Godot headless limitations; if blocked, document the manual fallback and keep the script skeleton small.

## Review Notes

Sprint4 is an architecture-foundation sprint, not a feature-expansion sprint. The expected output is a safer path into `v0.3-event-building-loop`, where a small event or special-building slice can later be implemented without pushing more game rules directly into `GameManager`, `NetworkManager`, or scene UI code.

Closeout evidence is recorded in `docs/sprints/sprint4_review.md`.
