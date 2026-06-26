# Sprint1

Start date: TBD

## Sprint Goal

Establish the prototype map pipeline baseline so current map data becomes a managed Rich War Online asset rather than an implicit dependency.

## Sprint Scope

- Document the current map pipeline.
- Define the first internal map schema vocabulary.
- Inventory current board resource assumptions.
- Define map validation rules.
- Add or plan a repeatable map validation smoke check.
- Keep gameplay behavior unchanged unless a P0 blocker is found.

## Out Of Scope

- No card system.
- No stock market.
- No casino system.
- No new art.
- No production map editor.
- No 100% recreation of any reference game.
- No same-seat reconnect implementation.

## Sprint Backlog Candidates

| Backlog ID | Status | Work item | Acceptance |
| --- | --- | --- | --- |
| PB-014 / PB-015 | [#10](https://github.com/benson94879453/rich-war-online/issues/10) | Done | Document and refine map pipeline schema | `docs/MAP_PIPELINE.md` describes source, internal concepts, current resources, schema vocabulary, and known gaps. |
| PB-016 | [#11](https://github.com/benson94879453/rich-war-online/issues/11) | Done | Inventory active board resource | Current `starq_board.tres` assumptions and known gaps are documented. |
| PB-017 | [#12](https://github.com/benson94879453/rich-war-online/issues/12) | Done | Add map validation checklist | Manual checklist covers spawns, directions, junctions, tile mappings, and blocked movement risks. |
| PB-018 | [#13](https://github.com/benson94879453/rich-war-online/issues/13) | Done | Plan map validation smoke script | Script inputs, checks, pass/fail behavior, and implementation follow-up are defined. |
| PB-020 | [#16](https://github.com/benson94879453/rich-war-online/issues/16) | Done | Implement map validation smoke script | Add the planned headless Godot map validation script without broad test framework adoption. |

## Related Cleanup

- [#14](https://github.com/benson94879453/rich-war-online/issues/14): decide how to handle stale Godot temporary files. This is useful repo hygiene, but it should stay outside map pipeline scope unless it blocks review.

## Acceptance Criteria

- A new contributor can identify the active map resource.
- A new contributor can explain how map concepts relate to current Godot Resources.
- Validation expectations are documented before new map pipeline code is written.
- Prototype map dependency is documented as internal-only bootstrap material.
- No gameplay feature scope is added during this sprint.

## Review Notes

This sprint is planning and pipeline hardening. It should make later map importer, validation, and original-map work safer to assign as one-issue Codex tasks.
