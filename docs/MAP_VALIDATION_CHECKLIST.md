# Map Validation Checklist

Baseline date: 2026-06-26

## Purpose

Use this checklist before treating a board resource as baseline-ready after map data, grid movement, spawn, tile placement, or property marker changes.

This checklist is manual for now. A future smoke script can automate the helper-backed checks listed here.

The planned helper-backed smoke script is defined in `docs/MAP_VALIDATION_SMOKE_PLAN.md`.

## Target

Current active scene:

> `res://scenes/StarQGame.tscn`

Current active board resource:

> `res://resources/maps/starq_board.tres`

Reference inventory:

> `docs/ACTIVE_BOARD_RESOURCE.md`

Do not use `res://scenes/Main.tscn` or `res://scenes/StarQMap.tscn` as map validation targets.

## Evidence Header

Record this before the checklist result:

- Date:
- Tester:
- Godot version:
- Board resource:
- Scene:
- Related issue or branch:
- Result: Pass / Fail

## 1. Resource Identity

- [ ] Active scene is `res://scenes/StarQGame.tscn`.
- [ ] Active board resource is `res://resources/maps/starq_board.tres`.
- [ ] Board resource loads as `BoardData`.
- [ ] `BoardData.get_map_grid()` returns `BoardMapGridData`.
- [ ] Legacy/demo scenes are not used to judge baseline map readiness.

## 2. Grid Shape And Direction Data

- [ ] Grid width and height are positive.
- [ ] `node_ids` count equals `width * height`.
- [ ] Walkable node ids resolve to positions inside the grid.
- [ ] Every walkable node has direction metadata in `node_directions_by_id`.
- [ ] Direction values use only `RIGHT`, `UP`, `LEFT`, or `DOWN`.
- [ ] Node id `0` is treated as intermediate road/path space, not a landing tile.
- [ ] `BoardMapGridData.BACKGROUND_NODE_ID` is treated as non-walkable background.

## 3. Player Spawns

- [ ] There is one spawn per expected player.
- [ ] Spawn `player_id` values are unique.
- [ ] Each grid spawn position is inside the grid.
- [ ] Each grid spawn position resolves to a landing node, not node id `0` or background.
- [ ] Each spawn has a valid `initial_direction`.
- [ ] Each fallback `tile_index` references an existing tile when present.
- [ ] Starting movement from each spawn can advance without immediately entering a blocked state.

For the current baseline, expected player ids are `0`, `1`, `2`, and `3`.

## 4. Junctions And Route Choices

- [ ] Every junction node listed in `junction_directions_by_node_id` exists in the grid.
- [ ] Every junction has at least one route direction.
- [ ] Junction directions use only `RIGHT`, `UP`, `LEFT`, or `DOWN`.
- [ ] Route-choice UI can display each available junction direction.
- [ ] Selecting each listed junction direction can continue movement.
- [ ] Route-choice controls disappear after a valid route is accepted.
- [ ] Non-junction nodes continue along the current direction when a route exists.
- [ ] A junction with no valid next step is recorded as a blocked movement risk.

## 5. Tile And Source Node Mapping

- [ ] Every `BoardTileData` entry has a valid tile index.
- [ ] `source_node_id` values are unique when present.
- [ ] Every `source_node_id` maps to a landing node in the active grid.
- [ ] Tile placements reference existing tile indices.
- [ ] Tile placement references are not duplicated.
- [ ] The active grid map is not failed only because `BoardData.EXPECTED_TILE_COUNT` is `40`.
- [ ] Current `starq_board.tres` tile count is compared against the active inventory, not the legacy 40-tile loop.

## 6. Property Marker References

- [ ] Every `BoardPropertyDecorationData` entry references an existing tile index.
- [ ] Property marker tile references point to property tiles unless an exception is documented.
- [ ] Property marker facing directions stay in the expected range.
- [ ] Property markers appear in the intended position during local visual smoke testing.
- [ ] Property marker failures are linked to the affected tile index and display name.

## 7. Blocked Movement Risk

- [ ] From each player spawn, play enough local turns to confirm movement leaves the spawn area.
- [ ] Trigger at least one route choice when the path allows it.
- [ ] Confirm Roll is disabled while route choice is pending.
- [ ] Confirm every visible route button can submit a valid direction.
- [ ] Confirm movement resumes after the route choice.
- [ ] Confirm no normal path reaches a state where movement is pending but no route choice is available.
- [ ] Confirm no script error appears during movement or route-choice validation.

## Failure Record Format

When validation fails, record one entry per issue:

- Checklist section:
- Severity: P0 / P1 / P2
- Node id:
- Tile index:
- Player id:
- Expected:
- Observed:
- Reproduction steps:
- Screenshot or log:
- Follow-up issue:

Severity guidance:

- `P0`: prevents the active scene from running, blocks a player from moving, creates an unrecoverable route choice, or corrupts baseline gameplay state.
- `P1`: map data is internally inconsistent but does not block the current local core loop.
- `P2`: documentation, visual marker, or cleanup issue that does not block validation.

## Helper Coverage

Existing runtime helpers that should be considered when planning automation:

| Helper | Checklist coverage |
| --- | --- |
| `BoardData.get_player_spawn_validation_messages()` | Player spawns and initial directions. |
| `BoardData.get_map_grid_validation_messages()` | Grid shape, junction directions, and walkable-node directions. |
| `BoardData.get_source_node_validation_messages()` | Duplicate source-node mappings. |
| `BoardData.get_placement_validation_messages()` | Tile placement references and duplicates. |
| `BoardData.get_property_decoration_validation_messages()` | Property marker tile references. |
| `BoardData.get_connection_validation_messages()` | Classic tile-to-tile connection checks when used. |
