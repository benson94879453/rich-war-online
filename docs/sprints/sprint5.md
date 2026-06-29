# Sprint5

Start date: 2026-06-29

## Sprint Goal

Start `v0.3-event-building-loop` with the smallest Host-authoritative event slice: introduce a reusable event-resolution layer, bind one active-map event-like landing path to it, and prove the path with headless scenario smoke coverage.

Sprint5 should validate that the Sprint4 foundations can carry a real gameplay-system extension before adding special buildings, full event decks, cards, intervention windows, or stock-market behavior.

## Sprint Integration Branch

Use `codex/sprint5-event-building-loop` as the Sprint5 integration branch.

Issue workflow:

1. Branch each Sprint5 issue from `codex/sprint5-event-building-loop`.
2. Open each issue PR with base branch `codex/sprint5-event-building-loop`.
3. Merge only issue-sized PRs into the Sprint5 branch during the sprint.
4. Open one final Sprint5 PR from `codex/sprint5-event-building-loop` into `main` after Sprint5 acceptance is complete.

## Sprint Scope

- Record Sprint5 planning baseline and issue order.
- Add a minimal event definition/service layer that can resolve one fixed money event.
- Bind one safe active-map event-like tile landing to the event service.
- Keep event resolution Host-authoritative through the existing landing pipeline.
- Add headless smoke coverage for the event landing path.
- Record Sprint5 acceptance evidence and the next recommendation.

## Out Of Scope

- No full card system.
- No card hand, deck, discard, draw, or counter-card implementation.
- No timed intervention windows.
- No full event deck or random event table.
- No full special-building ownership or placement system.
- No stock market or casino system.
- No broad `GameManager`, `NetworkManager`, or scene UI rewrite.
- No production balance pass.

## Sprint Backlog

| Backlog ID | Issue | Status | Work item | Acceptance |
| --- | --- | --- | --- | --- |
| PB-037 | [#56](https://github.com/benson94879453/rich-war-online/issues/56) | Done | Record event/building loop planning baseline | Sprint5 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-038 | [#57](https://github.com/benson94879453/rich-war-online/issues/57) | Done | Add EventDefinition and EventService baseline | A small event service can resolve one fixed money event through the existing effect/result path without adding full decks or cards. |
| PB-039 | [#58](https://github.com/benson94879453/rich-war-online/issues/58) | Done | Bind prototype event resolution to active tile landings | One selected active-map event-like tile resolves through the event service while existing property, rent, route, and money tile behavior stays stable. |
| PB-040 | [#61](https://github.com/benson94879453/rich-war-online/issues/61) | Done | Add event landing scenario smoke coverage | A headless scenario smoke path proves the selected event landing resolves and round-trips through snapshot state. |
| PB-041 | [#59](https://github.com/benson94879453/rich-war-online/issues/59) | Done | Record event/building loop acceptance review | Sprint5 evidence is summarized with a clear recommendation for moving from first event slice toward buildings or card timing windows. |

## Recommended Order

1. Planning baseline.
2. `EventService` baseline.
3. Active tile landing binding.
4. Event landing scenario smoke.
5. Sprint5 acceptance review.

This order proves the reusable event-resolution path before touching active landing behavior, then locks the new path with scenario coverage before closeout.

## Acceptance Criteria

- Sprint5 planning is committed and linked to issue #56.
- A minimal event service exists and can apply one fixed money event through the existing effect/result path.
- One selected event-like active-map tile path resolves through the event service during landing resolution.
- Existing Roll, route choice, property Buy/Skip, rent, money tile, map validation, reconnect, and snapshot smoke checks remain stable.
- Scenario smoke coverage proves the selected event landing path and snapshot round-trip.
- No full cards, random event deck, special-building ownership system, stock market, or broad UI rewrite is introduced.
- Any failed automated or manual check is recorded as a named blocker or explicitly deferred risk.

## Validation Expectations

Minimum automated checks before Sprint5 closeout:

- `git diff --check`
- New event service smoke check.
- New event landing scenario smoke check.
- Existing 10-roll local action pipeline scenario.
- Existing EffectService smoke check.
- Existing GameState snapshot smoke checks.
- Existing map validation smoke check.
- Existing reconnect smoke checks relevant to snapshot and seat restoration.

Manual checks should be recorded only if actually executed:

- Local active scene turn flow landing on the selected event-like tile.
- Host/Client roll and snapshot sync if the landing path touches visible gameplay.

## Known Risks

- Active-map event ids such as `starq_chance`, `starq_lottery_bet`, and `starq_type_*` are prototype placeholders, not final content definitions.
- If the selected event-like tile is hard to reach naturally, scenario smoke may need a controlled setup instead of random rolling.
- `GameManager` still owns landing sequencing; Sprint5 should use a narrow service boundary instead of attempting a broad decomposition.
- Event results must remain deterministic in smoke checks until a later sprint adds event decks or random content tables.
- Cards and intervention windows should remain deferred until one event slice proves stable under Host authority.

## Review Notes

Sprint5 is the first gameplay-system expansion after the online core and Sprint4 architecture foundation. The expected output is not a complete event/building system; it is a narrow proof that a new Host-authoritative gameplay effect can enter the turn loop, mutate state safely, appear in validation, and leave the project ready for a broader special-building or card-window sprint.

Closeout evidence is recorded in [sprint5_review.md](sprint5_review.md).
