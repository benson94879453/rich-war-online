# Sprint5 Review

Review date: 2026-06-29

## Sprint Branch

`codex/sprint5-event-building-loop`

## Sprint Goal

Start `v0.3-event-building-loop` with the smallest Host-authoritative event slice: introduce a reusable event-resolution layer, bind one active-map event-like landing path to it, and prove the path with headless scenario smoke coverage.

## Completed Issues

| Issue | PR | Status | Outcome |
| --- | --- | --- | --- |
| [#56](https://github.com/benson94879453/rich-war-online/issues/56) | [#62](https://github.com/benson94879453/rich-war-online/pull/62) | Done | Recorded Sprint5 plan, scope, out-of-scope items, validation expectations, and branch strategy. |
| [#57](https://github.com/benson94879453/rich-war-online/issues/57) | [#63](https://github.com/benson94879453/rich-war-online/pull/63) | Done | Added `EventDefinition` and `EventService` baseline for a deterministic prototype money event. |
| [#58](https://github.com/benson94879453/rich-war-online/issues/58) | [#64](https://github.com/benson94879453/rich-war-online/pull/64) | Done | Bound active-map `starq_chance` landings to `EventService` through the existing landing pipeline. |
| [#61](https://github.com/benson94879453/rich-war-online/issues/61) | [#65](https://github.com/benson94879453/rich-war-online/pull/65) | Done | Added deterministic event landing scenario smoke coverage with snapshot round-trip checks. |
| [#59](https://github.com/benson94879453/rich-war-online/issues/59) | This PR | Done | Recorded Sprint5 acceptance evidence and merge recommendation. |

## Implemented Changes

- `EventDefinition` represents a minimal event payload with id, display name, effect id, and money delta.
- `EventService` resolves one deterministic prototype money event and can create a tile-backed event for `starq_chance`.
- `GameManager` routes supported event-like tile landings through `EventService` while preserving existing `TILE_EFFECT_RESOLVED` summary behavior.
- `tools/smoke_event_landing_binding.gd` validates direct active-map event landing binding.
- `tools/scenarios/scenario_event_landing_pipeline.gd` validates a full action-pipeline event landing through `ActionDispatcher.ACTION_ROLL`, turn completion, pending-state draining, and `GameState.from_dict()` snapshot round-trip.
- `tools/scenarios/README.md` records how later building, card, or intervention-window scenarios should extend the pattern.

## Not Completed

- No full event deck or random event table.
- No card hand, draw, discard, or counter-card system.
- No timed intervention windows.
- No special-building ownership, activation, or placement loop.
- No stock market, lottery, casino, or production balance pass.
- No new manual active-scene or Host/Client QA run was executed during this closeout.

## Automated Test Summary

All commands were run from the repository root on 2026-06-29.

| Check | Command | Result |
| --- | --- | --- |
| Whitespace diff check | `git diff --check` | Pass, exit code 0 |
| Event landing scenario | `godot --headless --path . --script res://tools/scenarios/scenario_event_landing_pipeline.gd` | Pass, exit code 0 |
| Local 10-roll scenario | `godot --headless --path . --script res://tools/scenarios/scenario_10_roll_local_action_pipeline.gd` | Pass, exit code 0 |
| Event service smoke | `godot --headless --path . --script res://tools/smoke_event_service.gd` | Pass, exit code 0 |
| Event landing binding smoke | `godot --headless --path . --script res://tools/smoke_event_landing_binding.gd` | Pass, exit code 0 |
| Effect service smoke | `godot --headless --path . --script res://tools/smoke_effect_service.gd` | Pass, exit code 0 |
| GameState snapshot smoke | `godot --headless --path . --script res://tools/smoke_game_state_snapshot.gd` | Pass, exit code 0 |
| GameState reserved defaults smoke | `godot --headless --path . --script res://tools/smoke_game_state_reserved_defaults.gd` | Pass, exit code 0 |
| Active map validation smoke | `godot --headless --path . --script res://tools/smoke_map_validation.gd` | Pass, exit code 0 |
| Action dispatcher smoke | `godot --headless --path . --script res://tools/smoke_action_dispatcher.gd` | Pass, exit code 0 |
| Reconnect status/snapshot smoke | `godot --headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd` | Pass, exit code 0 |

## Manual QA

No manual QA pass was executed during Sprint5 closeout. Manual active-scene landing and Host/Client snapshot-sync checks remain deferred until a later slice exposes more visible event, building, card, or intervention-window behavior.

## Known Risks

- `starq_chance` is still a prototype active-map effect id, not final event content.
- Event resolution is deterministic and narrow; random event decks remain intentionally out of scope.
- `GameManager` still owns landing sequencing and should be split in a future sprint before larger gameplay expansion.
- Host-authoritative behavior is covered structurally by the existing local action pipeline; no new networked event-specific manual QA was run.
- Future card/intervention windows must extend the reserved snapshot and turn-phase fields without changing their current defaults.

## Recommended Merge Decision

Ready after this acceptance review PR is merged into `codex/sprint5-event-building-loop`.

The Sprint5 branch is ready for a final PR into `main` because the sprint goal was met, issue-sized PRs are merged, automated validation passed, manual QA gaps are explicit, and deferred larger systems remain outside scope.

## Next Recommendation

Move to Sprint6 with a `GameManager` decomposition focus before adding larger special-building or card timing-window behavior. The next implementation slice should reduce landing/action/effect ownership inside `GameManager` so future events, buildings, cards, and intervention windows have clearer service boundaries.
