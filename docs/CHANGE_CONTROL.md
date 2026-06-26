# Change Control

Baseline date: 2026-06-26

This document defines how scope and implementation changes are recorded during prototype development.

## Purpose

Rich War Online is moving from rapid exploration into a more formal prototype workflow. The goal of change control is to keep Scrum planning clear without slowing down prototype iteration.

Use this document when a change affects:

- MVP scope.
- Networking model.
- Game rules.
- Save or snapshot format.
- Manual QA expectations.
- Known limitations or release readiness.

## Change Levels

### Level 0: Local Implementation Detail

Examples:

- Refactoring private helper functions.
- Renaming local variables.
- Small UI label changes.
- Internal code cleanup with no behavior change.

Required action:

- Normal commit message is enough.

### Level 1: Prototype Behavior Change

Examples:

- Changing turn flow.
- Adding a new pending action.
- Changing property purchase behavior.
- Changing Client intent gating.
- Adding a new manual test expectation.

Required action:

- Update affected docs or checklist.
- Mention the behavior change in the commit body when useful.

### Level 2: MVP Scope Change

Examples:

- Moving intervention cards into or out of the current MVP.
- Adding same-seat reconnect as a required baseline pass criterion.
- Promoting a planned system into the active sprint.
- Removing a previously required MVP feature.

Required action:

- Update `docs/MVP_SCOPE.md`.
- Add a short entry to the Change Log section below.
- Confirm the change before implementation when the impact is uncertain.

### Level 3: Architecture Decision

Examples:

- Changing from Host-authoritative networking.
- Replacing WebSocket as the Web multiplayer path.
- Changing the snapshot format in a non-compatible way.
- Introducing a persistent backend service.

Required action:

- Create or update an Architecture Decision Record section in this file.
- Update `README.md` and `docs/MVP_SCOPE.md`.
- Include migration notes if existing prototype data or tests are affected.

## Commit Guidelines

Use concise conventional-style commits:

- `chore:` documentation, project setup, process, cleanup.
- `feat:` user-visible feature or prototype capability.
- `fix:` bug fix.
- `test:` manual or automated test coverage.
- `docs:` documentation-only changes.
- `refactor:` internal restructuring without intended behavior change.

Keep commits scoped to one story, bug, or process update when practical.

## Manual QA Policy

- Runtime verification is currently manual.
- Update `docs/MANUAL_TEST_CHECKLIST.md` when behavior changes.
- A story is not baseline-ready until its expected manual checks are documented.
- Known failures may be accepted only if they are listed under Known Issues or in the active sprint notes.

## Snapshot Compatibility Policy

GameState snapshots are part of the multiplayer contract. When changing snapshot content:

- Prefer additive keys.
- Keep old snapshots restorable when practical.
- Document new required keys in `docs/MVP_SCOPE.md` or the relevant implementation notes.
- Include a manual join/rejoin test whenever snapshot restore behavior changes.

## Architecture Decisions

### ADR-001: Host-Authoritative Multiplayer

Status: Accepted

Decision:

Clients submit intents. The Host validates, mutates game state, emits game events, and broadcasts state snapshots.

Reason:

This keeps game rules centralized, reduces cheating risk, and matches the Web multiplayer MVP target.

### ADR-002: WebSocket First For Web Prototype

Status: Accepted

Decision:

Use `WebSocketMultiplayerPeer` as the Web-compatible multiplayer path. Desktop ENet support remains planned but secondary.

Reason:

The project prioritizes Web playability, and ENet is not a Web fallback.

## Change Log

### 2026-06-26: Sprint0 Scrum Bootstrap

- Added GitHub issue forms for user stories, bugs, and sprint tasks.
- Added `docs/PRODUCT_BACKLOG.md` as the ordered Scrum backlog.
- Added `docs/sprints/sprint0.md` and `docs/releases/v0.1-local-core-loop.md`.
- Promoted the 4-player local core loop into the manual baseline checklist.
- Fixed route-choice payload handling for serialized direction arrays.
- Documented `StarQGame.tscn` as the only active baseline scene and marked older demo scenes outside sprint acceptance.
- Cleaned up GDScript reload warnings found during v0.1 manual QA.
- Added a lightweight GameState snapshot smoke script.
- Defined the `P0.3-reconnect-baseline` same-seat reconnect target and manual acceptance path.
- Added roadmap and map pipeline planning for the next sprint.
- Added an active board resource inventory for `starq_board.tres`.
- Added a manual map validation checklist for spawns, route choices, tile mappings, property markers, and failure records.
- Added a plan for the smallest useful headless map validation smoke script and split implementation into a follow-up issue.
- Implemented the headless map validation smoke script for the active board resource.
- Removed stale Godot temporary scene/resource artifacts and ignored similar files.

### 2026-06-26: Prototype Baseline Established

- Added formal README, MVP scope, change control, and manual test checklist.
- Recorded current completed features, unfinished areas, and known prototype limits.
- Set next recommended sprint focus to P0.3 reconnect and same-seat reseating.
