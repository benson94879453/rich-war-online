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
