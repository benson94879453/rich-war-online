# Map Pipeline

Baseline date: 2026-06-26

## Purpose

This document describes how Rich War Online turns map data into the internal board format used by gameplay systems.

The current prototype map is a bootstrap source for development. The long-term product should support original Rich War Online maps that use the same internal concepts.

## Current Active Map

Current baseline scene:

> `res://scenes/StarQGame.tscn`

Current active board resource:

> `res://resources/maps/starq_board.tres`

Current inventory document:

> `docs/ACTIVE_BOARD_RESOURCE.md`

Current map validation checklist:

> `docs/MAP_VALIDATION_CHECKLIST.md`

Current map validation smoke plan:

> `docs/MAP_VALIDATION_SMOKE_PLAN.md`

Legacy/demo scenes are not map pipeline acceptance targets:

- `res://scenes/Main.tscn`
- `res://scenes/StarQMap.tscn`

## Pipeline

```text
Prototype map source
-> internal map concepts
-> Godot BoardData resource
-> BoardMapGridData / BoardTileData / spawn data
-> playable board in StarQGame.tscn
```

The current repository already stores the playable result as Godot Resources. The next pipeline step is to document and validate the source-to-resource assumptions so future original maps can use the same path.

## Internal Map Concepts

These names are the shared vocabulary for map pipeline work. They describe Rich War Online's own map model, regardless of whether the source is prototype map data, hand-written JSON, CSV, Godot Resources, or a future editor.

Recommended identifier rules:

- `map_id`: stable string, for example `prototype_starq_001` or `original_city_001`.
- `node_id`: stable integer or string from the map graph.
- `tile_id`: stable string for gameplay tiles, independent from display text.
- `player_id`: zero-based player id used by current gameplay code.
- `direction`: one of the current `BoardConnectionData.Direction` values: `RIGHT`, `UP`, `LEFT`, `DOWN`.

### Map

A complete playable board definition.

Minimum fields:

- `map_id`
- `display_name`
- `width`
- `height`
- `nodes`
- `tiles`
- `connections`
- `player_spawns`

Draft shape:

```json
{
  "map_id": "prototype_starq_001",
  "display_name": "Prototype StarQ Map",
  "width": 41,
  "height": 43,
  "nodes": [],
  "tiles": [],
  "connections": [],
  "player_spawns": []
}
```

### Node

A walkable map point in grid space.

Minimum fields:

- `node_id`
- `grid_position`
- `directions`
- `is_walkable`
- `tile_id` when the node is a landing tile

Draft shape:

```json
{
  "node_id": 101,
  "grid_position": { "x": 12, "y": 30 },
  "directions": ["RIGHT", "DOWN"],
  "is_walkable": true,
  "tile_id": "tile_101"
}
```

### Tile

A gameplay landing cell.

Minimum fields:

- `tile_id`
- `source_node_id`
- `tile_type`
- `display_name`
- `effect_id`

Economy fields when relevant:

- `price`
- `base_rent`
- `salary`
- `money_delta`

Draft shape:

```json
{
  "tile_id": "tile_101",
  "source_node_id": 101,
  "tile_type": "property",
  "display_name": "Prototype Property",
  "effect_id": "property_basic",
  "price": 300,
  "base_rent": 45
}
```

### Connection

A route relationship from one tile or node to another.

Minimum fields:

- `from_node_id` or `from_tile_id`
- `to_node_id` or `to_tile_id`
- `direction`

Draft shape:

```json
{
  "from_node_id": 101,
  "to_node_id": 102,
  "direction": "RIGHT"
}
```

### Spawn

A valid starting state for a player.

Minimum fields:

- `player_id`
- `grid_position`
- `initial_direction`
- fallback `tile_index` when no grid map exists

Draft shape:

```json
{
  "player_id": 0,
  "grid_position": { "x": 3, "y": 4 },
  "initial_direction": "RIGHT",
  "tile_id": "tile_start_p1"
}
```

## RichWarMap Schema Draft

The first schema is descriptive, not a required file format yet. It exists to keep future importer and original-map work aligned.

```json
{
  "schema_version": 1,
  "map_id": "prototype_starq_001",
  "display_name": "Prototype StarQ Map",
  "grid": {
    "width": 41,
    "height": 43
  },
  "nodes": [
    {
      "node_id": 101,
      "grid_position": { "x": 12, "y": 30 },
      "directions": ["RIGHT"],
      "is_walkable": true,
      "tile_id": "tile_101"
    }
  ],
  "tiles": [
    {
      "tile_id": "tile_101",
      "source_node_id": 101,
      "tile_type": "property",
      "display_name": "Prototype Property",
      "effect_id": "property_basic",
      "price": 300,
      "base_rent": 45
    }
  ],
  "connections": [
    {
      "from_node_id": 101,
      "to_node_id": 102,
      "direction": "RIGHT"
    }
  ],
  "player_spawns": [
    {
      "player_id": 0,
      "grid_position": { "x": 3, "y": 4 },
      "initial_direction": "RIGHT",
      "tile_id": "tile_start_p1"
    }
  ]
}
```

## Deferred Schema Fields

These are expected later, but they should not block the current pipeline baseline:

- `theme_id` for visual theme selection.
- `event_pool_ids` for map-specific event decks.
- `building_slots` for special building placement.
- `district_id` or `group_id` for property sets.
- `art_refs` for final map art and icon references.
- `authoring_notes` for editor-only metadata.
- `balance_tags` for economy tuning.

## Current Godot Resources

| Schema concept | Current class | Important current fields |
| --- | --- | --- |
| Map / board | `BoardData` | `tiles`, `connections`, `placements`, `property_decorations`, `map_grid`, `player_spawns` |
| Tile | `BoardTileData` | `index`, `source_node_id`, `tile_type`, `display_name`, `price`, `base_rent`, `salary`, `money_delta`, `deck_id`, `effect_id` |
| Grid | `BoardMapGridData` | `width`, `height`, `node_ids`, `node_directions_by_id`, `walkable_node_ids`, `junction_directions_by_node_id` |
| Connection | `BoardConnectionData` | `from_tile_index`, `to_tile_index`, `direction` |
| Spawn | `BoardPlayerSpawnData` | `player_id`, `tile_index`, `grid_position`, `initial_direction` |
| Tile placement | `BoardTilePlacementData` | `tile_index`, `center_position` |
| Property marker placement | `BoardPropertyDecorationData` | `tile_index`, `center_position`, `facing_direction` |

## Current Mapping Notes

- `BoardData` is the playable board resource consumed by the active scene.
- `BoardMapGridData` currently holds the grid graph, including walkable node ids and direction metadata.
- `BoardTileData.source_node_id` links a gameplay tile to a map grid node.
- `BoardPlayerSpawnData.grid_position` and `initial_direction` are the current grid-map spawn source of truth.
- `BoardConnectionData` exists for classic tile-to-tile routes. The current active grid movement path mainly uses `BoardMapGridData` and `GridMovementSystem`.
- `BoardTilePlacementData` and `BoardPropertyDecorationData` are visual/layout helpers, not core game rules.

## Validation Rules

Minimum validation for a prototype map baseline:

- Every player spawn points to a valid landing node.
- Every spawn has a valid initial direction.
- Every source node maps to at most one tile.
- Every walkable node has direction data.
- Every junction exposes at least one valid direction.
- Route-choice nodes expose directions the UI can submit.
- Tile references point to existing tile data.
- Property decoration references point to existing property tiles.
- No normal movement path should enter an unrecoverable blocked state.

Run `docs/MAP_VALIDATION_CHECKLIST.md` for the manual evidence format and detailed per-area checklist before treating a map resource as baseline-ready. Use `docs/MAP_VALIDATION_SMOKE_PLAN.md` when implementing or reviewing the headless map validation smoke script.

## Out Of Scope

This pipeline baseline does not require:

- A visual map editor.
- A production-ready importer.
- Original final map art.
- Full automatic reachability analysis.
- Cards, stock market, casino systems, or final event pools.

## Known Gaps

- The current playable map is already serialized as a Godot Resource, but the upstream import/conversion process is not documented in code.
- Automated map validation is limited to helper methods inside `BoardData` and `BoardMapGridData`.
- There is no standalone map validation command yet.
- Stale Godot temporary files were removed in issue #14 and similar scene/resource write artifacts are ignored.
- The schema is descriptive and has not been implemented as a JSON importer.
- The current resource uses numeric tile indices internally; the draft schema prefers stable string ids for future original-map authoring.
- Final event pools, special buildings, cards, districts, and art references are intentionally deferred.
