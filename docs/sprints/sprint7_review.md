# Sprint7 Review

Review date: 2026-06-30

## Sprint Branch

`codex/sprint7-card-window-baseline`

## Sprint Goal

Establish the first `v0.4-card-window-loop` baseline by proving one narrow Host-authoritative card intervention window.

Sprint7 intentionally did not implement a full card game. The sprint output is evidence that one deterministic prototype card can exist in state, be validated through a Host-authoritative action path, resolve through the existing effect boundary, consume/discard state, and leave the normal turn loop stable.

## Completed Issues

| Issue | PR | Status | Result |
| --- | --- | --- | --- |
| [#81](https://github.com/benson94879453/rich-war-online/issues/81) Plan v0.4 card intervention window baseline | [#88](https://github.com/benson94879453/rich-war-online/pull/88) | Done | Sprint7 goal, scope, out-of-scope items, issue order, branch strategy, validation expectations, and risks are documented. |
| [#82](https://github.com/benson94879453/rich-war-online/issues/82) Add CardDefinition and CardService baseline | [#89](https://github.com/benson94879453/rich-war-online/pull/89) | Done | `CardDefinition` and `CardService` define and validate one deterministic prototype pre-roll money card through the existing `EffectService` boundary. |
| [#83](https://github.com/benson94879453/rich-war-online/issues/83) Activate card state snapshot helpers | [#90](https://github.com/benson94879453/rich-war-online/pull/90) | Done | `GameState` helper methods cover prototype hands, deck card lists, discard piles, and pending intervention metadata while preserving existing snapshot keys. |
| [#84](https://github.com/benson94879453/rich-war-online/issues/84) Add Host-authoritative card action intent envelope | [#91](https://github.com/benson94879453/rich-war-online/pull/91) | Done | `play_card` action validation and `NetworkManager.submit_play_card(...)` provide a narrow Host-authoritative intent envelope with clear rejection reasons. |
| [#85](https://github.com/benson94879453/rich-war-online/issues/85) Implement prototype pre-roll intervention card | [#92](https://github.com/benson94879453/rich-war-online/pull/92) | Done | One deterministic pre-roll card can be represented, played, resolved through `CardService`, consumed from hand, moved to discard, and followed by normal roll flow. |
| [#86](https://github.com/benson94879453/rich-war-online/issues/86) Add card window scenario smoke coverage | [#93](https://github.com/benson94879453/rich-war-online/pull/93) | Done | `scenario_card_window_pipeline.gd` protects the action-pipeline path for invalid actor rejection, valid card play, effect state, consume/discard, snapshot round-trip, and roll continuation. |
| [#87](https://github.com/benson94879453/rich-war-online/issues/87) Record v0.4 card window baseline acceptance review | This PR | Done | Sprint7 evidence, manual QA status, risks, and merge recommendation are recorded. |

## Implemented Changes

- Added `CardDefinition` and `CardService` as the first card data/service boundary.
- Added a deterministic prototype card id: `prototype_pre_roll_grant`.
- Added `GameState` helpers for card hands, deck cards, discard piles, and pending intervention state.
- Added `ActionDispatcher.ACTION_PLAY_CARD` and minimal payload keys: `player_id`, `card_id`, `window_id`, and optional `target_player_id`.
- Added `NetworkManager.submit_play_card(...)` as the narrow card intent envelope.
- Added one prototype pre-roll window represented by `GameState.pending_intervention` while preserving roll-ready turn flow.
- Added successful card resolution through `CardService` and `EffectService`.
- Added consume/discard behavior for the prototype card after successful play.
- Added focused smoke checks and a scenario-level card-window pipeline check.
- Documented card smoke and scenario commands in README surfaces.

## Not Completed

- No full card deck, random draw, shuffle, or draw timing system.
- No multiple-card set or balance pass.
- No priority stack, timer, counter-card chain, or multi-player response ordering.
- No production card UI, card art, or final UX.
- No production account-backed card/reconnect identity.
- No broad `NetworkManager`, `StarQGame`, or `GameManager` rewrite.
- No manual active-scene or Host/Client QA pass was executed during Sprint7 closeout.

## Validation Evidence

Issue PR validation:

| PR | Validation |
| --- | --- |
| [#88](https://github.com/benson94879453/rich-war-online/pull/88) | `git diff --check` pass; `git diff --cached --check` pass before commit. |
| [#89](https://github.com/benson94879453/rich-war-online/pull/89) | `git diff --check` pass; `git diff --cached --check` pass before commit; `smoke_card_service.gd`, `smoke_effect_service.gd`, `smoke_game_state_reserved_defaults.gd`, and `smoke_event_service.gd` exit 0. |
| [#90](https://github.com/benson94879453/rich-war-online/pull/90) | `git diff --check` pass; `git diff --cached --check` pass before commit; `smoke_game_state_card_state.gd`, `smoke_game_state_reserved_defaults.gd`, `smoke_game_state_snapshot.gd`, `smoke_reconnect_status_snapshot.gd`, and `smoke_card_service.gd` exit 0. |
| [#91](https://github.com/benson94879453/rich-war-online/pull/91) | `git diff --check` pass; `git diff --cached --check` pass before commit; `smoke_action_dispatcher.gd` and `smoke_reconnect_status_snapshot.gd` exit 0. |
| [#92](https://github.com/benson94879453/rich-war-online/pull/92) | `git diff --check` pass; `git diff --cached --check` pass before commit; `smoke_prototype_pre_roll_card.gd`, `smoke_action_dispatcher.gd`, `smoke_game_state_snapshot.gd`, `scenario_10_roll_local_action_pipeline.gd`, `scenario_event_landing_pipeline.gd`, `smoke_card_service.gd`, and `smoke_reconnect_status_snapshot.gd` exit 0. |
| [#93](https://github.com/benson94879453/rich-war-online/pull/93) | `git diff --check` pass; `git diff --cached --check` pass before commit; `scenario_card_window_pipeline.gd`, `scenario_10_roll_local_action_pipeline.gd`, and `scenario_event_landing_pipeline.gd` exit 0. |

Sprint7 closeout validation:

| Command | Result |
| --- | --- |
| `git diff --check` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/scenarios/scenario_card_window_pipeline.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/scenarios/scenario_10_roll_local_action_pipeline.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/scenarios/scenario_event_landing_pipeline.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_prototype_pre_roll_card.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_action_dispatcher.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_card_service.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_game_state_card_state.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_game_state_snapshot.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_game_state_reserved_defaults.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_effect_service.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_event_service.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_map_validation.gd` | Pass, exit code 0. |

## Manual QA

No manual QA pass was executed during Sprint7 closeout.

Manual active-scene checks for an unused pre-roll window, visible prototype card play, and Host/Client card intent behavior remain pending. They are not marked passed by this review because they were not manually run.

## Remaining Risks

- The card window is deterministic and prototype-only. It proves one timing slice, not a production card system.
- `GameManager` now owns temporary prototype card seeding and pre-roll window preparation. This should be extracted or redesigned before a larger card system.
- `ActionDispatcher` and `NetworkManager` support a narrow card intent envelope, but no production Host/Client card UI acceptance was run.
- `TurnSystem` has intervention vocabulary, but Sprint7 keeps the prototype pre-roll window roll-ready instead of implementing full intervention phases, timeout, priority, or pass behavior.
- Snapshot compatibility is protected by smoke checks, but future deck/draw/discard expansion must preserve existing card-state keys and defaults.
- GitHub issue auto-close keywords in issue PRs may not close #81-#87 until the sprint branch is merged to `main`, because issue PRs target the sprint integration branch.

## Recommended Merge Decision

Ready to open the final Sprint7 PR from `codex/sprint7-card-window-baseline` to `main` after this #87 review PR is merged into the Sprint7 branch.

Sprint7 met its goal: the project now has a documented, validated, Host-authoritative prototype card intervention window baseline. The next work should decide whether to expose a minimal manual UI path for the prototype card or first extract the temporary card-window orchestration out of `GameManager`.

## Merge Back To Main Checklist

- [x] Sprint branch is up to date through #93.
- [x] Sprint issue PRs #88 through #93 are merged into `codex/sprint7-card-window-baseline`.
- [ ] #87 review PR is merged into `codex/sprint7-card-window-baseline`.
- [x] Closeout automated checks pass on the review PR branch.
- [x] Manual QA is honestly recorded as not run for Sprint7 closeout.
- [x] Remaining risks are documented.
- [ ] Open final PR from `codex/sprint7-card-window-baseline` to `main`.
