# Sprint3 Networked 10-Turn Acceptance

Date: TBD

Branch under test: TBD

Sprint integration branch baseline: `codex/sprint3-online-core-stability`

## Purpose

This checklist defines the `v0.2-online-core` acceptance pass for Sprint3. It verifies that the Host-authoritative network core can sustain at least 10 completed networked turns without state divergence, stuck pending actions, or unclear failure visibility.

## Test Topology

Primary topology:

- Window A: Host.
- Window B: Client using `ws://127.0.0.1:8910`.
- `Host controls open seats` may stay enabled so the Host can advance unassigned seats during a 4-seat prototype run.

Optional topology:

- Add windows C and D as extra Clients if local resources allow.
- Record which player seat each window controls before turn 1.

## Preconditions

- Use `res://scenes/StarQGame.tscn`.
- Do not use legacy/demo scenes.
- Start from a clean game session.
- Record Godot version, platform, branch, and commit.
- Confirm no script errors appear immediately after launch.
- Confirm Window B joins and receives a player seat or spectator state.
- Confirm Host and Client show matching round, active player, money, positions, property ownership, dice, landed tile, event text, and recent log lines before turn 1.

## Required Coverage

The 10-turn pass should include:

- At least 10 completed turns.
- At least one Host-controlled roll.
- At least one Client-controlled roll.
- At least one route choice if the board path presents one.
- At least one property Buy or Skip if an unowned property is reached.
- At least one rent observation if an owned property is reached.
- One mid-run snapshot join or reconnect check.
- A Host/Client state comparison after every completed turn.

If a route choice, property decision, or rent case does not appear naturally in 10 turns, record `not encountered` instead of forcing unrelated setup.

## Procedure

1. Start Window A and click `Host`.
2. Start Window B, keep `ws://127.0.0.1:8910`, and click `Join`.
3. Record Window B seat assignment and network status.
4. Confirm both windows show matching baseline state.
5. Play until 10 turns are completed.
6. After each completed turn, fill one row in the turn evidence table.
7. When a route choice appears, confirm only the controlling window can choose a route.
8. When Buy or Skip appears, confirm only the controlling window can submit the property decision.
9. When rent appears, confirm money and ownership remain synchronized after resolution.
10. During turns 4-8, run one snapshot join or reconnect check:
    - Snapshot join: open a new Client window and join mid-game.
    - Reconnect: close Window B, reopen it, and join the same Host.
11. Confirm the joined or reconnected Client matches Host state after snapshot sync.
12. Continue until the 10-turn pass either completes or hits a blocker.

## Turn Evidence Table

| Turn # | Acting player | Control window | Action path | Dice / decision | Host state summary | Client state summary | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | P? | A/B/C/D | Roll / route / Buy / Skip / rent |  | Round, active player, money, positions, ownership, pending action, dice, landed tile, event text, recent log lines | Same fields | Pass / Fail |
| 2 | P? | A/B/C/D |  |  |  |  |  |
| 3 | P? | A/B/C/D |  |  |  |  |  |
| 4 | P? | A/B/C/D |  |  |  |  |  |
| 5 | P? | A/B/C/D |  |  |  |  |  |
| 6 | P? | A/B/C/D |  |  |  |  |  |
| 7 | P? | A/B/C/D |  |  |  |  |  |
| 8 | P? | A/B/C/D |  |  |  |  |  |
| 9 | P? | A/B/C/D |  |  |  |  |  |
| 10 | P? | A/B/C/D |  |  |  |  |  |

## Snapshot / Reconnect Evidence

| Check | Expected observation | Actual observation | Result |
| --- | --- | --- | --- |
| Mid-run join or reconnect status | Client reports joined or `Reconnected as Pn` |  | Pass / Fail |
| Snapshot revision | Client status includes `synced snapshot #n` |  | Pass / Fail |
| Seat assignment | Reconnect returns to the same seat when using the same local reconnect token |  | Pass / Fail / Not applicable |
| State comparison | Round, active player, money, positions, ownership, pending action, dice, landed tile, event text, and recent log lines match Host |  | Pass / Fail |
| Continued play | Rejoined or reconnected Client can act when its controlled seat becomes active |  | Pass / Fail / Not encountered |

## Failure Conditions

Mark the run failed and create or link a blocker issue if any of these happen:

- A script error appears during the run.
- Host and Client disagree on round, active player, money, positions, property ownership, pending action, dice, landed tile, event text, or recent log lines after snapshot sync.
- A player turn cannot advance.
- Movement reaches a route choice but no controlling window can resolve it.
- Buy, Skip, or rent leaves the game stuck in a pending state.
- A Client can submit an action for a player it should not control.
- A normal accepted action produces misleading rejected-intent noise.
- Reconnect loses the previous seat while the same local reconnect token is available.
- A failure occurs but the UI/status/log does not make the cause recordable.

Use `docs/sprints/sprint3_authority_failure_visibility.md` to classify whether the failure was visible enough to diagnose.

## Pass Criteria

The pass is successful when:

- At least 10 networked turns complete.
- Host and Client state comparison passes after every completed turn.
- Required coverage is recorded, or unencountered route/property/rent cases are explicitly marked `not encountered`.
- Snapshot join or reconnect evidence passes.
- No failure condition occurs.

## Evidence Summary

Use this summary when commenting on issue #33:

```md
## Sprint3 Networked 10-Turn Acceptance Evidence

- Date:
- Branch / commit:
- Godot version:
- Windows used:
- Player seat mapping:
- Host controls open seats: on/off
- Completed turns:
- Route choice encountered: yes/no
- Property Buy/Skip encountered: yes/no
- Rent encountered: yes/no
- Snapshot join or reconnect check: pass/fail
- Result: pass/fail

## Notes
- ...

## Blockers
- None / #...
```
