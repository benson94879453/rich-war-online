# Sprint8

Start date: 2026-07-01

## Sprint Goal

Establish the first visible `v0.4-card-playtest-ui` baseline by turning the Sprint7 headless prototype card window into a minimal active-scene card playtest surface.

Sprint8 should not implement a full card game. The goal is to make the existing prototype pre-roll card path visible, asset-backed enough for testing, easy to tune, and manually verifiable without locking in final UI polish.

## Sprint Integration Branch

Use `codex/sprint8-visible-card-playtest` as the Sprint8 integration branch.

Issue workflow:

1. Branch each Sprint8 issue from `codex/sprint8-visible-card-playtest`.
2. Open each issue PR with base branch `codex/sprint8-visible-card-playtest`.
3. Merge only issue-sized PRs into the Sprint8 branch during the sprint.
4. Open one final Sprint8 PR from `codex/sprint8-visible-card-playtest` into `main` after Sprint8 acceptance is complete.

## Sprint Scope

- Record Sprint8 planning baseline and issue order.
- Define a minimal standard Godot card test asset intake guide.
- Bind the prototype card to visible metadata and an optional test asset reference.
- Draft a visible card UI wireframe/spec and require user confirmation before UI implementation.
- Implement a minimal active-scene card hand UI only after the wireframe/spec is confirmed.
- Add a visible card playtest manual checklist.
- Preserve existing Sprint7 card-window smoke/scenario coverage.
- Record Sprint8 acceptance evidence and next recommendation.

## Out Of Scope

- No full card deck system.
- No random draw, shuffle, or balance pass.
- No large card set.
- No priority stack, counter-card chain, or production timer UX.
- No final card art, final UI polish, or accessibility pass.
- No broad `NetworkManager`, `StarQGame`, or `GameManager` rewrite.
- No Host/Client card UI acceptance claim unless it is actually run and recorded.

## User-Confirmed UI Direction

- Card display location: bottom of the active scene, with hand layout inspired by Slay the Spire.
- Hand panel visibility: always visible.
- Inactive card window state: hand panel remains visible but disabled/gray.
- Active pre-roll window state: hand panel returns to normal color and becomes interactive.
- Card proportion: vertical card shape inspired by Balatro.
- Card inspection: an enlarged view is required.
- Interaction model: first slice is the pre-roll card window only.
- Roll relationship: current player can directly Roll to skip an unused card window.
- Asset usage: use standard Godot asset/import behavior with clear path and naming rules.

## UI Confirmation Gate

The active-scene card UI implementation is blocked until issue #99 records a wireframe/spec and the user confirms it.

The implementation issue must keep these values easy to adjust:

- Card width and height.
- Hand panel anchor and margins.
- Card overlap, fan angle, and spacing.
- Disabled opacity, saturation, or modulation.
- Active-state colors.
- Hover/click inspect scale and position.
- Asset path or fallback placeholder behavior.

## Current Foundations

Sprint8 builds on the following completed boundaries:

- `CardDefinition` and `CardService` can define and resolve one deterministic prototype card.
- `GameState` has explicit helpers for hands, deck card lists, discard piles, and pending intervention metadata.
- `ActionDispatcher.ACTION_PLAY_CARD` validates card intents under Host authority.
- `NetworkManager.submit_play_card(...)` exposes a narrow card intent envelope.
- The prototype pre-roll card path can resolve through `CardService`, consume/discard the card, and continue normal roll flow.
- `scenario_card_window_pipeline.gd` protects the headless card-window path.

## Sprint Backlog

| Backlog ID | Issue | Status | Work item | Acceptance |
| --- | --- | --- | --- | --- |
| PB-054 | [#96](https://github.com/benson94879453/rich-war-online/issues/96) | Done | Plan visible card playtest baseline | Sprint8 plan, scope, out-of-scope items, UI gate, issue order, validation expectations, and branch strategy are documented. |
| PB-055 | [#97](https://github.com/benson94879453/rich-war-online/issues/97) | Done | Define card test asset pipeline guide | Standard Godot asset paths, naming, ratio guidance, and fallback behavior are documented. |
| PB-056 | [#98](https://github.com/benson94879453/rich-war-online/issues/98) | Done | Bind prototype card metadata to test asset reference | Prototype card metadata can support a visible card surface with optional test art and safe fallback behavior. |
| PB-057 | [#99](https://github.com/benson94879453/rich-war-online/issues/99) | Done | Draft visible card UI wireframe and implementation spec | Bottom-hand UI, disabled/active states, inspect behavior, tunable parameters, and user-confirmation gate are documented. |
| PB-058 | [#100](https://github.com/benson94879453/rich-war-online/issues/100) | In Review | Implement minimal active-scene card hand UI | After #99 confirmation, the prototype card can be seen, inspected, played during pre-roll, or skipped by rolling. |
| PB-059 | [#101](https://github.com/benson94879453/rich-war-online/issues/101) | Planned | Add visible card playtest manual checklist | Manual checks cover inactive/active hand states, inspect, card play, roll skip, and Host/Client pending status. |
| PB-060 | [#102](https://github.com/benson94879453/rich-war-online/issues/102) | Planned | Record visible card playtest acceptance review | Sprint8 evidence is summarized with manual QA status, remaining risks, and a merge recommendation. |

## Recommended Order

1. Planning baseline.
2. Card test asset pipeline guide.
3. Prototype card metadata and optional asset reference.
4. Visible card UI wireframe/spec for user confirmation.
5. Minimal active-scene card hand UI, only after #99 is confirmed.
6. Visible card playtest manual checklist.
7. Sprint8 acceptance review.

This order keeps test assets and metadata ahead of UI, and keeps UI implementation blocked until the user confirms the wireframe/spec.

## Acceptance Criteria

- Sprint8 planning is committed and linked to issue #96.
- Test asset path, naming, ratio, and fallback rules are documented.
- Prototype card metadata can support a visible card surface without requiring final assets.
- The visible card UI wireframe/spec is confirmed before implementation starts.
- Minimal active-scene UI shows an always-visible bottom hand panel with inactive and active states.
- Prototype card can be inspected, played during the pre-roll window, or skipped by direct Roll.
- Manual card playtest checklist exists and records manual QA honestly.
- Existing card-window scenario, card smoke, snapshot, reconnect, and map validation checks remain stable.

## Validation Expectations

Minimum automated checks before Sprint8 closeout:

- `git diff --check`
- `godot --headless --path . --script res://tools/scenarios/scenario_card_window_pipeline.gd`
- `godot --headless --path . --script res://tools/smoke_prototype_pre_roll_card.gd`
- `godot --headless --path . --script res://tools/smoke_action_dispatcher.gd`
- `godot --headless --path . --script res://tools/smoke_card_service.gd`
- `godot --headless --path . --script res://tools/smoke_card_hand_ui.gd`
- `godot --headless --path . --script res://tools/smoke_game_state_card_state.gd`
- `godot --headless --path . --script res://tools/smoke_game_state_snapshot.gd`
- `godot --headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd`

Manual checks should be recorded only if actually executed:

- Active scene shows bottom hand panel in inactive gray state.
- Active pre-roll window shows hand panel in normal interactive state.
- Prototype card can be enlarged for inspection.
- Prototype card can be played and visibly affects the target player.
- Direct Roll skips the unused card window.
- Host/Client card UI behavior remains pending unless a two-window pass is actually run.

## Known Risks

- Visible card UI can expand quickly into final UX work. Sprint8 should stay prototype/debug-focused.
- `GameManager` still owns temporary prototype card-window orchestration from Sprint7.
- The UI path may expose tension between local debug flow and future Host/Client card intent UX.
- Assets prepared for Sprint8 are test assets, not final product art.
- Headless checks cannot fully prove visual layout quality; manual active-scene QA remains necessary for UI acceptance.

## Review Notes

Sprint8 should produce a playable visual slice, not a production card system. If UI implementation grows beyond the confirmed wireframe/spec, split the work or defer it.
