# Rich War Online

Rich War Online is a Godot multiplayer board game prototype. The design direction is a Monopoly-style asset game with online turns, property ownership, and a future intervention-card system that lets players affect other players' turns.

This repository is currently a prototype baseline, not a finished MVP.

## Current Baseline

- Engine: Godot 4.6.x stable
- Rendering: GL Compatibility
- Main scene: `res://scenes/StarQGame.tscn`
- Primary target: Web
- Secondary targets: Windows, macOS
- Multiplayer model: Host-authoritative
- Web networking path: `WebSocketMultiplayerPeer`
- Desktop networking path: planned `ENetMultiplayerPeer`

## Active Scene Boundary

Use `res://scenes/StarQGame.tscn` for all baseline validation, sprint review, and manual QA.

Legacy/demo scenes remain in the repository for reference, but they are outside the active baseline:

- `res://scenes/Main.tscn`: older local two-player board prototype using `scripts/core/Main.gd`.
- `res://scenes/StarQMap.tscn`: map movement demo using `scripts/core/StarQMapDemo.gd`.

Do not use legacy/demo scenes to judge `v0.1-local-core-loop` readiness. Stale Godot temporary scene/resource write artifacts are ignored by `.gitignore` and should not be mixed into gameplay or baseline documentation work.

## Implemented

- Local 1-4 player turn flow.
- Dice roll and smooth piece movement on the 2D grid board.
- Grid route choice when movement reaches a branch.
- Basic property purchase, rent payment, and bankruptcy handling.
- Serializable `GameState` snapshots with turn phase and UI summary data.
- Host / Client WebSocket prototype with intent-based Roll, Buy, Skip, and route choice requests.
- Host-authoritative validation for player control and pending actions.
- Snapshot sync when a Client joins an active Host.
- Basic network debug UI for Host / Join / status and Host open-seat control.
- Same-seat reconnect for prototype Clients using a persisted local reconnect token.
- Event log and core game status UI.

## Not Implemented Yet

- Production account-backed reconnect and cross-device continuity.
- Lobby, room code, or matchmaking flow.
- Property upgrades and property valuation.
- Pass Go salary rules.
- Card draw, chance, fate, and special tile systems.
- Player status effects.
- Intervention windows and intervention cards.
- Stock market system.
- End-game scoring and full bankruptcy settlement.
- Production Web export pipeline.

## Known Issues / Prototype Limits

- Reconnect identity is stored in local Godot user data; deleting app data or joining from another device creates a fresh identity.
- Network testing is manual and focused on two local game windows.
- The Host can optionally control open seats for prototype testing.
- UI is functional debug UI, not final game UX.
- Some legacy demo scenes remain in the project, but the active entry point is `StarQGame.tscn`.

## Project Layout

```text
res://
  docs/
    target.md
    ROADMAP.md
    MAP_PIPELINE.md
    ACTIVE_BOARD_RESOURCE.md
    MAP_VALIDATION_CHECKLIST.md
    MAP_VALIDATION_SMOKE_PLAN.md
    MVP_SCOPE.md
    PRODUCT_BACKLOG.md
    CHANGE_CONTROL.md
    MANUAL_TEST_CHECKLIST.md
    reconnect_baseline.md
    network_test_checklist.md
    qa_notes.md
    releases/v0.1-local-core-loop.md
    sprints/sprint0.md
    sprints/sprint1.md
    sprints/sprint2.md
    sprints/sprint2_acceptance.md
    sprints/sprint3.md
    sprints/sprint3_authority_failure_visibility.md
    sprints/sprint3_networked_10_turn_acceptance.md
    sprints/sprint3_networked_10_turn_evidence.md
    sprints/sprint3_readiness_review.md
  scenes/
    StarQGame.tscn
    Board.tscn
    PlayerPiece.tscn
    UI.tscn
    GridRouteChoicePanel.tscn
    Main.tscn                  # legacy prototype, not baseline QA
    StarQMap.tscn              # map demo, not baseline QA
  scripts/
    autoload/
      GameManager.gd
      EventBus.gd
    core/
      StarQGame.gd
      ActionDispatcher.gd
      Board.gd
      EffectResult.gd
      EffectService.gd
      TurnSystem.gd
      GridMovementSystem.gd
      GameUI.gd
    data/
      GameState.gd
      PlayerState.gd
      PlayerMapState.gd
      TileData.gd
    network/
      NetworkManager.gd
  resources/
    maps/
    tiles/
  tools/
    scenarios/
      README.md
      scenario_10_roll_local_action_pipeline.gd
    smoke_action_dispatcher.gd
    smoke_effect_service.gd
    smoke_game_state_reserved_defaults.gd
    smoke_game_state_snapshot.gd
    smoke_turn_system_fsm.gd
    smoke_map_validation.gd
```

## Development Flow

1. Keep `docs/MVP_SCOPE.md` as the current product baseline.
2. Use `docs/PRODUCT_BACKLOG.md` to order sprint work.
3. Record meaningful scope changes in `docs/CHANGE_CONTROL.md`.
4. Validate prototype builds with `docs/MANUAL_TEST_CHECKLIST.md`.
5. Keep changes small enough to match one Scrum story or bug fix.

## Smoke Checks

Run the local 10-roll action pipeline scenario with:

```bash
godot --headless --path . --script res://tools/scenarios/scenario_10_roll_local_action_pipeline.gd
```

Run the action dispatcher smoke check with a Godot command-line runner:

```bash
godot --headless --path . --script res://tools/smoke_action_dispatcher.gd
```

Run the effect service smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_effect_service.gd
```

Run the TurnSystem FSM smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_turn_system_fsm.gd
```

Run the GameState reserved defaults smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_game_state_reserved_defaults.gd
```

Run the GameState snapshot smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_game_state_snapshot.gd
```

If `godot` is not on PATH, run the same script from a configured Godot 4.6.x executable.

Run the map validation smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_map_validation.gd
```

The map validation script follows `docs/MAP_VALIDATION_SMOKE_PLAN.md`.

Run the reconnect token lifecycle smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_reconnect_token_lifecycle.gd
```

Run the reconnect seat reservation smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_reconnect_seat_reservation.gd
```

Run the reconnect reserved-seat reassignment smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_reconnect_reserved_seat_reassign.gd
```

Run the reconnect status/snapshot smoke check with:

```bash
godot --headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd
```

## Manual Test Entry Point

Use `docs/MANUAL_TEST_CHECKLIST.md` for baseline validation.
Use `docs/MAP_VALIDATION_CHECKLIST.md` when map resource, spawn, route, tile placement, or property marker data changes.

For the current multiplayer path:

1. Start two Godot game windows.
2. In window A, click `Host`.
3. In window B, use `ws://127.0.0.1:8910` and click `Join`.
4. Exercise Roll, route choice, Buy, Skip, mid-game join, and reconnect smoke tests.
