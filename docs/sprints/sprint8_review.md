# Sprint8 Review

Review date: 2026-07-01

## Sprint Branch

`codex/sprint8-visible-card-playtest`

## Sprint Goal

Establish the first visible `v0.4-card-playtest-ui` baseline by turning the Sprint7 headless prototype pre-roll card window into a minimal active-scene card playtest surface.

Sprint8 intentionally did not implement a full card game. It created a narrow visible slice for one deterministic prototype pre-roll card, with documented asset rules, metadata, UI spec, active-scene hand panel, smoke coverage, and manual QA checklist.

## Completed Issues

| Issue | PR | Status | Result |
| --- | --- | --- | --- |
| [#96](https://github.com/benson94879453/rich-war-online/issues/96) Plan visible card playtest baseline | [#103](https://github.com/benson94879453/rich-war-online/pull/103) | Done | Sprint8 goal, scope, branch strategy, issue order, UI confirmation gate, validation expectations, and risks are documented. |
| [#97](https://github.com/benson94879453/rich-war-online/issues/97) Define card test asset pipeline guide | [#104](https://github.com/benson94879453/rich-war-online/pull/104) | Done | Standard Godot card test asset path, naming, ratio, import, metadata, and missing-art fallback expectations are documented. |
| [#98](https://github.com/benson94879453/rich-war-online/issues/98) Bind prototype card metadata to test asset reference | [#105](https://github.com/benson94879453/rich-war-online/pull/105) | Done | `CardDefinition` and `CardService` expose visible metadata and optional test art reference for the prototype card. |
| [#99](https://github.com/benson94879453/rich-war-online/issues/99) Draft visible card UI wireframe and implementation spec | [#106](https://github.com/benson94879453/rich-war-online/pull/106) | Done | Bottom hand layout, inactive/active states, inspect behavior, Roll skip path, and tunable implementation parameters are documented. |
| [#100](https://github.com/benson94879453/rich-war-online/issues/100) Implement minimal active-scene card hand UI | [#107](https://github.com/benson94879453/rich-war-online/pull/107) | Done | Active UI has an always-visible bottom card hand panel, disabled/active states, enlarged inspect behavior, and Play Card bridge through the existing card intent path. |
| [#101](https://github.com/benson94879453/rich-war-online/issues/101) Add visible card playtest manual checklist | [#108](https://github.com/benson94879453/rich-war-online/pull/108) | Done | Manual checklist records local active-scene card UI checks and keeps Host/Client checks pending unless actually run. |
| [#102](https://github.com/benson94879453/rich-war-online/issues/102) Record visible card playtest acceptance review | [#109](https://github.com/benson94879453/rich-war-online/pull/109) | Done | This document records Sprint8 evidence, manual QA status, risks, and merge recommendation. |

## Post-Review Fix

| Scope | PR | Status | Result |
| --- | --- | --- | --- |
| Sprint8 card hand compile fix | [#110](https://github.com/benson94879453/rich-war-online/pull/110) | Done | Added the missing `StarQGame._get_string_name(...)` helper used by the visible card hand pending-intervention bridge. This fixed editor errors for pending `window_id` and `card_id` parsing. |

## Implemented Changes

- Added `docs/CARD_ASSET_PIPELINE.md` for Sprint8 test card art intake.
- Added visible-card metadata fields on `CardDefinition`: description, effect summary, target summary, and optional art path.
- Updated the prototype pre-roll card in `CardService` with display metadata and a default optional test art reference.
- Added `docs/CARD_UI_WIREFRAME.md` as the user-confirmed UI spec for the visible card hand.
- Added `scripts/core/CardHandPanel.gd` as a focused active-scene card hand UI component.
- Updated `scenes/UI.tscn`, `scripts/core/GameUI.gd`, and `scripts/core/StarQGame.gd` to expose one visible card hand path without moving card resolution logic into UI code.
- Added `tools/smoke_card_hand_ui.gd` to validate the UI panel state and Play Card signal payload headlessly.
- Added `docs/VISIBLE_CARD_PLAYTEST_CHECKLIST.md` for manual local and Host/Client visible-card QA.
- Added a post-review `StarQGame` string-name parsing helper fix for the visible card hand path.
- Updated README, Sprint8, and product backlog documentation.

## Automated Validation

All closeout checks were rerun on `codex/issue-102-sprint8-review-refresh` after syncing from `origin/codex/sprint8-visible-card-playtest` through PR #110.

| Command | Result |
| --- | --- |
| `git diff --check` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/scenarios/scenario_card_window_pipeline.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_prototype_pre_roll_card.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_action_dispatcher.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_card_service.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_card_hand_ui.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_game_state_card_state.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_game_state_snapshot.gd` | Pass, exit code 0. |
| `godot --headless --path . --script res://tools/smoke_reconnect_status_snapshot.gd` | Pass, exit code 0. |
| `godot --headless --path . res://scenes/StarQGame.tscn --quit` | Pass, exit code 0. |

The local executable used for Godot checks was the configured Steam Godot 4.6.x tools binary.

## Manual QA

Manual active-scene card UI QA was not executed during this closeout by Codex.

Status:

- Local active-scene visible card QA: Pending.
- Host/Client visible card UI QA: Pending.
- Host/Client card UI acceptance claim: Not made.

Use `docs/VISIBLE_CARD_PLAYTEST_CHECKLIST.md` to record manual results before claiming manual acceptance. Host/Client checks must remain pending unless a two-window run is actually performed.

## Remaining Risks

- Headless checks validate the card hand signal path and existing card pipeline, but they do not prove visual quality, layout fit, or pointer feel in a real window.
- The card hand is intentionally prototype UI. It is not final UX, accessibility, art, animation, or responsive layout polish.
- `GameManager` still owns temporary prototype card seeding and pre-roll window preparation. This should be revisited before a larger card system.
- Host/Client visible card UI behavior is not manually accepted yet.
- The current visible slice supports one deterministic prototype card only. It does not prove deck, draw, timing priority, counter-card, or multi-card behavior.

## Recommended Merge Decision

Automated validation is ready.

Recommended decision: ready to open the final Sprint8 PR to `main` after this review refresh is merged into `codex/sprint8-visible-card-playtest`, with manual active-scene QA explicitly recorded as pending unless the owner runs `docs/VISIBLE_CARD_PLAYTEST_CHECKLIST.md` first.

If the project requires visual/manual acceptance before merging to `main`, block the final PR until at least the local active-scene section of `docs/VISIBLE_CARD_PLAYTEST_CHECKLIST.md` is executed and recorded.

## Merge Back To Main Checklist

- [x] Sprint branch is up to date through PR #110.
- [x] Sprint issue PRs #103 through #110 are merged into `codex/sprint8-visible-card-playtest`.
- [x] Closeout automated checks pass.
- [x] Manual QA status is honestly recorded as pending.
- [x] Remaining risks are documented.
- [x] #102 review PR is merged into `codex/sprint8-visible-card-playtest`.
- [ ] Review refresh PR is merged into `codex/sprint8-visible-card-playtest`.
- [ ] Open final PR from `codex/sprint8-visible-card-playtest` to `main`.

## Conclusion

Sprint8 met the automated and documentation side of its goal: the prototype card window now has a visible active-scene hand surface, asset/metadata guidance, headless UI smoke coverage, and a manual checklist for real-window validation.

The remaining decision is process-level: either run and record manual active-scene QA before the final merge, or merge with manual visual QA explicitly deferred.
