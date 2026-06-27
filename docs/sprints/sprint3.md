# Sprint3

Start date: TBD

## Sprint Goal

Establish `v0.2-online-core` confidence by validating that 2-4 players can complete a 10-turn networked prototype run without state divergence, stuck pending actions, or unclear Host-authoritative failure states.

## Sprint Integration Branch

Use `codex/sprint3-online-core-stability` as the Sprint3 integration branch.

Issue workflow:

1. Branch each Sprint3 issue from `codex/sprint3-online-core-stability`.
2. Open each issue PR with base branch `codex/sprint3-online-core-stability`.
3. Merge only issue-sized PRs into the Sprint3 branch during the sprint.
4. Open one final Sprint3 PR from `codex/sprint3-online-core-stability` into `main` after the full sprint acceptance pass.

## Sprint Scope

- Update planning docs after Sprint2 merge.
- Define a networked 10-turn acceptance checklist and evidence format.
- Run or prepare the manual networked acceptance pass.
- Verify Roll, route choice, Buy, Skip, rent, snapshot sync, and reconnect behavior during online-core testing.
- Review whether debug status is enough to record Host-authoritative failures.
- Record a `v0.2-online-core` readiness recommendation.

## Out Of Scope

- No card system.
- No special event or building implementation.
- No stock market system.
- No room code, matchmaking, public lobby, or production account system.
- No broad UI redesign.
- No full automation framework unless a narrow smoke script is clearly needed for acceptance.

## Sprint Backlog Candidates

| Backlog ID | Issue | Status | Work item | Acceptance |
| --- | --- | --- | --- | --- |
| PB-026 | [#31](https://github.com/benson94879453/rich-war-online/issues/31) | In Progress | Update post-Sprint2 planning baseline | Roadmap, MVP scope, Sprint3 plan, and backlog reflect that P0.3 reconnect is complete and Sprint3 targets online-core stability. |
| PB-027 | [#32](https://github.com/benson94879453/rich-war-online/issues/32) | Planned | Define networked 10-turn acceptance pass | Manual checklist and evidence format define how to validate 2-4 networked players for 10 turns without divergence. |
| PB-028 | [#33](https://github.com/benson94879453/rich-war-online/issues/33) | Planned | Run networked 10-turn acceptance pass | Evidence records at least 10 networked turns or a named blocker, including Host/Client state comparison. |
| PB-029 | [#34](https://github.com/benson94879453/rich-war-online/issues/34) | Planned | Review network authority failure visibility | Testers can clearly record joined/reconnected/spectator status, snapshot sync, rejected intents, and pending-action failures. |
| PB-030 | [#35](https://github.com/benson94879453/rich-war-online/issues/35) | Planned | Record v0.2-online-core readiness review | Sprint3 evidence is summarized with a clear ready/not-ready recommendation for moving toward events, buildings, or cards. |

## Acceptance Criteria

- Sprint2 completion is reflected in current planning docs.
- A tester can run the documented networked 10-turn scenario from the active scene.
- Host and Client stay synchronized for turn, money, positions, ownership, pending action, dice, landed tile, event text, and recent log lines.
- Route choice, Buy, Skip, rent, join snapshot, and reconnect observations are recorded where encountered.
- Any divergence, script error, stuck pending action, or unclear authority failure becomes a named blocker.
- Sprint3 ends with an explicit recommendation: ready for event/building work, or continue online-core stabilization.

## Review Notes

Sprint3 should protect the foundation before the project moves into more expressive gameplay systems. Events, buildings, cards, and stock mechanics will multiply state transitions, so the online core should first prove it can survive repeated networked turns with clear acceptance evidence.
