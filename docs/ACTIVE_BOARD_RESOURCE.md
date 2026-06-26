# Active Board Resource Inventory

Baseline date: 2026-06-26

## Purpose

This document records the current assumptions for the active playable board resource:

> `res://resources/maps/starq_board.tres`

It is an inventory document, not an importer specification and not a resource rewrite plan.

## Active Entry Points

| Purpose | Path |
| --- | --- |
| Active scene | `res://scenes/StarQGame.tscn` |
| Active board resource | `res://resources/maps/starq_board.tres` |
| Board resource class | `BoardData` |
| Active grid class | `BoardMapGridData` |
| Local/manual QA checklist | `docs/MANUAL_TEST_CHECKLIST.md` |

Do not use `res://scenes/Main.tscn` or `res://scenes/StarQMap.tscn` to judge active baseline readiness.

## Resource Counts

Observed in `res://resources/maps/starq_board.tres`:

| Item | Count / value | Notes |
| --- | --- | --- |
| Grid width | 41 | From `BoardMapGridData.width`. |
| Grid height | 43 | From `BoardMapGridData.height`. |
| Grid cells | 1763 | `41 * 43`. |
| `BoardTileData` entries | 160 | Active map is not the legacy 40-tile loop. |
| Tile placements | 160 | One placement subresource per tile. |
| Property decorations | 56 | Matches the observed number of priced property tiles. |
| Player spawns | 4 | P1-P4 grid spawns. |
| `BoardConnectionData` entries | 0 | Active grid movement does not use classic tile-to-tile connections. |
| `node_directions_by_id` entries | 160 | Direction metadata for walkable landing nodes. |
| `walkable_node_ids` entries | 160 | Walkable named nodes. |
| `junction_directions_by_node_id` entries | 28 | Junction nodes 205-232. |
| `source_node_id` entries | 160 | All unique; observed range is 1-232. |

## Tile Type Distribution

The resource serializes explicit non-default tile types. `BoardTileData.tile_type` defaults to `SAFE`, so omitted `tile_type` lines are treated as safe tiles.

| Tile type enum | Meaning | Count |
| --- | --- | --- |
| `PROPERTY` (`1`) | Property | 56 |
| `STOCK_MARKET` (`2`) | Stock market | 4 |
| `DRAW_CARD` (`3`) | Draw card | 6 |
| `CHANCE` (`4`) | Chance | 6 |
| `FATE` (`5`) | Fate | 4 |
| `BLESSING` (`6`) | Blessing | 22 |
| `SPECIAL` (`8`) | Special | 34 |
| Default `SAFE` (`9`) | Safe / omitted tile type | 28 |

Notes:

- No explicit `START` tile is currently serialized.
- No explicit `CURSE` tile is currently serialized.
- 56 `price` entries were observed, matching the property tile count.

## Player Spawns

| Player | Tile index | Grid position | Initial direction |
| --- | --- | --- | --- |
| P1 (`player_id = 0`) | 62 | `Vector2i(33, 7)` | `RIGHT` (`1`) |
| P2 (`player_id = 1`) | 64 | `Vector2i(29, 33)` | `DOWN` (`4`) |
| P3 (`player_id = 2`) | 68 | `Vector2i(10, 10)` | `UP` (`2`) |
| P4 (`player_id = 3`) | 66 | `Vector2i(7, 35)` | `LEFT` (`3`) |

Assumptions:

- The grid spawn is the source of truth for active `StarQGame.tscn` movement.
- `tile_index` remains useful as fallback metadata and for tile/property systems.
- Every spawn must resolve to a valid landing node.

## Movement Assumptions

The active map uses grid movement:

- `StarQGame.tscn` loads `BoardData`.
- `BoardData.get_map_grid()` returns `BoardMapGridData`.
- `GameManager` initializes `PlayerMapState` from `BoardPlayerSpawnData`.
- `GridMovementSystem` advances movement by asking `MapGridNavigator` for valid directions.
- `MapGridNavigator` reads direction and junction data from `BoardMapGridData`.

Important implementation details:

- `BoardConnectionData` is not the active movement source for `starq_board.tres`.
- Node id `0` is used as intermediate road/path space.
- `BoardMapGridData.BACKGROUND_NODE_ID` is `233`.
- Junction nodes are defined by `junction_directions_by_node_id`; route-choice UI depends on these directions.
- Non-junction nodes continue in the current travel direction when a route exists.

## Validation Helpers Already Available

Existing helper methods can support a future map smoke script:

| Helper | Current purpose |
| --- | --- |
| `BoardData.get_placement_validation_messages()` | Checks tile placement references and duplicates. |
| `BoardData.get_property_decoration_validation_messages()` | Checks property decoration tile references. |
| `BoardData.get_map_grid_validation_messages()` | Delegates grid validation to `BoardMapGridData`. |
| `BoardData.get_source_node_validation_messages()` | Checks duplicate source-node to tile mappings. |
| `BoardData.get_connection_validation_messages()` | Checks classic tile-to-tile connections when present. |
| `BoardData.get_player_spawn_validation_messages()` | Checks spawn references, landing nodes, duplicate player ids, and initial directions. |
| `BoardMapGridData.get_validation_messages()` | Checks dimensions, node count, junction directions, and walkable-node directions. |

## Known Assumptions And Risks

- `BoardData.EXPECTED_TILE_COUNT` is `40`, but the active resource contains `160` tiles. Active map validation must not treat the 40-tile value as a failure when explicit placements and grid data are present.
- The upstream conversion/import process is not documented in code yet.
- The resource is large and hand-reviewing it directly is error-prone.
- Current validation helpers are runtime helpers, not a standalone map validation command.
- Active movement depends on `BoardMapGridData` direction metadata being internally consistent.
- A broken junction may produce a stuck route-choice or blocked movement state.
- Some tile types are present before their full gameplay systems exist, such as stock, draw card, chance, fate, blessing, and special.
- No active original-map authoring format exists yet.

## Temporary Files

Decision from [issue #14](https://github.com/benson94879453/rich-war-online/issues/14):

- `res://scenes/Main.tscn2093169919.tmp` was a stale temporary write artifact for a legacy demo scene and has been removed.
- `res://resources/tiles/default_board.tres2095199292.tmp` was a stale temporary write artifact for an older default board resource and has been removed.
- Similar Godot temporary scene/resource artifacts are ignored by `.gitignore`.

These files were outside the active board resource inventory. The active baseline remains `res://scenes/StarQGame.tscn` with `res://resources/maps/starq_board.tres`.
