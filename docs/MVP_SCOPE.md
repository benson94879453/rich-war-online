# Rich War Online MVP Scope

Baseline date: 2026-06-26

This document defines the prototype baseline used for Scrum planning. `docs/target.md` remains the broader product design reference; this file is the current execution scope.

## Product Goal

Build a multiplayer board-game prototype that proves the core loop:

> Players take turns, move around a shared board, buy or pay for properties, and stay synchronized through a Host-authoritative network model.

The larger product vision includes intervention cards and reaction windows, but the immediate milestone is a stable multiplayer board foundation.

## MVP Validation Questions

- Can two or more players share the same board state without divergence?
- Can Clients submit intents while the Host remains authoritative?
- Can a late-joining Client restore enough state to continue the match?
- Can the property flow support later intervention-card insertion points?
- Is the turn loop readable enough for repeated manual testing?

## In Scope For Current Prototype

- Godot 4.6.x project using `StarQGame.tscn` as the active scene.
- Local 1-4 player turn loop.
- Dice roll, movement, landing resolution, and turn switching.
- Grid-based board movement with branch route choices.
- Basic property purchase and rent flow.
- Basic bankruptcy handling.
- Host / Client WebSocket prototype.
- Intent submission for roll, route choice, buy property, and skip property.
- Host-side action validation.
- GameState snapshot serialization and restoration.
- Client join snapshot sync.
- Debug UI for local network testing.
- Manual QA checklist for baseline validation.

## Active Baseline Entry Point

The current baseline entry point is:

> `res://scenes/StarQGame.tscn`

Use this scene for sprint review, manual QA, and `v0.1-local-core-loop` validation.

The following scenes are retained as legacy/demo references and are not baseline acceptance targets:

- `res://scenes/Main.tscn`: older local two-player prototype.
- `res://scenes/StarQMap.tscn`: map movement demo scene.

Stale Godot temporary scene/resource write artifacts are not part of the active baseline. The known stale `.tmp` files were removed in issue #14, and similar artifacts are ignored by `.gitignore`.

## Out Of Scope For Current Prototype

- Production lobby or account system.
- Room codes, matchmaking, or public server hosting.
- Same-seat reconnect guarantee.
- AI players.
- Final UI art, sound, animation polish, or accessibility pass.
- Full Web export/release pipeline.
- Property upgrades.
- Full bankruptcy liquidation and end-game scoring.
- Stock market system.
- Card draw, chance/fate cards, intervention cards, counter cards.
- Timed intervention windows.
- Complex status effects such as jail, hospital, speed, slow, shields, luck, or misfortune.
- Balance tuning.

## Completed

- `P0.1` Local board prototype is implemented.
- 2D grid movement and branch route selection are implemented.
- Basic property purchase, rent, and bankruptcy are implemented.
- `GameState` can serialize and restore core player, map, property, turn, pending action, and UI summary state.
- `P0.2` WebSocket Host / Client prototype exists for core actions.
- Host-authoritative intent flow exists for Roll, route choice, Buy, and Skip.
- Client pending-intent locking exists to avoid duplicate local submissions.
- Stale property-decision rejection display is filtered when the local state has already advanced.
- Snapshot join sync includes turn, positions, money, property ownership, dice, landing text, event text, and recent log lines.
- Manual network checklist exists and is promoted into the formal baseline checklist.

## Not Completed

- Same-player reconnect after disconnect.
- Robust seat reservation or player identity token system.
- Multi-client stress testing beyond local manual windows.
- Automated gameplay tests.
- Property upgrades and valuation.
- Pass Go salary behavior.
- Special tile effects beyond the current basic resolver.
- Intervention windows and card system.
- Stock market.
- Game-over and winner calculation.

## Known Issues

- Reconnect currently relies on new join behavior and does not guarantee returning to the same player seat.
- Host open-seat control is a prototype convenience and may hide seat ownership problems during manual testing.
- Manual testing is currently the source of truth; no automated regression suite exists yet.
- Legacy demo scenes still exist but are not baseline acceptance targets.
- Multiplayer behavior should be tested in Web exports later; current baseline focuses on local editor/desktop windows.

## Next Recommended Sprint

Sprint goal:

> Complete the P0.3 reconnect baseline by adding stable player identity, seat reservation, and same-seat rejoin behavior.

Decision:

> Same-seat reconnect is required for `P0.3-reconnect-baseline`, but remains out of scope for `v0.1-local-core-loop`.

Candidate stories:

- As a reconnecting Client, I can reclaim my previous player seat.
- As Host, I can keep disconnected seats reserved for a short prototype grace period.
- As a tester, I can see connection and seat state clearly in the debug UI.
- As a developer, I can validate reconnect behavior with the manual checklist.

See `docs/reconnect_baseline.md` for the baseline behavior and manual acceptance criteria.
