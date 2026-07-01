# Card UI Wireframe

This document defines the Sprint8 visible card UI wireframe and implementation spec for issue #99.

Status: pending user confirmation before active-scene UI implementation.

The goal is to make the existing Sprint7 prototype pre-roll card path visible in `res://scenes/StarQGame.tscn` without turning Sprint8 into a final card UX pass.

## Scope

In scope:

- Bottom hand layout for the active scene.
- Always-visible hand panel with inactive and active states.
- One prototype pre-roll card surface backed by `CardDefinition` visible metadata.
- Enlarged card inspection behavior.
- Play Card and Roll skip behavior for the pre-roll window.
- Tunable layout and visual parameters for issue #100.

Out of scope:

- No full deck UI.
- No random draw, shuffle, discard viewer, or card collection screen.
- No final card art, final visual polish, or accessibility pass.
- No Host/Client card UI acceptance claim unless separately tested and recorded.
- No broad rewrite of `GameManager`, `StarQGame`, or `GameUI`.

## User-Confirmed Direction

The following decisions were confirmed before this spec:

- Card display location: bottom of the active scene.
- Layout reference: hand presentation inspired by Slay the Spire.
- Hand panel visibility: always visible.
- Inactive state: visible but disabled/gray when no usable card window is available.
- Active state: normal color and interactive during the pre-roll card window.
- Card proportion: vertical card shape inspired by Balatro.
- Card inspection: an enlarged view is required.
- Interaction model: first visible slice is the pre-roll window only.
- Roll relationship: the current player can directly Roll to skip an unused card window.
- Test asset flow: use standard Godot asset/import behavior.

## Screen Placement

The hand panel should live in the active `GameUI` CanvasLayer and anchor to the bottom center of the viewport.

The current UI already occupies:

- Top-left: network panel.
- Right side: log and status panels.
- Center and left: board view.

The hand panel should avoid the right-side status column and leave the map readable.

Recommended desktop placement:

```text
+------------------------------------------------------------------+
| Network panel                                      Log panel      |
|                                                                  |
|                                                                  |
|                       Board / pieces                             |
|                                                                  |
|                                                                  |
|                                        Status panel              |
|                                                                  |
|             [     bottom card hand panel     ]                   |
+------------------------------------------------------------------+
```

Panel behavior:

- Anchor bottom center.
- Keep the panel width constrained so it does not collide with the right-side status panel.
- Keep enough bottom margin that cards do not touch the viewport edge.
- Do not hide the Roll button; Roll remains the skip path when the card window is unused.

## Hand States

The hand panel has two required states.

### Inactive State

Use when no playable card window is available.

Expected behavior:

- Panel remains visible.
- Card slots/cards are disabled.
- Visuals are gray, desaturated, dimmed, or otherwise clearly inactive.
- Hover/click inspect may either be disabled or show read-only inspection, but Play Card must not be available.
- Roll availability continues to follow the existing turn rules.

### Active Pre-Roll State

Use when `GameState.pending_intervention` exposes a playable pre-roll card for the locally controlled player.

Expected behavior:

- Panel returns to normal color.
- Playable card is highlighted enough to distinguish it from inactive state.
- Card can be inspected.
- Play Card action submits the existing card-play intent.
- Direct Roll remains available and skips the unused card window by following the existing roll path.

## Card Surface

The Sprint8 card surface should use metadata from `CardDefinition.get_visible_metadata()`.

Required visible fields:

- `display_name`
- `effect_summary`
- `target_summary`
- `art_path`

Recommended card content:

```text
+----------------------+
| Prototype pre-roll   |
| grant                |
|                      |
| [art or fallback]    |
|                      |
| +$50 to current      |
| player               |
|                      |
| Target: Current      |
| player               |
+----------------------+
```

Fallback behavior:

- If `art_path` is empty or missing, show a functional fallback card surface.
- Missing art must not block active-scene startup, Roll, or Play Card.
- The fallback must still show the card name and effect summary.

## Inspect Behavior

Inspection is required for Sprint8 because the bottom hand card may be small.

Recommended behavior:

- Hover or click/tap enlarges the focused card.
- The enlarged card should appear above the hand panel, centered on the focused card or near bottom center.
- The enlarged card should not cover the right-side Roll button/status panel more than necessary.
- The enlarged card should preserve the same metadata and art/fallback surface.
- The inspect state should close when focus leaves, the card is clicked again, or another action starts.

Issue #100 can choose hover-first for desktop and click/tap fallback for touch/web compatibility.

## Pre-Roll Interaction

The first visible Sprint8 slice only supports the prototype pre-roll card window.

Allowed paths:

1. Active pre-roll card window appears.
2. Current player either plays the prototype card or directly rolls.
3. If the card is played, the card resolves through the existing card service path, leaves the hand, enters discard, and the turn can continue to Roll.
4. If Roll is pressed first, the unused card window is skipped and normal roll flow continues.

The UI must not invent a separate Skip Card button in Sprint8. Roll is the skip action for this prototype.

## Implementation Boundary For Issue #100

Recommended affected files:

- `res://scenes/UI.tscn`
- `res://scripts/core/GameUI.gd`
- `res://scripts/core/StarQGame.gd`

Recommended optional split if the node/script grows:

- `res://scenes/CardHandPanel.tscn`
- `res://scripts/core/CardHandPanel.gd`

Implementation notes:

- Keep the hand UI as an owned child of `GameUI`.
- Expose focused signals from the UI layer, such as `card_play_pressed(card_id, window_id, target_player_id)`.
- Let `StarQGame` translate current `GameState.pending_intervention` and card metadata into UI state.
- Do not move card resolution logic into UI scripts.
- Do not duplicate `ActionDispatcher` validation rules in UI; UI only enables the obvious local interaction.

## Tunable Parameters

Issue #100 should keep these values local and easy to adjust:

| Parameter | Initial recommendation |
| --- | --- |
| Card ratio | 5:7 vertical |
| Hand card size | 120 x 168 px desktop prototype |
| Inspect card size | 240 x 336 px desktop prototype |
| Hand anchor | Bottom center |
| Hand panel width | 720 px max desktop prototype |
| Bottom margin | 24 px |
| Card spacing | 18 px when only one card is present |
| Card overlap | 32 px overlap allowance for future multiple-card fan |
| Fan angle | 0 degrees for one card; keep configurable for future hands |
| Disabled opacity | 45 percent |
| Disabled modulation | Neutral gray/desaturated |
| Active highlight | Subtle border or brighter modulation |
| Inspect scale | 2.0x from hand size, capped by viewport |
| Missing asset fallback | Plain card background plus text metadata |
| Art fit | Preserve aspect ratio inside the card art area |
| Z order | Inspect above hand panel and below modal/debug overlays |

These values are prototype defaults, not product design decisions.

## Confirmation Gate

Issue #100 is blocked until the user confirms this spec.

Before implementation starts, confirm:

- Bottom-center hand placement is acceptable with the current right-side debug/status panels.
- The inactive gray panel should still show the prototype card instead of showing an empty slot.
- Hover/click inspect behavior is acceptable for the first desktop/web slice.
- Roll as the only skip path is acceptable for Sprint8.
- The listed tunable parameters are sufficient for quick UI adjustment after playtest.

If any of these decisions change, update this document before implementing the active-scene UI.

## Validation

For this documentation-only issue:

```bash
git diff --check
```

Manual visual validation belongs to issue #100 and the Sprint8 manual checklist.
