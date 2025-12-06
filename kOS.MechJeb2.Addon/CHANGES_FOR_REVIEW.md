# Changes for Review - kOS.MechJeb2.Addon

## Summary

Two major changes:
1. **Save Reload Fix** - MechJeb now properly reinitializes after loading a saved game
2. **ManeuverPlanner Refactoring** - Operations split into organized partial classes

---

## 1. Save Reload Fix

### Problem
After loading a saved game (e.g., switching from orbit to launchpad vessel), accessing MechJeb caused errors like:
- `Value cannot be null. Parameter name: instance`
- `GET Suffix 'ENABLED' not found on object AscentWrapper`

### Root Cause
The MechJeb wrapper held stale references to the previous vessel's MechJeb instance after a save reload. Unity's "fake null" (destroyed objects that aren't C# null) caused reflection errors.

### Solution

#### MechJebController.cs (NEW: GameEvents subscription)
- Added `NeedsReinitialization` flag
- Subscribe to KSP GameEvents: `onFlightReady`, `onVesselChange`, `onGameSceneLoadRequested`
- When events fire: clear cached `_instance` and set `NeedsReinitialization = true`

#### Addon.cs (MODIFIED: Reinitialization logic)
- `Available()` now checks `NeedsReinitialization` flag
- `TryInitializeMechJebCore()` now returns `bool` (success/failure)
- Only clear reinitialization flag on successful initialization
- Added vessel "fake null" check (Unity destroyed object detection)
- Removed unused `_isMechJebDev` field

#### MechJebCoreWrapper.cs (MODIFIED: Null checks on all wrapper properties)
All 5 wrapper properties (Ascent, VesselState, InfoItems, NodeExecutor, ManeuverPlanner) now:
- Check if `MasterMechJeb` is null before returning wrapper
- Throw helpful `KOSException` instead of returning broken wrapper
- Check `Initialized` flag before returning cached wrapper

#### MechJebAscentWrapper.cs (MODIFIED: Binding safety)
- Added `_bindingSucceeded` flag to track if reflection binding worked
- `BindObject()` returns early if `MasterMechJeb` is null
- `Enabled` getter/setter check `_bindingSucceeded` before accessing

---

## 2. ManeuverPlanner Refactoring

### Changes

#### MechJebManeuverPlannerWrapper.cs (MODIFIED: Core methods only)
- Moved operation methods to partial classes
- Added `ExecuteOperationWithTargetLongitude()` helper for LONGITUDE/LAN operations
- Added vessel fallback to `FlightGlobals.ActiveVessel` when `ComputerModule.Vessel` is stale
- Enhanced debug logging for node placement

#### NEW: ManeuverPlanner/Basic.cs
Contains: `CHANGEPE`, `CHANGEAP`, `CIRCULARIZE`

#### NEW: ManeuverPlanner/Orbital.cs
Contains: `CHANGEINCLINATION`

#### NEW: ManeuverPlanner/Transfer.cs
Contains: `HOHMANN`, `COURSECORRECTION`, `LONGITUDE`, `LAN`

#### NEW: ManeuverPlanner/Rendezvous.cs
Contains: `KILLRELVEL`, `RESONANTORBIT`

#### kOS.MechJeb2.Addon.csproj (MODIFIED)
- Added `<Compile>` entries for new partial class files

#### DELETED: MechJebManeuverPlannerWrapper.Orbital.cs
- Replaced by `ManeuverPlanner/Orbital.cs`

---

## Files Changed

| File | Change Type | Purpose |
|------|------------|---------|
| `Addon.cs` | Modified | Save reload fix, vessel validity check |
| `MechJebController.cs` | Modified | GameEvents subscription for save reload detection |
| `Wrapeers/MechJebCoreWrapper.cs` | Modified | Null checks on all wrapper properties |
| `Wrapeers/MechJebAscentWrapper.cs` | Modified | Binding safety for save reload |
| `Wrapeers/MechJebManeuverPlannerWrapper.cs` | Modified | Refactored, vessel fallback |
| `Wrapeers/ManeuverPlanner/Basic.cs` | New | CHANGEPE, CHANGEAP, CIRCULARIZE |
| `Wrapeers/ManeuverPlanner/Orbital.cs` | New | CHANGEINCLINATION |
| `Wrapeers/ManeuverPlanner/Transfer.cs` | New | HOHMANN, COURSECORRECTION, LONGITUDE, LAN |
| `Wrapeers/ManeuverPlanner/Rendezvous.cs` | New | KILLRELVEL, RESONANTORBIT |
| `kOS.MechJeb2.Addon.csproj` | Modified | Added partial class file references |
| `MechJebManeuverPlannerWrapper.Orbital.cs` | Deleted | Replaced by ManeuverPlanner/Orbital.cs |
