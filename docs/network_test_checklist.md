# Network Test Checklist

Use this checklist for each multiplayer prototype pass.

## Setup

- Start two desktop/editor game windows.
- In window A, click `Host`.
- In window B, keep `ws://127.0.0.1:8910` and click `Join`.
- Confirm window A reports the peer joined.
- Confirm window B reports it connected as P2.

## Basic Turn Sync

- P1 rolls from Host.
- Confirm both windows show the same dice value.
- Confirm both windows animate P1 to the same node.
- P2 rolls from Client.
- Confirm both windows show the same dice value.
- Confirm both windows animate P2 to the same node.
- Repeat until at least one route choice appears.

## Route Choice

- Trigger a route choice on the active player.
- Confirm only the controlling window shows usable route buttons.
- Choose a route.
- Confirm both windows move the piece along the same path.
- Confirm no duplicate route rejection appears in the log.

## Property Decision

- Land on an unowned property.
- Confirm only the controlling window shows `Buy` / `Skip`.
- Click `Buy` when affordable.
- Confirm both windows update money and property owner.
- Click `Buy` when unaffordable.
- Confirm the log shows `cannot afford` without an extra rejected intent.
- Click `Skip`.
- Confirm both windows advance to the next turn.

## Pending Intent Lock

- On Client, double-click `Buy`, `Skip`, route choice, or `Roll`.
- Confirm only one intent is processed.
- Confirm no stale `no property decision pending` entry appears in the visible log.

## Snapshot Join

- Start a game on Host and advance several turns.
- Join from Client after the game has already started.
- Confirm current round and active player match Host.
- Confirm piece positions match Host.
- Confirm money values match Host.
- Confirm property ownership marks match Host.
- Confirm dice text matches Host.
- Confirm landed tile text matches Host.
- Confirm event text and recent log lines are not stale local startup values.
- If Host is waiting on a property decision, confirm Client shows the correct controls only when Client controls that player.
- If Host is waiting on a route choice, confirm Client shows route controls only when Client controls that player.

## Host Open Seat Control

- On Host, leave `Host controls open seats` enabled.
- Confirm Host can operate P1 and any unassigned players.
- Disable `Host controls open seats`.
- Confirm Host can only operate its own seat.
- Re-enable it before broad 4-player prototype testing.

## Reconnect Smoke Test

- Disconnect or close Client while game is in progress.
- Reopen Client and join Host again.
- Confirm Client receives a fresh snapshot.
- Confirm no local stale opening state remains visible after sync.
- Note current limitation: reseating to the same player is not finalized yet.

## Pass Criteria

- 10 turns can be played across two windows without state divergence.
- Normal actions do not produce misleading rejected intent logs.
- Client joining mid-game matches Host state for turn, dice, landed tile, event text, money, positions, and property owners.
- Pending action buttons appear only for the controlling player.
