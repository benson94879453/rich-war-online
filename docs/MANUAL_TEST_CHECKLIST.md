# Manual Test Checklist

Baseline date: 2026-06-26

Use this checklist before treating the current prototype as baseline-ready after gameplay, networking, or snapshot changes.

## Test Environment

- Godot version is 4.6.x stable.
- Main scene is `res://scenes/StarQGame.tscn`.
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

- Connect Client to Host.
- Advance at least one Client-owned turn.
- Disconnect or close Client while game is in progress.
- Reopen Client and join Host again.
- Confirm Client receives a fresh snapshot.
- Confirm no local stale opening state remains visible after sync.
- Confirm the game remains playable after rejoin.
- Record whether the Client returned to the same seat.

Known current limitation:

- Same-seat reseating is not finalized yet.

## 10. Long Turn Stability

- Play at least 10 turns across two windows.
- Include at least one Host roll.
- Include at least one Client roll.
- Include at least one property decision if the board path allows it.
- Include at least one route choice if the board path allows it.
- Confirm both windows remain in sync.
- Confirm no misleading rejected intent logs appear during normal accepted actions.

## Baseline Pass Criteria

- Two windows can connect through Host / Client flow.
- 10 turns can be played without state divergence.
- Roll, movement, route choice, Buy, and Skip stay Host-authoritative.
- Pending action buttons appear only for the controlling player.
- Client joining mid-game matches Host state for turn, dice, landed tile, event text, money, positions, and property owners.
- Known reconnect limitation is observed and recorded rather than treated as a surprise failure.

