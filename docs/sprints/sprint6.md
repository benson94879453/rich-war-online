# Sprint6

Start date: 2026-06-29

## Sprint Goal

Reduce `GameManager` god-object risk before expanding special buildings, full event decks, cards, or intervention windows.

Sprint6 should be a behavior-preserving decomposition sprint. The goal is not to add new gameplay; it is to move stable responsibilities behind narrow service/helper boundaries while keeping the existing local, event, snapshot, reconnect, and map validation checks green.

## Sprint Integration Branch

Use `codex/sprint6-game-manager-decomposition` as the Sprint6 integration branch.

Issue workflow:

1. Branch each Sprint6 issue from `codex/sprint6-game-manager-decomposition`.
2. Open each issue PR with base branch `codex/sprint6-game-manager-decomposition`.
3. Merge only issue-sized PRs into the Sprint6 branch during the sprint.
4. Open one final Sprint6 PR from `codex/sprint6-game-manager-decomposition` into `main` after Sprint6 acceptance is complete.

## Sprint Scope

- Record Sprint6 planning baseline and issue order.
- Extract snapshot UI summary tracking from `GameManager`.
- Extract property purchase and rent rules behind a focused boundary.
- Extract landing resolution orchestration behind a focused boundary.
- Preserve current public `GameManager` action and snapshot APIs.
- Preserve current event payloads consumed by UI, snapshot sync, and smoke checks.
- Record Sprint6 acceptance evidence and the next recommendation.

## Out Of Scope

- No full card system.
- No card hand, deck, discard, draw, or counter-card implementation.
- No timed intervention windows.
- No full event deck or random event table.
- No full special-building ownership, placement, or activation system.
- No stock market, lottery, casino, or production balance pass.
- No movement algorithm rewrite.
- No broad `NetworkManager` or scene UI rewrite.
- No intentional gameplay behavior changes.

## Current `GameManager` Responsibilities

`GameManager` currently owns several responsibilities that should not all remain coupled as future gameplay expands:

- Game bootstrap and restore.
- Runtime references to board data, navigators, services, turn system, and RNG.
- Public action entry points for Roll, route choice, Buy, and Skip.
- Legacy board movement and active grid movement continuation.
- Landing resolution, including tile lookup, property offer, rent, tile effects, event effects, and turn completion.
- Snapshot payload creation and restore.
- Snapshot UI summary state and text formatting.
- Event emission through `EventBus`.

Sprint6 should not attempt to split all of this at once. It should remove isolated responsibilities first, then put a clearer boundary around landing resolution.

## Sprint Backlog

| Backlog ID | Issue | Status | Work item | Acceptance |
| --- | --- | --- | --- | --- |
| PB-042 | [#68](https://github.com/benson94879453/rich-war-online/issues/68) | In Progress | Plan GameManager decomposition baseline | Sprint6 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-043 | [#69](https://github.com/benson94879453/rich-war-online/issues/69) | Planned | Extract snapshot summary tracking from GameManager | Snapshot UI summary state and formatting are delegated while snapshot payload compatibility remains intact. |
| PB-044 | [#70](https://github.com/benson94879453/rich-war-online/issues/70) | Planned | Extract property purchase and rent resolution boundary | Current Buy, Skip, insufficient-funds, purchase offer, and rent behavior live behind a focused boundary without behavior changes. |
| PB-045 | [#71](https://github.com/benson94879453/rich-war-online/issues/71) | Planned | Extract landing resolution orchestration boundary | Landing sequencing delegates through a focused resolver while property, rent, money tile, and `starq_chance` behavior remains stable. |
| PB-046 | [#72](https://github.com/benson94879453/rich-war-online/issues/72) | Planned | Record GameManager decomposition acceptance review | Sprint6 evidence is summarized with remaining risks and a clear recommendation for the next gameplay-system slice. |

## Recommended Order

1. Planning baseline.
2. Snapshot summary extraction.
3. Property purchase/rent boundary.
4. Landing resolution boundary.
5. Sprint6 acceptance review.

This order starts with the least gameplay-risky state extraction, then isolates property rules before landing resolution delegates to a smaller orchestration surface.

## Acceptance Criteria

- Sprint6 planning is committed and linked to issue #68.
- `GameManager` no longer directly owns snapshot UI summary state and formatting.
- Property purchase and rent rules have a focused boundary while public action behavior remains compatible.
- Landing resolution has a focused boundary while existing tile/effect/event behavior remains compatible.
- Existing Roll, route choice, Buy/Skip, rent, money tile, `starq_chance`, map validation, reconnect, and snapshot smoke checks remain stable.
- No new gameplay feature behavior is introduced.
- Any failed automated or manual check is recorded as a named blocker or explicitly deferred risk.

## Validation Expectations

Minimum automated checks before Sprint6 closeout:

- `git diff --check`
- Existing event landing scenario.
- Existing 10-roll local action pipeline scenario.
- Existing event service smoke check.
- Existing event landing binding smoke check.
- Existing EffectService smoke check.
- Existing ActionDispatcher smoke check.
- Existing GameState snapshot smoke checks.
- Existing map validation smoke check.
- Existing reconnect smoke checks relevant to snapshot and seat restoration.

Manual checks should be recorded only if actually executed:

- Local active scene turn flow through Roll, route choice, Buy, Skip, rent, and `starq_chance`.
- Host/Client roll and snapshot sync if landing or snapshot code paths are touched in a way not covered by smoke checks.

## Known Risks

- `GameManager` still owns movement continuation and public action entry points after this sprint.
- Landing resolution extraction may need small callback/dependency boundaries for event emission, turn completion, and pending property decisions.
- Snapshot UI summary compatibility is part of the network sync contract and should not change shape.
- Behavior-preserving refactors can still break event ordering; scenario smoke checks are required for each implementation PR.
- Larger special-building and card timing-window work should wait until these decomposition boundaries prove stable.

## Review Notes

Sprint6 is an architecture stabilization sprint after Sprint5 proved the first Host-authoritative event slice. The expected output is a smaller, clearer `GameManager`, not a new player-facing feature.
