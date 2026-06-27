# Same-Seat Reconnect Baseline

Baseline date: 2026-06-26

This document defines the smallest reconnect behavior for the next playable networking baseline. It does not change `v0.1-local-core-loop`; that release remains local-first and accepts reconnect as a known limitation.

## Decision

Same-seat reconnect is required for the next networking baseline after `v0.1-local-core-loop`.

Target milestone:

> `P0.3-reconnect-baseline`

The goal is not a production account system. The goal is to prove that a disconnected Client can return to the same in-progress local prototype match and continue controlling the same player seat.

## Required Behavior

- Host remains authoritative.
- A Client has a reconnect identity token.
- Host maps reconnect identity tokens to player seats.
- When a Client disconnects, the Host reserves that seat instead of immediately making it available to new peers.
- When the same Client reconnects with the same identity token, the Host reassigns that Client to the reserved seat.
- Host sends a fresh `GameState` snapshot after reconnect.
- The reconnecting Client sees the same turn, round, money, positions, property ownership, pending action, dice text, landed tile text, event text, and recent log lines as Host.
- Host open-seat control remains a prototype convenience, but it must not hide reconnect failures during acceptance.

## Prototype Identity Model

For the first reconnect baseline, use a generated client token rather than accounts:

- Client creates a random reconnect token before joining.
- Client persists the token locally for the prototype session.
- Client sends the token when joining or reconnecting.
- Host stores `token -> player_id` and `player_id -> disconnected/reserved` state.

This token is not security. It is a prototype continuity key.

## Seat Reservation

Minimum accepted behavior:

- A disconnected player seat remains reserved for the current match.
- Reserved seats are not assigned to new peers while the match is active.
- Reconnect succeeds if the returning Client supplies the same token.
- A Client with no matching token receives the next available open seat or spectator state.

Deferred behavior:

- Account login.
- Secure authentication.
- Room codes.
- Matchmaking.
- Cross-device reconnect guarantees.
- Long-term persistence after Host exits.

## Manual Acceptance

Use two local Godot windows:

1. Window A starts Host.
2. Window B joins as Client and receives a player seat.
3. Advance until the Client has completed at least one owned turn.
4. Record the Client player seat.
5. Close or disconnect Window B.
6. Continue at least one Host-controllable turn if possible.
7. Reopen Window B and join the same Host.
8. Confirm Window B returns to the same player seat.
9. Confirm Window B receives a fresh snapshot.
10. Confirm money, piece positions, property ownership, turn, round, pending action, dice, landed tile, event text, and recent log lines match Host.
11. Confirm Window B can act when that same player seat becomes active.

## Pass Criteria

- Reconnecting Client returns to the same player seat.
- Reconnecting Client does not receive a fresh unrelated seat.
- Host does not assign the reserved seat to another peer.
- The restored Client UI matches Host state after snapshot sync.
- The game remains playable after reconnect.

## Failure Criteria

- Reconnecting Client receives a different active player seat.
- Reconnecting Client becomes spectator when its seat should be reserved.
- Host assigns the disconnected seat to another peer before the original Client returns.
- Snapshot after reconnect is stale or missing core state.
- The match becomes stuck after reconnect.

## Current Status

Current implementation supports the baseline mechanics: the Client stores its reconnect token in local Godot user data, the Host reserves disconnected seats, matching tokens reclaim reserved seats, and reconnect snapshots are sent with a fresh revision.

Manual two-window acceptance was reported passed on issue #24 after the reserved-seat token mismatch bug was fixed.
