# Ref-After-Save Failure – Fix Plan

## What we know so far
- After any scene/vessel reload the GameEvent handlers in `MechJebController` set `_instance = null` and `NeedsReinitialization = true` (`MechJebController.cs:67-83`). This guarantees that the next `ADDONS:MJ:CORE` lookup builds a *new* `MechJebCoreWrapper`, but any scripts that cached the previous `CORE` or any of its child wrappers now keep references to objects that will never be touched again by the controller.
- `Addon.Available()` sees the flag and calls `TryInitializeMechJebCore(true)` (`Addon.cs:31-51`). That delivers a fresh `MechJebCore` PartModule instance and invokes `MechJebController.Instance.Initialize(..., true)` (`Addon.cs:79-136`). Base wrappers *can* rebind because `BaseWrapper.Initialize` ignores the `Initialized` guard when `force=true` (`Wrapeers/BaseWrapper.cs:21-29`).
- `MechJebCoreWrapper.Initialize` currently handles the `force` case by deleting all cached child wrapper objects (`Wrapeers/MechJebCoreWrapper.cs:26-37`). This means that the new core wrapper will hand out fresh child wrappers the *next time* someone requests them, but any kOS script that already stored `core:ManeuverPlanner` or `core:Ascent` keeps using the old object. Because `BindObject()` is never called on those existing wrapper instances again, fields such as `_maneuverPlannerModule` stay bound to destroyed Unity objects (`Wrapeers/MechJebManeuverPlannerWrapper.cs:64-195`), and subsequent calls into the wrapper fail even though the addon pretends it has been reinitialized.

## Plan of attack

1. **Keep the singleton instance alive and mark it stale instead of discarding it**
   - Replace the `_instance = null` assignments in the GameEvent callbacks (`MechJebController.cs:67-83`) with a helper, e.g. `MarkInstanceStale()`, that only sets `NeedsReinitialization = true` and records that the *current* `MechJebCoreWrapper` must be rebound.
   - Add a simple `int _generation` (or similar) inside `MechJebController` and store the generation number on each wrapper. When events fire, increment `_generation`. The next time `Addon.TryInitializeMechJebCore(true)` succeeds we will call `_instance?.Initialize(newCore, force:true)` so every existing reference (including ones cached by scripts) gets hydrated with the new `MechJebCore`. This guarantees we always mutate the same object graph instead of creating unreachable duplicates.

2. **Actively rebind every child wrapper when the core wrapper reinitializes**
   - Replace the `if (force) { _wrapper = null; ... }` block at the start of `MechJebCoreWrapper.Initialize` with logic that calls `.Initialize(MasterMechJeb, true)` on each already-created child wrapper (`Ascent`, `VesselState`, `Info`, `NodeExecutor`, `ManeuverPlanner`). This can be factored into a helper such as `RebindChild<T>` to avoid repetitive code.
   - If a child wrapper throws (for example because MechJeb is still booting and `MasterMechJeb` is temporarily `null`), log the error and set that field back to `null` so the next property access can lazily build a new wrapper. Scripts that still hold the original object will now have it automatically rebound because we were able to reach it and run `Initialize(..., true)` on it.

3. **Guard against stale module handles inside the high-risk wrappers**
   - In `MechJebManeuverPlannerWrapper` and `MechJebAscentWrapper`, add a lightweight `EnsureBound()` method that verifies `_maneuverPlannerModule`, `_getModuleVessel`, etc. are still pointing at live Unity objects before every operation. If a fake-null Unity object is detected, call `BindObject()` again (which will rebuild `_maneuverPlannerModule` using the current `MasterMechJeb`) instead of just throwing. This is effectively an automatic self-heal path for callers that hold onto these objects between scene transitions.
   - Emit a descriptive log/exception only if rebinding fails twice; that makes debugging easier and keeps the exception message actionable.

4. **Extend the test coverage so the regression cannot happen again**
   - Add a kOS regression script (e.g., `Tests/E2E/ManeuverPlannerReloadTest.ks`) that:
     1. Stores `SET planner TO ADDONS:MJ:CORE:MANEUVERPLANNER.`
     2. Forces reinitialization via `ADDONS:MJ:INIT(TRUE).`
     3. Invokes a read-only accessor on the *previously cached* `planner` (e.g., `planner:OPERATIONS:LENGTH`) and expects it to succeed.
   - Add a similar test for another child wrapper (e.g., `ASCENT:DESIREDALTITUDE`) to make sure the fix is generic, not just for Maneuver Planner.
   - These tests do not need to validate real maneuver creation; they only need to prove that accessing cached wrappers after `ADDONS:MJ:INIT(TRUE)` no longer explodes because of stale Unity references.

## Expected outcome
- Cached `CORE`, `MANEUVERPLANNER`, and `ASCENT` wrapper objects survive scene reloads because the addon now reuses the same instance graph, forces every wrapper through `Initialize(..., true)`, and self-heals module bindings when destroyed Unity objects are detected.
- `ADDONS:MJ:INIT(TRUE)` becomes a reliable workaround again, so the save-reload test flow described in the bug report will stop failing.
