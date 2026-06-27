# Sprint2 Acceptance Evidence

Date: 2026-06-27

Branch under test: `codex/issue-24-reconnect-acceptance-pass`

Sprint integration branch baseline: `codex/sprint2-reconnect-baseline`

## Scope

This evidence records the current `P0.3-reconnect-baseline` verification state for Sprint2.

Sprint2 implemented:

- Prototype reconnect token lifecycle.
- Host disconnected-seat reservation.
- Matching-token reserved-seat reclaim.
- Fresh snapshot send after reserved-seat reclaim.
- Visible reconnect and snapshot status for manual QA.

## Automated Smoke Evidence

All commands were run with the Steam Godot executable:

`C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`

| Check | Command | Result |
| --- | --- | --- |
| Reconnect token lifecycle | `--headless --path . --script res://tools/smoke_reconnect_token_lifecycle.gd` | Pass, exit code 0 |
| Host seat reservation | `--headless --path . --script res://tools/smoke_reconnect_seat_reservation.gd` | Pass, exit code 0 |
| Reserved-seat reassignment | `--headless --path . --script res://tools/smoke_reconnect_reserved_seat_reassign.gd` | Pass, exit code 0 |
| Reconnect status and snapshot message | `--headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd` | Pass, exit code 0 |
| GameState snapshot restore | `--headless --path . --script res://tools/smoke_game_state_snapshot.gd` | Pass, exit code 0 |
| Active map validation | `--headless --path . --script res://tools/smoke_map_validation.gd` | Pass, exit code 0 |

Note: the Steam Godot Windows build used in this environment returns process exit codes but does not reliably pipe `print()` output back to PowerShell. Exit code 0 was used as the pass signal.

## Manual Two-Window Acceptance

Status: Pending human execution.

The manual two-window acceptance path is documented in `docs/MANUAL_TEST_CHECKLIST.md`, section `9.5 P0.3 Same-Seat Reconnect Acceptance`.

Required manual observations:

- Window B returns to the same player seat after disconnect/rejoin.
- Window B network status reports `Reconnected as Pn`.
- Window B network status includes `synced snapshot #n`.
- Host does not assign the reserved seat to another peer.
- Current round, active player, money, piece positions, property ownership, pending action, dice, landed tile, event text, and recent log lines match Host.
- The reconnecting Client can act when the reclaimed player seat becomes active.

## Current Acceptance Read

Automated evidence covers the data-path and Host-authoritative reconnect mechanics. Full Sprint2 acceptance should not be marked complete until the manual two-window pass above is run and recorded.
