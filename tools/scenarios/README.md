# Scenario Smoke Checks

Scenario smoke checks exercise a short gameplay flow across multiple systems. They are broader than single-purpose smoke scripts and should stay deterministic enough for headless execution.

Use scenarios for flow-level regressions such as:

- Action dispatch through `ActionDispatcher`.
- Turn phase transitions through `TurnSystem`.
- Movement, route choice, landing, property decisions, rent, and effect plumbing.
- Snapshot or reconnect behavior after a meaningful game flow.

Keep each scenario narrow:

- Prefer one gameplay story per file.
- Use the active board resource unless the scenario explicitly needs a fixture.
- Fail on rejected actions, stuck pending state, script errors, or missing required data.
- Do not add new gameplay features inside scenario scripts.

Run the local 10-roll action pipeline scenario with:

```bash
godot --headless --path . --script res://tools/scenarios/scenario_10_roll_local_action_pipeline.gd
```

Run the event landing pipeline scenario with:

```bash
godot --headless --path . --script res://tools/scenarios/scenario_event_landing_pipeline.gd
```

Run the card window pipeline scenario with:

```bash
godot --headless --path . --script res://tools/scenarios/scenario_card_window_pipeline.gd
```

The event landing scenario targets the active-map `starq_chance` effect id. It finds a deterministic grid roll path to the selected event tile, submits the roll through `ActionDispatcher`, verifies the prototype event money result, and checks snapshot round-trip state. Later building, card, or intervention-window scenarios should follow this pattern: force one narrow active-board path, submit through the public action pipeline, assert exact state deltas, and then round-trip the snapshot fields owned by that slice.

The card window scenario starts from the active board, verifies the deterministic prototype pre-roll card window, proves an invalid actor rejection, resolves the valid card play through `ActionDispatcher`, checks the effect/consume/discard state, round-trips the owned card snapshot fields, and confirms the current player can continue into a roll.
