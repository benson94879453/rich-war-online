# Map Validation Smoke Plan

Baseline date: 2026-06-26

## Purpose

This document defines the smallest useful headless smoke script for validating the active board resource before map data is treated as baseline-ready.

Implementation is tracked by [issue #16](https://github.com/benson94879453/rich-war-online/issues/16). This plan intentionally does not introduce a broader test framework.

## Proposed Script

| Item | Decision |
| --- | --- |
| Script path | `res://tools/smoke_map_validation.gd` |
| Runtime base | Godot `SceneTree`, matching `res://tools/smoke_game_state_snapshot.gd` |
| Default board input | `res://resources/maps/starq_board.tres` |
| CLI arguments | None for v1; keep the active resource path as a script constant |
| Implementation issue | [#16](https://github.com/benson94879453/rich-war-online/issues/16) |

Planned command:

```bash
godot --headless --path . --script res://tools/smoke_map_validation.gd
```

If `godot` is not on PATH, run the same command with the configured Godot 4.6.x executable.

## Inputs

The v1 smoke script should use fixed inputs so the first implementation stays narrow:

- `ACTIVE_BOARD_RESOURCE_PATH := "res://resources/maps/starq_board.tres"`
- `EXPECTED_PLAYER_IDS := [0, 1, 2, 3]`
- `EXPECTED_ACTIVE_SCENE := "res://scenes/StarQGame.tscn"` as documentation output only

The script should not accept a broad map file parameter yet. Generalized map validation can wait until the importer or original-map authoring path exists.

## Helper-Backed Checks

The script should load `ACTIVE_BOARD_RESOURCE_PATH`, cast it to `BoardData`, and fail if the cast does not succeed.

Call these existing helpers and treat every returned message as a failure:

| Helper | Failure meaning |
| --- | --- |
| `BoardData.get_player_spawn_validation_messages()` | Invalid spawn references, duplicate player ids, invalid grid spawns, or invalid initial directions. |
| `BoardData.get_map_grid_validation_messages()` | Invalid grid dimensions, wrong cell count, junction direction errors, or missing walkable-node directions. |
| `BoardData.get_source_node_validation_messages()` | More than one tile maps to the same source node. |
| `BoardData.get_placement_validation_messages()` | Missing or duplicate tile placement references. |
| `BoardData.get_property_decoration_validation_messages()` | Property marker references an unknown tile. |
| `BoardData.get_connection_validation_messages()` | Classic tile-to-tile connection errors when connections are present. |

The script should not call `BoardData.has_expected_tile_count()` as a pass/fail gate because the active grid map has 160 tiles while `BoardData.EXPECTED_TILE_COUNT` is the legacy 40-tile loop value.

## Extra Active-Map Checks

The helper methods cover the low-level resource shape, but the v1 script should add these active-map assumptions:

- Board resource has a non-null `BoardMapGridData`.
- Expected player ids `0`, `1`, `2`, and `3` each have exactly one spawn.
- Every expected player spawn uses a grid position, not only a fallback tile index.
- Each expected player spawn can produce at least one available movement direction from its initial state.
- Every tile with `source_node_id >= 0` resolves to a landing node in the active grid.
- Every property decoration references a `PROPERTY` tile unless the script has an explicit documented exception.
- Every junction direction in `junction_directions_by_node_id` leads to at least one route position through `MapGridNavigator.get_route_positions()`.

These checks are intentionally structural. They do not replace manual route-choice or visual marker validation from `docs/MAP_VALIDATION_CHECKLIST.md`.

## Pass / Fail Behavior

The script should collect all failures before exiting so a broken map produces one actionable report.

Pass behavior:

- Print the active board resource path.
- Print the number of helper-backed checks run.
- Print `PASS: Map validation smoke check`.
- Exit with code `0`.

Fail behavior:

- Print or push one error per failure.
- Include the failing helper name or check name in each message.
- Include node id, tile index, or player id when available.
- Print `FAIL: Map validation smoke check had N failure(s)`.
- Exit with code `1`.

Warnings should be avoided in v1. A condition should either be a failure or stay out of the script until it becomes a clear rule.

## Out Of Scope For V1

- No broad test framework adoption.
- No map importer.
- No map resource rewrite.
- No visual path or screenshot validation.
- No full graph reachability analysis.
- No support for arbitrary map resource arguments.
- No validation of card, stock market, casino, or future event systems.

## Acceptance For Implementation

Issue #16 should be considered complete when:

- `res://tools/smoke_map_validation.gd` exists.
- The planned command is documented and runnable where Godot CLI is available.
- The script fails on helper validation messages.
- The script checks the active resource path, expected player spawns, route/junction assumptions, source-node landing mapping, and property marker tile types.
- The script exits `0` on pass and non-zero on fail.
