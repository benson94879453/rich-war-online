# Sprint4 Review

Review date: 2026-06-29

## Sprint Branch

`codex/sprint4-action-effect-foundation`

## Sprint Goal

Establish the `v0.3-event-building-loop` foundation by separating action submission, effect resolution, turn phase vocabulary, snapshot reserved fields, and scenario validation before implementing full events, buildings, cards, or stock-market systems.

## Completed Issues

| Issue | PR | Status | Result |
| --- | --- | --- | --- |
| [#42](https://github.com/benson94879453/rich-war-online/issues/42) | [#48](https://github.com/benson94879453/rich-war-online/pull/48) | Done | Sprint4 plan, scope, branch strategy, issue order, risks, and validation expectations were documented. |
| [#43](https://github.com/benson94879453/rich-war-online/issues/43) | [#49](https://github.com/benson94879453/rich-war-online/pull/49) | Done | `ActionDispatcher` now provides a single Host-authoritative gameplay intent entry point for roll, grid route choice, Buy, and Skip. |
| [#44](https://github.com/benson94879453/rich-war-online/issues/44) | [#50](https://github.com/benson94879453/rich-war-online/pull/50) | Done | `EffectService` now resolves current tile money effects through a reusable effect path. |
| [#45](https://github.com/benson94879453/rich-war-online/issues/45) | [#51](https://github.com/benson94879453/rich-war-online/pull/51) | Done | `TurnSystem` now has explicit phase vocabulary for future pre-roll, movement, landing, intervention, turn-end, and game-over flows while preserving legacy phases. |
| [#46](https://github.com/benson94879453/rich-war-online/issues/46) | [#52](https://github.com/benson94879453/rich-war-online/pull/52) | Done | `GameState` snapshots now reserve inert fields for hands, decks, discards, statuses, pending interventions, game-over state, winner, and round limit. |
| [#47](https://github.com/benson94879453/rich-war-online/issues/47) | [#53](https://github.com/benson94879453/rich-war-online/pull/53) | Done | A 10-roll local action pipeline scenario smoke script now validates dispatcher, grid movement, property decisions, turn draining, and snapshot round-trip. |

## Acceptance Evidence

Automated validation was executed on 2026-06-29 with Steam Godot `4.6.3.stable`.

- `git diff --check`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/scenarios/scenario_10_roll_local_action_pipeline.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_action_dispatcher.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_effect_service.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_turn_system_fsm.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_game_state_reserved_defaults.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_game_state_snapshot.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_map_validation.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_reconnect_token_lifecycle.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_reconnect_seat_reservation.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_reconnect_reserved_seat_reassign.gd`: PASS, exit code 0.
- `godot --headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd`: PASS, exit code 0.

## Closeout Fixes

Final closeout validation exposed that several new Sprint4 scripts relied on local Godot editor/global-class cache state. The closeout pass removed that dependency by using explicit `preload()` for new Sprint4 classes and runtime singleton lookup for headless smoke scripts.

This affects validation stability only; it does not add new gameplay scope.

## Manual QA

No new manual QA pass was executed during Sprint4 closeout. Sprint4 is accepted on automated structural and scenario smoke evidence. Broader manual networked play remains a future acceptance task when the next event/building/card slice touches visible gameplay.

## Known Risks

- `GameManager` still owns core gameplay sequencing and remains a decomposition target.
- `ActionDispatcher` is intentionally narrow and does not yet cover future event, card, building, stock, or intervention actions.
- `EffectService` currently handles money tile effects only.
- `TurnSystem` phase vocabulary exists, but full intervention-window orchestration is not implemented.
- Reserved snapshot fields are inert until their owning systems are added.

## Recommended Merge Decision

Ready to open the final Sprint4 PR from `codex/sprint4-action-effect-foundation` to `main` after `git diff --check` passes.

The final PR should close #42, #43, #44, #45, #46, and #47 when merged into `main`.
