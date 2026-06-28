# Sprint3 Readiness Review

Date: 2026-06-28

Sprint branch: `codex/sprint3-online-core-stability`

## Goal

Record whether `v0.2-online-core` is ready after Sprint3, and whether the next sprint can move toward events, buildings, or cards.

## Completed Issues

| Issue | Result |
| --- | --- |
| [#31](https://github.com/benson94879453/rich-war-online/issues/31) Update post-Sprint2 planning baseline | Done |
| [#32](https://github.com/benson94879453/rich-war-online/issues/32) Define networked 10-turn acceptance pass | Done |
| [#33](https://github.com/benson94879453/rich-war-online/issues/33) Run networked 10-turn acceptance pass | Done |
| [#34](https://github.com/benson94879453/rich-war-online/issues/34) Review network authority failure visibility | Done |
| [#35](https://github.com/benson94879453/rich-war-online/issues/35) Record v0.2-online-core readiness review | Done |

## Evidence Summary

- Sprint3 planning baseline exists in `docs/sprints/sprint3.md`.
- Networked 10-turn acceptance procedure exists in `docs/sprints/sprint3_networked_10_turn_acceptance.md`.
- Owner-reported 10-turn acceptance evidence is recorded in `docs/sprints/sprint3_networked_10_turn_evidence.md`.
- Authority failure visibility review is recorded in `docs/sprints/sprint3_authority_failure_visibility.md`.
- Automated smoke evidence recorded for GameState snapshot restore, active map validation, reconnect token lifecycle, Host seat reservation, reserved-seat reassignment, and reconnect status/snapshot messaging.

## v0.2-online-core Readiness

Decision: Ready.

Reasoning:

- Owner reported the networked 10-turn acceptance pass completed normally.
- No state divergence was reported.
- No stuck pending action was reported.
- No P0 blocker was reported.
- Current debug UI/status/log surfaces are sufficient for Sprint3 QA visibility.

## Known Risks

- Manual evidence is owner-reported and does not include itemized per-turn dice/state rows.
- Network testing is still local desktop/editor focused, not Web export focused.
- The UI remains a debug UI.
- Reconnect identity remains prototype-local Godot user data, not account-backed identity.
- No broad automated multiplayer simulation suite exists yet.

## Recommendation

Sprint3 can close as ready for merge-back.

The next sprint can move toward `v0.3-event-building-loop`, but should start with a narrow Host-authoritative gameplay-system slice:

1. Add one small event or special-building behavior.
2. Route it through existing turn/pending-action/snapshot patterns.
3. Validate that networked turns, snapshot sync, and reconnect remain stable.

Cards should still wait until at least one event/building loop proves stable under Host authority.

## Merge Back Checklist

- [x] Sprint branch is up to date.
- [x] Sprint issues #31-#35 are complete or ready to close with this review.
- [x] Automated smoke evidence is recorded.
- [x] Manual networked 10-turn acceptance is recorded.
- [x] Authority failure visibility is reviewed.
- [x] Final Sprint3 PR can be opened from `codex/sprint3-online-core-stability` to `main` after issue PRs are merged.
