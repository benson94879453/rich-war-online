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
- Event log and core game status UI.

## Not Implemented Yet

- Reliable same-seat reconnect after disconnect.
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

- Reconnect currently gives a fresh seat assignment; reseating to the previous player is not finalized.
- Network testing is manual and focused on two local game windows.
- The Host can optionally control open seats for prototype testing.
- UI is functional debug UI, not final game UX.
- Some legacy demo scenes remain in the project but the active entry point is `StarQGame.tscn`.

## Project Layout

```text
res://
  docs/
    target.md
    MVP_SCOPE.md
    CHANGE_CONTROL.md
    MANUAL_TEST_CHECKLIST.md
    network_test_checklist.md
    qa_notes.md
  scenes/
    StarQGame.tscn
    Board.tscn
    PlayerPiece.tscn
    UI.tscn
    GridRouteChoicePanel.tscn
  scripts/
    autoload/
      GameManager.gd
      EventBus.gd
    core/
      StarQGame.gd
      Board.gd
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
```

## Development Flow

1. Keep `docs/MVP_SCOPE.md` as the current product baseline.
2. Record meaningful scope changes in `docs/CHANGE_CONTROL.md`.
3. Validate prototype builds with `docs/MANUAL_TEST_CHECKLIST.md`.
4. Keep changes small enough to match one Scrum story or bug fix.

## Manual Test Entry Point

Use `docs/MANUAL_TEST_CHECKLIST.md` for baseline validation.

For the current multiplayer path:

1. Start two Godot game windows.
2. In window A, click `Host`.
3. In window B, use `ws://127.0.0.1:8910` and click `Join`.
4. Exercise Roll, route choice, Buy, Skip, mid-game join, and reconnect smoke tests.

