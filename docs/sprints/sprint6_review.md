# Sprint6 Review

Review date: 2026-06-29

## Sprint Branch

`codex/sprint6-game-manager-decomposition`

## Sprint Goal

Reduce `GameManager` god-object risk before expanding special buildings, full event decks, cards, or intervention windows.

Sprint6 was intentionally behavior-preserving. It did not add player-facing gameplay, balance changes, card systems, special-building activation, event decks, stock market, lottery, casino, movement rewrites, or UI rewrites.

## Completed Issues

| Issue | PR | Status | Result |
| --- | --- | --- | --- |
| [#68](https://github.com/benson94879453/rich-war-online/issues/68) Plan GameManager decomposition baseline | [#73](https://github.com/benson94879453/rich-war-online/pull/73) | Done | Sprint6 goal, scope, issue order, branch strategy, validation expectations, and out-of-scope items are documented. |
| [#69](https://github.com/benson94879453/rich-war-online/issues/69) Extract snapshot summary tracking from GameManager | [#74](https://github.com/benson94879453/rich-war-online/pull/74) | Done | `SnapshotSummaryTracker` owns snapshot UI summary state, restore, formatting, and log limiting while `GameManager` keeps compatible snapshot constants and payload shape. |
| [#70](https://github.com/benson94879453/rich-war-online/issues/70) Extract property purchase and rent resolution boundary | [#75](https://github.com/benson94879453/rich-war-online/pull/75) | Done | `PropertyResolutionService` owns purchase offer, Buy, Skip, insufficient-funds, and rent rules while `GameManager` keeps public action methods and turn orchestration. |
| [#71](https://github.com/benson94879453/rich-war-online/issues/71) Extract landing resolution orchestration boundary | [#76](https://github.com/benson94879453/rich-war-online/pull/76) | Done | `LandingResolutionService` owns board/grid landing sequencing, property offer/rent routing, tile effects, and `starq_chance` effect routing while `GameManager` keeps event emission and turn completion orchestration. |
| [#72](https://github.com/benson94879453/rich-war-online/issues/72) Record GameManager decomposition acceptance review | This PR | Done | Sprint6 evidence, remaining risks, and merge recommendation are recorded. |

## Implemented Changes

- Added `SnapshotSummaryTracker` and moved UI summary event-to-text state out of `GameManager`.
- Added `PropertyResolutionService` and moved property purchase/rent rule decisions out of direct `GameManager` methods.
- Added `LandingResolutionService` and moved landing sequencing decisions out of direct `GameManager` landing paths.
- Preserved public `GameManager` action entry points for Roll, route choice, Buy, and Skip.
- Preserved snapshot keys for `turn_phase` and `ui_summary`.
- Preserved event payload compatibility for dice, landing, property offer/purchase/skip, rent, and tile-effect summaries.

## Not Completed

- No additional `GameManager` split was attempted beyond the scoped snapshot, property/rent, and landing boundaries.
- Movement continuation remains in `GameManager`.
- Public action entry points remain in `GameManager`.
- Event emission through `EventBus` remains in `GameManager`.
- Full card, event deck, intervention-window, and special-building behavior remain future work.

## Validation Evidence

Issue PR validation:

| PR | Validation |
| --- | --- |
| [#73](https://github.com/benson94879453/rich-war-online/pull/73) | `git diff --check` pass; `git diff --cached --check` pass before commit. |
| [#74](https://github.com/benson94879453/rich-war-online/pull/74) | `git diff --check` pass; `git diff --cached --check` pass before commit; `smoke_snapshot_summary_tracker.gd`, `smoke_game_state_snapshot.gd`, `smoke_game_state_reserved_defaults.gd`, `smoke_reconnect_status_snapshot.gd`, `scenario_10_roll_local_action_pipeline.gd`, `scenario_event_landing_pipeline.gd`, and `smoke_event_landing_binding.gd` exit 0. |
| [#75](https://github.com/benson94879453/rich-war-online/pull/75) | `git diff --check` pass; `git diff --cached --check` pass before commit; `smoke_property_resolution_service.gd`, `scenario_10_roll_local_action_pipeline.gd`, `scenario_event_landing_pipeline.gd`, `smoke_action_dispatcher.gd`, `smoke_game_state_snapshot.gd`, and `smoke_snapshot_summary_tracker.gd` exit 0. |
| [#76](https://github.com/benson94879453/rich-war-online/pull/76) | `git diff --check` pass; `git diff --cached --check` pass before commit; `scenario_event_landing_pipeline.gd`, `scenario_10_roll_local_action_pipeline.gd`, `smoke_event_landing_binding.gd`, `smoke_event_service.gd`, `smoke_effect_service.gd`, `smoke_game_state_snapshot.gd`, `smoke_property_resolution_service.gd`, `smoke_action_dispatcher.gd`, and `smoke_snapshot_summary_tracker.gd` exit 0. |

Sprint6 closeout validation:

| Command | Result |
| --- | --- |
| `git diff --check` | Pass. |
| `godot --headless --path . --script res://tools/scenarios/scenario_event_landing_pipeline.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/scenarios/scenario_10_roll_local_action_pipeline.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_event_landing_binding.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_event_service.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_effect_service.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_action_dispatcher.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_game_state_snapshot.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_game_state_reserved_defaults.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_map_validation.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_reconnect_seat_reservation.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_reconnect_reserved_seat_reassign.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_reconnect_token_lifecycle.gd` | Pass, exit code 0. |

## Manual QA

No new manual QA pass was executed during Sprint6 closeout.

Manual active-scene checks for local Roll, route choice, Buy, Skip, rent, and `starq_chance` remain available in `docs/MANUAL_TEST_CHECKLIST.md`. They are not marked passed by this review because they were not manually re-run for Sprint6 closeout.

## Remaining Risks

- `GameManager` still owns movement continuation, public action entry points, turn-system phase changes, RNG, bootstrap/restore wiring, and event emission.
- `LandingResolutionService` is a data-returning boundary, not a fully independent domain engine. It still depends on injected property/effect/event services and expects `GameManager` to apply turn phase changes.
- Network Host/Client manual acceptance was not re-run after Sprint6 refactors. Automated snapshot, event landing, reconnect, and scenario checks reduce risk but do not replace a two-window manual pass.
- GitHub issue auto-close keywords in issue PRs may not close #68-#72 until the sprint branch is merged to `main`, because the issue PRs target the sprint integration branch.

## Recommended Merge Decision

Ready to open the final Sprint6 PR from `codex/sprint6-game-manager-decomposition` to `main` after this #72 review PR is merged into the Sprint6 branch.

The sprint met its behavior-preserving decomposition goal. The next gameplay-system slice can build on the new service boundaries, but larger card or intervention-window work should still start with a narrow spec and validation path.

## Merge Back To Main Checklist

- [x] Sprint branch is up to date through #76.
- [x] Sprint issue PRs are merged into `codex/sprint6-game-manager-decomposition`.
- [ ] #72 review PR is merged into `codex/sprint6-game-manager-decomposition`.
- [x] Closeout automated checks pass on the review PR branch.
- [x] Manual QA is honestly recorded as not re-run for Sprint6 closeout.
- [x] Remaining risks are documented.
- [ ] Open final PR from `codex/sprint6-game-manager-decomposition` to `main`.
