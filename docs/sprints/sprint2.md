# Sprint2

Start date: TBD

## Sprint Goal

Establish the `P0.3-reconnect-baseline` so a disconnected Client can reconnect to the same in-progress match, reclaim the same player seat, receive a fresh Host snapshot, and continue playing without hiding seat ownership failures behind prototype Host controls.

## Sprint Integration Branch

Use `codex/sprint2-reconnect-baseline` as the Sprint2 integration branch.

Issue workflow:

1. Branch each Sprint2 issue from `codex/sprint2-reconnect-baseline`.
2. Open each issue PR with base branch `codex/sprint2-reconnect-baseline`.
3. Merge only issue-sized PRs into the Sprint2 branch during the sprint.
4. Open one final Sprint2 PR from `codex/sprint2-reconnect-baseline` into `main` after the full sprint acceptance pass.

## Sprint Scope

- Add a prototype reconnect identity token for Clients.
- Send reconnect identity during join or reconnect.
- Let the Host reserve disconnected player seats for the active match.
- Let a reconnecting Client reclaim its reserved player seat.
- Send a fresh `GameState` snapshot after reconnect.
- Make connection and seat state visible enough for manual QA.
- Update manual reconnect validation evidence.

## Out Of Scope

- No account login or secure authentication.
- No room code, matchmaking, or lobby system.
- No long-term persistence after Host exit.
- No cross-device reconnect guarantee.
- No card system.
- No stock market or casino system.
- No map importer or map resource rewrite.
- No final UI/UX pass beyond necessary debug visibility.

## Sprint Backlog Candidates

| Backlog ID | Issue | Status | Work item | Acceptance |
| --- | --- | --- | --- | --- |
| PB-021 | [#20](https://github.com/benson94879453/rich-war-online/issues/20) | Done | Add reconnect identity token lifecycle | Client creates a prototype reconnect token before joining, keeps it for the prototype session, and can resend it when joining the same Host again. |
| PB-022 | [#21](https://github.com/benson94879453/rich-war-online/issues/21) | Done | Add Host seat reservation model | Host tracks peer-to-player, token-to-player, and reserved player seats; disconnected seats are not treated as open seats while the match is active. |
| PB-023 | [#22](https://github.com/benson94879453/rich-war-online/issues/22) | Done | Reassign matching reconnect token to reserved seat | A Client reconnecting with a known token returns to the same player seat and does not receive a fresh unrelated seat. |
| PB-024 | [#23](https://github.com/benson94879453/rich-war-online/issues/23) | Done | Refresh snapshot and debug status after reconnect | Host sends a fresh snapshot after reseating; Client UI reflects current turn, round, money, positions, ownership, pending action, dice, landed tile, event text, and recent log lines. |
| PB-025 | [#24](https://github.com/benson94879453/rich-war-online/issues/24) | In Progress | Run Sprint2 reconnect acceptance pass | Automated reconnect smoke evidence is recorded; manual two-window QA still needs human execution. |

## Acceptance Evidence

- `docs/sprints/sprint2_acceptance.md` records automated smoke results for reconnect token lifecycle, Host reservation, reserved-seat reassignment, reconnect status/snapshot messaging, GameState snapshot restore, and active map validation.
- Manual two-window acceptance remains pending human execution before Sprint2 is closed into `main`.

## Suggested Issue Order

1. Define the reconnect token and join handshake path in `scripts/network/NetworkManager.gd`.
2. Add Host-side reservation state and make open-seat lookup ignore reserved seats.
3. Reconnect matching tokens to reserved seats and send a fresh snapshot.
4. Tighten debug status and checklist coverage so failures are visible.
5. Run and record the full manual acceptance pass.

## Acceptance Criteria

- A Client that disconnects and rejoins with the same prototype token returns to the same player seat.
- The Host does not assign the reserved seat to another peer while the match remains active.
- A Client without a matching token receives the next available non-reserved seat or spectator state.
- The reconnecting Client receives a fresh Host snapshot after reseating.
- Reconnected UI matches Host state for turn, round, money, positions, property ownership, pending action, dice text, landed tile text, event text, and recent log lines.
- The reconnecting Client can act when its reclaimed player seat becomes active.
- `Host controls open seats` remains useful for prototype testing but does not allow reserved seats to mask reconnect failures.

## Review Notes

Sprint2 is a networking baseline sprint. It should make reconnect behavior observable, testable, and stable enough to unblock later online-authority work. If implementation risk grows, keep the sprint centered on same-seat reconnect and move broader lobby or automation work to later issues.
