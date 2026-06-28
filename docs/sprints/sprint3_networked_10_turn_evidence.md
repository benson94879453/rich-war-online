# Sprint3 Networked 10-Turn Evidence

Date: 2026-06-27

Branch under test: `codex/issue-33-networked-10-turn-pass`

Sprint integration branch baseline: `codex/sprint3-online-core-stability`

## Scope

This file records the current evidence state for issue #33, the Sprint3 `v0.2-online-core` networked 10-turn acceptance pass.

The required manual procedure is defined in `docs/sprints/sprint3_networked_10_turn_acceptance.md`.

## Current Status

Status: Passed by owner on issue #33.

Codex ran the available headless smoke checks. The required two-window or multi-window Godot manual run was executed by the owner and reported as passing on issue #33.

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

Status: Passed by owner.

Recorded evidence:

- Date: 2026-06-27
- Branch / commit: `codex/issue-33-networked-10-turn-pass`
- Godot version: not separately recorded
- Windows used: owner-reported networked manual run
- Player seat mapping: not itemized
- Host controls open seats: not separately recorded
- Completed turns: 10-turn acceptance pass completed
- Route choice encountered: no blocker reported where encountered
- Property Buy/Skip encountered: no blocker reported where encountered
- Rent encountered: no blocker reported where encountered
- Snapshot join or reconnect check: no blocker reported where encountered
- Result: pass

## Turn Evidence Table

| Turn # | Acting player | Control window | Action path | Dice / decision | Host state summary | Client state summary | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1-10 | Mixed | Owner manual run | Networked 10-turn pass | Not itemized | Owner reported normal operation with synchronized Host state | Owner reported no Client divergence | Pass |

## Snapshot / Reconnect Evidence

| Check | Expected observation | Actual observation | Result |
| --- | --- | --- | --- |
| Mid-run join or reconnect status | Client reports joined or `Reconnected as Pn` | No blocker reported | Pass |
| Snapshot revision | Client status includes `synced snapshot #n` | No blocker reported | Pass |
| Seat assignment | Reconnect returns to the same seat when using the same local reconnect token | No blocker reported | Pass |
| State comparison | Round, active player, money, positions, ownership, pending action, dice, landed tile, event text, and recent log lines match Host | Owner reported no state divergence | Pass |
| Continued play | Rejoined or reconnected Client can act when its controlled seat becomes active | No blocker reported | Pass |

## Current Acceptance Read

Automated regression checks pass, and owner-reported manual acceptance on issue #33 passed. No state divergence, stuck pending action, or P0 blocker was reported.
