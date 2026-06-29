# Rich War Online Roadmap

Baseline date: 2026-06-26

## Product Positioning

Rich War Online is a 2-4 player online strategy board game inspired by classic property-trading board-game pacing.

The prototype currently uses a complex imported map as a development accelerator. That map is a bootstrap asset for validating board rendering, route movement, tile effects, turns, and multiplayer synchronization. It is not the product identity and should not become a dependency for the final game.

Long term, Rich War Online should support original maps, original events, original special buildings, original cards, and original rules content.

## Development Principle

Separate these three layers:

- Map import layer: converts prototype or original map data into Rich War Online's internal board format.
- Board game engine layer: owns turns, movement, state, tile effects, properties, cards, events, buildings, and networking.
- Content layer: owns maps, tile names, events, buildings, cards, economy values, and balance.

The board game engine should not depend on one specific source map.

## Epics

### Epic 1: Prototype Map Pipeline

Goal:

Convert current prototype map data into a documented, validated Rich War Online map baseline.

Success looks like:

- The map source and transformation path are documented.
- The internal map concepts are named clearly.
- Spawns, route choices, tile mapping, and movement validation are testable.
- Known map-data limitations are recorded instead of hidden in code.

### Epic 2: Local Core Loop

Goal:

Make the 4-player local board-game loop stable enough to iterate on.

Current status:

- `v0.1-local-core-loop` has passed manual 4-player validation.
- Snapshot smoke coverage exists for core `GameState` restore behavior.

### Epic 3: Online Authority

Goal:

Make Host-authoritative multiplayer reliable enough for a playable prototype.

Current status:

- `P0.2` WebSocket Host / Client core actions exist.
- `P0.3-reconnect-baseline` is complete: same-seat reconnect works through a prototype identity token, Host seat reservation, and fresh snapshot sync.
- `v0.2-online-core` is ready based on Sprint3 evidence: owner-reported 10-turn networked acceptance passed, automated smoke checks passed, and authority failure visibility was reviewed.

Next key milestone:

- `v0.3-event-building-loop`: add a small Host-authoritative event or special-building loop without destabilizing turn, pending-action, snapshot, or reconnect behavior.

### Epic 4: Special Events, Buildings, And Cards

Goal:

Add Rich War Online's differentiating interaction systems after the board and network loop are stable.

Suggested order:

1. Special tile events.
2. Special buildings.
3. Cards and timing windows.

Cards should wait until turn phases, pending actions, Host validation, and UI timing are stable.

### Epic 5: Original Map Authoring

Goal:

Replace prototype map dependency with original map content and a repeatable authoring format.

Initial authoring can be JSON, CSV, or Godot Resources. A visual editor is not required for the early MVP.

## Version Path

| Version | Focus | Completion Signal |
| --- | --- | --- |
| `v0.1-local-core-loop` | 4-player local board loop | 20+ local turns pass with route, Buy, Skip, and rent coverage. |
| `v0.2-online-core` | Host / Client core loop | 2-4 players can play 10 networked turns without divergence. |
| `P0.3-reconnect-baseline` | Same-seat reconnect | Reconnecting Client returns to the same seat and receives a fresh snapshot. |
| `v0.3-event-building-loop` | Events and special buildings | A small event/building set works through Host-authoritative resolution. |
| `v0.4-card-window-loop` | Cards and timing windows | A small card set works through Host validation and one timing window. |
| `v1.0-playable-mvp` | Full prototype match | Original content, full game end, bankruptcy, scoring, and basic balance exist. |

## Current Planning Decision

Sprint1 established the prototype map pipeline baseline without expanding gameplay scope.

Sprint2 completed `P0.3-reconnect-baseline`: same-seat reconnect through a prototype identity token, Host seat reservation, fresh snapshot sync after reconnect, and manual two-window reconnect acceptance.

Sprint3 completed `v0.2-online-core` stability: it defined and ran a networked 10-turn acceptance pass, reviewed Host-authoritative failure visibility, and recorded readiness to move into a narrowly scoped gameplay-system sprint.

Sprint5 completed the first narrow `v0.3-event-building-loop` slice: a deterministic prototype event can resolve through a reusable event service, active `starq_chance` landings route through the Host-authoritative landing pipeline, and scenario smoke coverage proves snapshot round-trip behavior.

Next recommended direction: run Sprint6 as a `GameManager` decomposition sprint before adding special buildings or card timing windows. Cards should still wait until event/building boundaries are clearer and stable under Host authority.
