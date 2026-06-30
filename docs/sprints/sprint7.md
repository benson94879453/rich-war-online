# Sprint7

Start date: 2026-06-30

## Sprint Goal

Establish the first `v0.4-card-window-loop` baseline by proving one narrow Host-authoritative card intervention window.

Sprint7 should not implement a full card game. The goal is to validate the smallest useful card path: a deterministic prototype card can exist in state, be validated through a narrow action path, resolve through existing effect boundaries, and leave the normal turn loop stable.

## Sprint Integration Branch

Use `codex/sprint7-card-window-baseline` as the Sprint7 integration branch.

Issue workflow:

1. Branch each Sprint7 issue from `codex/sprint7-card-window-baseline`.
2. Open each issue PR with base branch `codex/sprint7-card-window-baseline`.
3. Merge only issue-sized PRs into the Sprint7 branch during the sprint.
4. Open one final Sprint7 PR from `codex/sprint7-card-window-baseline` into `main` after Sprint7 acceptance is complete.

## Sprint Scope

- Record Sprint7 planning baseline and issue order.
- Add a minimal card definition and card service boundary.
- Activate existing reserved card state fields through explicit helper behavior.
- Add a narrow Host-authoritative card action intent envelope.
- Implement one deterministic pre-roll intervention card path.
- Add scenario smoke coverage for the prototype card window.
- Preserve existing Roll, route choice, Buy, Skip, rent, event landing, snapshot, reconnect, and map validation behavior.
- Record Sprint7 acceptance evidence and the next recommendation.

## Out Of Scope

- No full card deck system.
- No large card set.
- No random draw balancing.
- No counter-card chain or full priority stack.
- No production timer UX.
- No card art or final UI polish.
- No stock market, casino, lottery, or balance pass.
- No original map redesign.
- No broad `NetworkManager` or scene UI rewrite.

## Current Foundations

Sprint7 builds on the following completed boundaries:

- `ActionDispatcher` can validate Host-authoritative player actions.
- `TurnSystem` has intervention-oriented phase vocabulary available for extension.
- `GameState` already reserves snapshot fields for hands, decks, discards, statuses, and pending intervention state.
- `EffectService` can apply deterministic money-style effects through a shared result path.
- `EventService` proved a deterministic event effect path.
- `LandingResolutionService` reduced landing complexity and keeps the turn loop easier to extend.

## Proposed First Slice

The first card-window slice should be deliberately small:

- One deterministic prototype intervention card.
- One timing window: pre-roll.
- One successful path: a valid non-current player can play the card against the current player before roll resolution.
- One effect type: deterministic money-style effect through existing effect result concepts.
- One state transition: card moves from hand to discard after successful play.
- One validation path: invalid actor, target, card, or timing requests are rejected clearly.

If this slice becomes too large, prefer reducing UI/network surface before expanding card content.

## Sprint Backlog

| Backlog ID | Issue | Status | Work item | Acceptance |
| --- | --- | --- | --- | --- |
| PB-047 | [#81](https://github.com/benson94879453/rich-war-online/issues/81) | In Progress | Plan v0.4 card intervention window baseline | Sprint7 plan, scope, out-of-scope items, issue order, validation expectations, and branch strategy are documented. |
| PB-048 | [#82](https://github.com/benson94879453/rich-war-online/issues/82) | Planned | Add CardDefinition and CardService baseline | One prototype card definition can be validated and resolved through a focused service boundary. |
| PB-049 | [#83](https://github.com/benson94879453/rich-war-online/issues/83) | Planned | Activate card state snapshot helpers | Prototype hand, discard, and pending intervention state can be represented and round-tripped without changing snapshot keys. |
| PB-050 | [#84](https://github.com/benson94879453/rich-war-online/issues/84) | Planned | Add Host-authoritative card action intent envelope | Card-play action payloads can be accepted or rejected through a narrow Host-authoritative path without regressing existing actions. |
| PB-051 | [#85](https://github.com/benson94879453/rich-war-online/issues/85) | Planned | Implement prototype pre-roll intervention card | One fixed card can resolve in a valid pre-roll window, apply its effect, consume/discard the card, and let turn flow continue. |
| PB-052 | [#86](https://github.com/benson94879453/rich-war-online/issues/86) | Planned | Add card window scenario smoke coverage | A headless scenario proves the valid card-window path and key rejection or continuation behavior. |
| PB-053 | [#87](https://github.com/benson94879453/rich-war-online/issues/87) | Planned | Record v0.4 card window baseline acceptance review | Sprint7 evidence is summarized with remaining risks and a clear recommendation for the next card-system slice. |

## Recommended Order

1. Planning baseline.
2. Card definition and service boundary.
3. Card state snapshot helpers.
4. Card action intent envelope.
5. Prototype pre-roll intervention card.
6. Scenario smoke coverage.
7. Sprint7 acceptance review.

This order keeps state and service boundaries ahead of turn-window behavior, and keeps Host-authoritative action validation ahead of visible gameplay expansion.

## Acceptance Criteria

- Sprint7 planning is committed and linked to issue #81.
- A prototype card data/service boundary exists and has focused smoke coverage.
- Reserved card state fields can support the first card window without changing snapshot payload keys.
- A narrow card action intent can be validated under Host authority.
- One deterministic pre-roll intervention card path works through state, validation, effect resolution, and turn continuation.
- A scenario smoke protects the card-window path.
- Existing Roll, route choice, Buy/Skip, rent, event landing, snapshot, reconnect, and map validation checks remain stable.
- No full card deck, random draw, counter-card chain, timer UX, or broad UI rewrite is introduced.

## Validation Expectations

Minimum automated checks before Sprint7 closeout:

- `git diff --check`
- New card service smoke check.
- New or updated card state snapshot smoke check.
- New or updated card action dispatcher smoke check.
- New card-window scenario smoke check.
- Existing 10-roll local action pipeline scenario.
- Existing event landing scenario.
- Existing event/effect service smoke checks.
- Existing GameState snapshot and reserved-defaults smoke checks.
- Existing reconnect smoke checks relevant to snapshot and seat restoration.

Manual checks should be recorded only if actually executed:

- Local active scene turn flow through an unused pre-roll window.
- Local active scene valid prototype card play if UI controls are exposed.
- Host/Client card intent and snapshot sync if the card path is exposed through network controls.

## Known Risks

- `NetworkManager` is still a large transport and synchronization surface. Sprint7 should add only a narrow card intent unless a concrete blocker proves decomposition is required.
- `StarQGame.gd` is still the likely UI integration point and should not absorb full card-system complexity.
- `TurnSystem` has intervention vocabulary, but full priority, timeout, and counter-card semantics are not implemented.
- Snapshot compatibility remains part of the network sync contract; card fields must retain stable defaults.
- A visible card UX can grow quickly. Sprint7 should prefer headless validation and minimal control exposure over final UI.

## Review Notes

Sprint7 is the first v0.4 sprint. The expected output is not a complete card system; it is evidence that the architecture can carry one card timing window safely under Host authority.
