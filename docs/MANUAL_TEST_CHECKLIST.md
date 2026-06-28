# Manual Test Checklist

Baseline date: 2026-06-26

Use this checklist before treating the current prototype as baseline-ready after gameplay, networking, or snapshot changes.

Use `docs/MAP_VALIDATION_CHECKLIST.md` before treating map resource, spawn, route, tile placement, or property marker changes as baseline-ready.

## Test Environment

- Godot version is 4.6.x stable.
- Main scene is `res://scenes/StarQGame.tscn`.
- Do not use `res://scenes/Main.tscn` or `res://scenes/StarQMap.tscn` for baseline validation.
- Use two desktop/editor game windows unless a test states otherwise.
- Window A is Host.
- Window B is Client.
- Default Client address is `ws://127.0.0.1:8910`.

## 1. Local Smoke Test

- Start one game window.
- Confirm the board, pieces, UI, and log are visible.
- Confirm the current round is shown.
- Confirm the active player is shown.
- Roll for several turns.
- Confirm the dice label updates after each roll.
- Confirm the active player changes after each completed turn.
- Confirm money values remain visible.
- Confirm no immediate script errors are shown.

## 1.5 4-Player Local Core Loop

Use this section for `v0.1-local-core-loop` acceptance.

- Start `res://scenes/StarQGame.tscn` in one local game window.
- Confirm P1, P2, P3, and P4 pieces are visible.
- Confirm the money label includes P1, P2, P3, and P4.
- Confirm the first active turn is P1.
- Play 20 completed turns.
- Confirm turn order repeats P1, P2, P3, P4.
- Confirm dice text updates after every roll.
- Confirm each active player's piece moves to the displayed landing node.
- Trigger at least one route choice if the board path allows it.
- Confirm Roll is disabled while route choice is pending.
- Choose a route.
- Confirm movement continues and route buttons disappear.
- Buy at least one affordable property if offered.
- Skip at least one property if offered.
- Trigger rent if the dice path allows it.
- Confirm Buy / Skip controls disappear after each property decision.
- Confirm money text updates after purchases, rent, and tile money effects.
- Confirm no script errors are shown during the run.
- Record the result using the evidence format in `docs/releases/v0.1-local-core-loop.md`.

## 2. Host / Client Setup

- Start two game windows.
- In window A, click `Host`.
- In window B, keep `ws://127.0.0.1:8910` and click `Join`.
- Confirm window A reports that a peer joined.
- Confirm window B reports that it connected.
- Confirm window B receives a player seat or spectator state.
- Confirm both windows show the same current round and active player after sync.

## 3. Basic Turn Sync

- Roll for P1 from Host.
- Confirm both windows show the same dice value.
- Confirm both windows animate P1 to the same node.
- Confirm both windows show the same landing tile text.
- Roll for P2 from Client when it is P2's turn.
- Confirm both windows show the same dice value.
- Confirm both windows animate P2 to the same node.
- Repeat until at least one route choice or property decision appears.

## 4. Route Choice

- Trigger a route choice on the active player.
- Confirm only the controlling window shows usable route buttons.
- Confirm the non-controlling window does not expose usable route buttons.
- Choose a route.
- Confirm both windows move the piece along the same path.
- Confirm the route buttons disappear after the choice is accepted.
- Confirm no duplicate route rejection appears in the log.

## 5. Property Decision

- Land on an unowned affordable property.
- Confirm only the controlling window shows `Buy` / `Skip`.
- Click `Buy`.
- Confirm both windows update money.
- Confirm both windows update the property owner marker.
- Land on an unowned unaffordable property.
- Click `Buy`.
- Confirm the log shows `cannot afford`.
- Confirm no extra `game rejected intent` appears for the unaffordable purchase path.
- Land on another unowned property.
- Click `Skip`.
- Confirm both windows hide property actions.
- Confirm both windows advance to the next turn.

## 6. Pending Intent Lock

- On Client, double-click `Roll`.
- Confirm only one roll intent is processed.
- On Client, double-click a route choice button.
- Confirm only one route choice is processed.
- On Client, double-click `Buy`.
- Confirm only one purchase intent is processed.
- On Client, double-click `Skip`.
- Confirm only one skip intent is processed.
- Confirm no stale `no property decision pending` entry appears in the visible log after accepted Buy or Skip resolution.

## 7. Snapshot Join

- Start a game on Host.
- Advance several turns.
- Buy at least one property if possible.
- Leave Host running.
- Start or reconnect a Client after the game has already advanced.
- Confirm current round matches Host.
- Confirm active player matches Host.
- Confirm piece positions match Host.
- Confirm money values match Host.
- Confirm property ownership marks match Host.
- Confirm dice text matches Host.
- Confirm landed tile text matches Host.
- Confirm event text is not a stale local startup value.
- Confirm recent log lines are not stale local startup values.
- If Host is waiting on a property decision, confirm Client shows controls only when Client controls that player.
- If Host is waiting on a route choice, confirm Client shows route controls only when Client controls that player.

## 8. Host Open Seat Control

- On Host, leave `Host controls open seats` enabled.
- Confirm Host can operate P1.
- Confirm Host can operate any unassigned players.
- Disable `Host controls open seats`.
- Confirm Host can only operate its own seat.
- Confirm Host cannot operate Client-owned seats.
- Re-enable it before broad 4-player prototype testing.

## 9. Reconnect Smoke Test

Use this section as a broad reconnect smoke test. Same-seat reconnect is required for `P0.3-reconnect-baseline`, but it remains outside `v0.1-local-core-loop`.

- Connect Client to Host.
- Advance at least one Client-owned turn.
- Disconnect or close Client while game is in progress.
- Reopen Client and join Host again.
- Confirm Client network status reports `Reconnected as Pn`.
- Confirm Client network status includes `synced snapshot #n`.
- Confirm Client receives a fresh snapshot.
- Confirm no local stale opening state remains visible after sync.
- Confirm the game remains playable after rejoin.
- Record whether the Client returned to the same seat.

## 9.5 P0.3 Same-Seat Reconnect Acceptance

Use this section for the next networking baseline defined in `docs/reconnect_baseline.md`.

- Start Host in window A.
- Join from Client in window B.
- Record the Client player seat.
- Advance until the Client has completed at least one owned turn.
- Disconnect or close window B.
- Keep Host running.
- Reopen window B and join the same Host.
- Confirm Client returns to the same player seat.
- Confirm Client network status reports `Reconnected as Pn`.
- Confirm Client network status includes `synced snapshot #n`.
- Confirm Host did not assign the reserved seat to another peer.
- Confirm Client receives a fresh snapshot.
- Confirm current round, active player, money, piece positions, property ownership, pending action, dice, landed tile, event text, and recent log lines match Host.
- Confirm the reconnecting Client can act when that same player seat becomes active.

## 10. Long Turn Stability

Use `docs/sprints/sprint3_networked_10_turn_acceptance.md` for the full `v0.2-online-core` acceptance procedure and evidence format.
Use `docs/sprints/sprint3_authority_failure_visibility.md` when a networked run exposes rejected intents, unclear controls, stale pending actions, join/reconnect confusion, or snapshot status ambiguity.

- Play at least 10 turns across two windows.
- Include at least one Host roll.
- Include at least one Client roll.
- Include at least one property decision if the board path allows it.
- Include at least one route choice if the board path allows it.
- Include a mid-run snapshot join or reconnect check if the run is for Sprint3 acceptance.
- Compare Host and Client state after each completed turn: round, active player, money, positions, ownership, pending action, dice, landed tile, event text, and recent log lines.
- Confirm both windows remain in sync.
- Confirm no misleading rejected intent logs appear during normal accepted actions.
- If a rejected intent appears, record the exact Client event text and Host network status text.
- If an action is blocked, record whether the controlling window had visible controls and whether non-controlling windows hid those controls.

## Baseline Pass Criteria

- One local window can complete the 4-player `v0.1-local-core-loop` check.
- Two windows can connect through Host / Client flow.
- 10 turns can be played without state divergence.
- Roll, movement, route choice, Buy, and Skip stay Host-authoritative.
- Pending action buttons appear only for the controlling player.
- Client joining mid-game matches Host state for turn, dice, landed tile, event text, money, positions, and property owners.
- Reconnect returns to the same seat when the local prototype reconnect token is still available.
