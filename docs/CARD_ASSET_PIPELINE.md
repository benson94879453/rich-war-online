# Card Asset Pipeline

This document defines the Sprint8 test asset intake rules for visible prototype card playtesting.

The goal is to support temporary test art through standard Godot import behavior without creating a custom asset pipeline or final card-art system.

## Scope

In scope:

- Test card art paths and naming conventions.
- Recommended card image ratio and working dimensions.
- Standard Godot import expectations.
- Placeholder and missing-asset fallback behavior.
- Metadata expectations for the prototype visible card surface.

Out of scope:

- No custom importer.
- No production card-frame template.
- No final card art direction.
- No deck database.
- No random draw or card set balancing.

## Asset Paths

Use these paths for Sprint8 test card art:

```text
res://assets/cards/test/
```

Recommended examples:

```text
res://assets/cards/test/prototype_pre_roll_grant.png
res://assets/cards/test/prototype_pre_roll_grant_hover.png
```

Do not put card art under `res://resources/cards/` during Sprint8. Reserve `resources` for Godot `Resource` data, not bitmap art.

If `res://assets/cards/test/` does not exist yet, create it when the first test asset is added. Empty folders do not need to be committed.

## Naming

Use the card id as the base filename:

```text
<card_id>.png
```

Rules:

- Use lowercase snake_case.
- Match the runtime `card_id` exactly where possible.
- Prefer `.png` for transparent or UI-edited test assets.
- Use `.webp` only if file size becomes a real issue.
- Avoid spaces, uppercase, localization text, version suffixes, and exported design-tool names.

For the current prototype card:

```text
card_id: prototype_pre_roll_grant
asset:   res://assets/cards/test/prototype_pre_roll_grant.png
```

## Image Ratio And Size

Sprint8 card art should use a vertical card shape inspired by Balatro-style proportions.

Recommended working size:

```text
420 x 588 px
```

Acceptable ratio:

```text
5:7 vertical
```

Minimum useful test size:

```text
300 x 420 px
```

The UI implementation should not assume an exact pixel size. It should fit the asset into the configured card rectangle while preserving aspect ratio.

## Import Settings

Use standard Godot import behavior.

Recommended manual import expectations for test card art:

- Import as texture.
- Keep alpha enabled if the image has transparent corners or frame details.
- Avoid mipmaps unless visual testing shows scaled cards need them.
- Do not rely on per-file import tweaks for gameplay behavior.
- Do not hand-edit `.import` files unless there is a concrete Godot import problem.

The source image file is the tracked asset. Godot-generated `.import` metadata can be committed when Godot creates it as part of normal asset import, but Sprint8 should not require custom import scripts.

## Metadata Binding

Card metadata should be able to reference a test art path without requiring the art file to exist.

Required visible metadata for Sprint8:

- `card_id`
- display name
- short description or effect summary
- timing window
- target rule or target summary
- optional art path

The prototype card should be able to render from metadata plus fallback visuals if `art_path` is empty or the file is missing.

Runtime metadata is owned by `CardDefinition`. Sprint8 visible-card metadata includes:

- `display_name`
- `description`
- `effect_summary`
- `target_summary`
- `art_path`

The current prototype card defaults to:

```text
card_id:        prototype_pre_roll_grant
display_name:   Prototype pre-roll grant
effect_summary: +$50 to current player
target_summary: Current player
art_path:       res://assets/cards/test/prototype_pre_roll_grant.png
```

The default art path is a reference only. The file does not need to exist for smoke checks or gameplay to pass.

## Missing Asset Fallback

Missing art must not break gameplay, smoke checks, or active-scene startup.

Fallback behavior:

- If a card art path is empty, show a simple generated/default card surface.
- If a card art path is set but the file cannot be loaded, show the fallback surface and log a warning at most once per card id.
- The card should still show its display name and effect summary.
- Headless card smoke checks should not require bitmap assets.

Fallback visuals are allowed to be plain and functional. They are not final art.

## UI Implementation Expectations

The active-scene card UI should treat assets as replaceable test content.

Implementation should keep these values easy to adjust:

- Card rectangle width and height.
- Hand-panel bottom anchor and margins.
- Hand overlap and fan/offset.
- Disabled modulation, opacity, or grayscale behavior.
- Inspect/enlarged-card scale.
- Fallback card colors and text.

Do not hard-code layout values in multiple unrelated files. Keep prototype constants near the UI component that owns them.

## Current Prototype Asset Contract

For Sprint8, the only required card-art contract is:

```text
prototype_pre_roll_grant -> res://assets/cards/test/prototype_pre_roll_grant.png
```

This asset is optional. The UI and metadata layer must work without it.

## Validation

For documentation-only asset guide changes:

```bash
git diff --check
```

For future metadata or UI changes that reference card assets:

```bash
godot --headless --path . --script res://tools/smoke_card_service.gd
godot --headless --path . --script res://tools/scenarios/scenario_card_window_pipeline.gd
```

Manual active-scene validation should confirm:

- Card art appears when the test asset exists.
- Fallback card surface appears when the test asset is missing.
- Missing art does not block Roll or Play Card.
