# Sprint3 Networked 10-Turn Evidence

Date: 2026-06-27

Branch under test: `codex/issue-33-networked-10-turn-pass`

Sprint integration branch baseline: `codex/sprint3-online-core-stability`

## Scope

This file records the current evidence state for issue #33, the Sprint3 `v0.2-online-core` networked 10-turn acceptance pass.

The required manual procedure is defined in `docs/sprints/sprint3_networked_10_turn_acceptance.md`.

## Current Status

Status: Manual execution pending.

Codex could run the available headless smoke checks, but did not execute the required two-window or multi-window Godot manual run. The 10-turn Host/Client state comparison must still be completed before issue #33 can be closed.

## Automated Regression Evidence

All commands were run with the Steam Godot executable:

`C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`

| Check | Command | Result |
| --- | --- | --- |
| GameState snapshot restore | `--headless --path . --script res://tools/smoke_game_state_snapshot.gd` | Pass, exit code 0 |
| Active map validation | `--headless --path . --script res://tools/smoke_map_validation.gd` | Pass, exit code 0 |
| Reconnect token lifecycle | `--headless --path . --script res://tools/smoke_reconnect_token_lifecycle.gd` | Pass, exit code 0 |
| Host seat reservation | `--headless --path . --script res://tools/smoke_reconnect_seat_reservation.gd` | Pass, exit code 0 |
| Reserved-seat reassignment | `--headless --path . --script res://tools/smoke_reconnect_reserved_seat_reassign.gd` | Pass, exit code 0 |
| Reconnect status and snapshot message | `--headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd` | Pass, exit code 0 |

Note: the Steam Godot Windows build used in this environment returns process exit codes but does not reliably pipe `print()` output back to PowerShell. Exit code 0 was used as the pass signal.

## Manual 10-Turn Acceptance

Status: Pending.

Required evidence:

- Date:
- Branch / commit:
- Godot version:
- Windows used:
- Player seat mapping:
- Host controls open seats: on/off
- Completed turns:
- Route choice encountered: yes/no/not encountered
- Property Buy/Skip encountered: yes/no/not encountered
- Rent encountered: yes/no/not encountered
- Snapshot join or reconnect check: pass/fail
- Result: pass/fail

## Turn Evidence Table

| Turn # | Acting player | Control window | Action path | Dice / decision | Host state summary | Client state summary | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 |  |  |  |  |  |  | Pending |
| 2 |  |  |  |  |  |  | Pending |
| 3 |  |  |  |  |  |  | Pending |
| 4 |  |  |  |  |  |  | Pending |
| 5 |  |  |  |  |  |  | Pending |
| 6 |  |  |  |  |  |  | Pending |
| 7 |  |  |  |  |  |  | Pending |
| 8 |  |  |  |  |  |  | Pending |
| 9 |  |  |  |  |  |  | Pending |
| 10 |  |  |  |  |  |  | Pending |

## Snapshot / Reconnect Evidence

| Check | Expected observation | Actual observation | Result |
| --- | --- | --- | --- |
| Mid-run join or reconnect status | Client reports joined or `Reconnected as Pn` |  | Pending |
| Snapshot revision | Client status includes `synced snapshot #n` |  | Pending |
| Seat assignment | Reconnect returns to the same seat when using the same local reconnect token |  | Pending |
| State comparison | Round, active player, money, positions, ownership, pending action, dice, landed tile, event text, and recent log lines match Host |  | Pending |
| Continued play | Rejoined or reconnected Client can act when its controlled seat becomes active |  | Pending |

## Current Acceptance Read

Automated regression checks pass, but they do not satisfy issue #33 by themselves. Issue #33 remains open until the manual networked 10-turn pass is executed and either passes or records a named blocker.
