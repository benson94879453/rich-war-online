# Visible Card Playtest Checklist

This checklist records manual QA for the Sprint8 visible card playtest baseline.

Use this document for `res://scenes/StarQGame.tscn` only. Do not mark any item passed unless it was actually run in the active scene.

## Status Legend

Use one of these values for every manual item:

- `Pending`: not run yet.
- `Pass`: run and matched the expected observation.
- `Fail`: run and did not match the expected observation.
- `Blocked`: could not run because of a setup, build, asset, or workflow blocker.

Evidence should include:

- Date.
- Branch or PR.
- Godot version.
- Local, Host, Client, or Host/Client setup.
- Short notes for any failure or unexpected behavior.

## Test Environment

Record before running:

```text
Date:
Branch or PR:
Godot version:
Build mode: editor / exported desktop / exported web
Window count: 1 / 2
Tester:
Notes:
```

Required baseline:

- Main scene is `res://scenes/StarQGame.tscn`.
- Godot version is 4.6.x stable.
- The card hand UI is the Sprint8 prototype surface, not production UX.
- Test art may be missing; fallback card visuals are acceptable.

## Automated Precheck

Run these before manual card QA when possible:

```bash
git diff --check
godot --headless --path . --script res://tools/smoke_card_hand_ui.gd
godot --headless --path . --script res://tools/scenarios/scenario_card_window_pipeline.gd
godot --headless --path . --script res://tools/smoke_prototype_pre_roll_card.gd
```

Record result:

| Check | Status | Notes |
| --- | --- | --- |
| `git diff --check` | Pending | |
| `smoke_card_hand_ui.gd` | Pending | |
| `scenario_card_window_pipeline.gd` | Pending | |
| `smoke_prototype_pre_roll_card.gd` | Pending | |

## Local Active-Scene Card UI

Run with one active scene window.

| Item | Status | Required observation | Notes |
| --- | --- | --- | --- |
| Scene startup | Pending | `StarQGame.tscn` opens without script errors. | |
| Hand placement | Pending | Bottom-center card hand panel is visible and does not cover the right-side status panel or Roll button. | |
| Inactive state | Pending | When no playable pre-roll card window is available, the hand remains visible but gray/disabled. | |
| Card metadata | Pending | The visible card shows the prototype card name and effect summary. | |
| Missing art fallback | Pending | Missing `prototype_pre_roll_grant.png` does not break the UI; fallback card surface appears. | |
| Inspect behavior | Pending | Hover or click/tap shows an enlarged card view above the hand panel. | |
| Inspect close behavior | Pending | Inspect view closes when focus changes, mouse leaves, or the card is toggled according to current behavior. | |
| Active state | Pending | During the pre-roll card window, the hand changes from disabled gray to normal/interactive state for the controlling player. | |
| Play Card | Pending | Pressing `Play Card` plays the prototype card and updates the target player's money by the card effect. | |
| Card consumed | Pending | After play, the card no longer remains playable in the hand for the used window. | |
| Roll after card | Pending | After playing the card, Roll remains available for the current player if the turn is still in pre-roll. | |
| Roll skip | Pending | Pressing Roll without using the card skips the unused card window and starts normal movement. | |
| No duplicate action | Pending | Repeated Play Card clicks do not apply duplicate effects. | |
| No stale UI | Pending | After Roll, movement, route choice, or property decision, the hand does not stay incorrectly active. | |

## Host / Client Card UI

Run only if two-window card UI QA is intentionally executed. Otherwise leave these items `Pending`.

Setup:

- Window A starts Host.
- Window B joins `ws://127.0.0.1:8910`.
- Record which player each window can control.

| Item | Status | Required observation | Notes |
| --- | --- | --- | --- |
| Host/Client setup | Pending | Both windows connect and show synchronized round/current player state. | |
| Controlling player active state | Pending | Only the window that can control the pending card actor can press `Play Card`. | |
| Non-controlling player inactive state | Pending | Non-controlling window shows the hand but cannot play the pending card. | |
| Network Play Card | Pending | Playing the prototype card from the controlling window applies the effect on Host and syncs to Client. | |
| Network Roll skip | Pending | Direct Roll skips the unused card window and both windows stay synchronized. | |
| Snapshot after card | Pending | After card play or Roll skip, money, pending action, dice, event text, and recent log lines match across windows. | |
| Rejected intent visibility | Pending | Any rejected card intent is visible enough to record attempted action and reason. | |

## Result Summary

Fill this after the run.

```text
Overall status: Pending / Pass / Fail / Blocked
Manual local active-scene QA:
Manual Host/Client QA:
Blocking issues:
Follow-up issues:
Recommendation for Sprint8 acceptance:
```

## Recording Rules

- Do not convert `Pending` Host/Client items to `Pass` unless a two-window run was actually executed.
- If a visual issue is acceptable for Sprint8 prototype scope, record it under notes instead of silently ignoring it.
- If gameplay diverges, money is applied twice, Roll becomes unavailable unexpectedly, or a non-controlling window can play the card, record the issue as a blocker for Sprint8 acceptance.
- If only layout polish is imperfect but Play Card and Roll skip work, record the issue as a follow-up candidate rather than a blocker unless it prevents testing.
