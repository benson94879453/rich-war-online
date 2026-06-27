# Sprint3 Authority Failure Visibility Review

Date: 2026-06-27

Branch under review: `codex/issue-34-authority-failure-visibility`

Sprint integration branch baseline: `codex/sprint3-online-core-stability`

## Purpose

This review documents whether Sprint3 testers can identify network authority failures while running `v0.2-online-core` acceptance. It focuses on what is visible in the current debug UI, event log, and manual checklist.

## Current Visibility Surfaces

| Area | Current signal | Source | Review result |
| --- | --- | --- | --- |
| Client joined | Network status shows `Connected as Pn` | `NetworkManager._assign_local_player()` and `GameUI.set_network_status_text()` | Visible |
| Client spectator | Network status shows `Connected as spectator` | `NetworkManager._get_local_assignment_status_message()` | Visible |
| Client reconnected | Network status shows `Reconnected as Pn` | `NetworkManager._get_local_assignment_status_message()` | Visible |
| Snapshot sync | Network status includes `synced snapshot #n`; first snapshot also logs `Synced snapshot #n from host` | `NetworkManager._get_snapshot_status_message()` and `StarQGame._on_network_state_snapshot_received()` | Visible |
| Host rejected Client intent | Host network status shows `Rejected <intent> from peer <id>: <reason>` | `NetworkManager._reject_intent()` | Visible |
| Client rejected intent | Client network status and event log show `Rejected <intent>: <reason>` | `NetworkManager._receive_intent_rejected_with_request()` and `StarQGame._on_network_intent_rejected()` | Visible |
| Stale property rejection noise | Stale `no property decision pending` after accepted Buy/Skip is filtered locally | `StarQGame._is_stale_property_rejection()` | Mitigated |
| Pending property controls | Buy/Skip controls appear only when the local peer can control the pending property player | `StarQGame._refresh_pending_action_controls()` | Visible by control state |
| Pending route controls | Route controls appear only when local control and route state allow resolution | `StarQGame._show_pending_route_choice()` / refresh path | Visible by control state |
| Client pending intent lock | Client controls are hidden or Roll disabled while a submitted intent is pending | `StarQGame._begin_pending_client_intent()` | Visible by control state |

## Tester Recording Rules

When a networked acceptance run exposes an authority failure, record:

- Window role: Host, Client, reconnecting Client, or spectator.
- Network status text from the affected window.
- Event log text from the affected window.
- Current round and active player.
- Visible controls: Roll, route buttons, Buy, Skip.
- Intended action and actual rejection reason.
- Whether Host state and Client state diverged after the failure.
- Whether snapshot status includes a revision number.

## Required Manual Probes

Use these probes during or after the Sprint3 10-turn acceptance run when possible:

- Non-controlling player action: confirm the action is unavailable or produces a clear rejection reason.
- Duplicate Client action: confirm only one intent is processed and stale rejection noise is absent.
- Route-choice ownership: confirm only the controlling window can resolve route choice.
- Property-decision ownership: confirm only the controlling window can Buy or Skip.
- Mid-run join or reconnect: confirm joined/reconnected/spectator status and snapshot revision are visible.
- Host-side rejection: if a rejection occurs, confirm Host status names the rejected intent and peer id.
- Client-side rejection: if a rejection occurs, confirm Client status or log names the rejected intent and reason.

## Known Limits

- The UI is still a debug UI, not final player-facing UX.
- Rejection history is not stored in a structured test report; testers must copy status/log text into the evidence comment.
- Pending intent state is visible through disabled/hidden controls, not through a dedicated pending-intent label.
- Host peer ids are useful for QA but not final user-facing identifiers.

## Current Acceptance Read

The current debug UI and checklists are sufficient for Sprint3 QA visibility. No code change is required for issue #34. Future UX work can replace these debug strings with a structured network diagnostics panel.
