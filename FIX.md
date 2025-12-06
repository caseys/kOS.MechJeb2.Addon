# Fix: Stale MechJeb References After Save Reload

## Problem

After reloading a save in KSP (without restarting KSP entirely), MechJeb operations failed with "MechJeb is not ready yet" errors, even though MechJeb worked fine in the UI.

## Root Cause

Unity destroys objects on scene transitions (like save reloads), but C# references remain non-null. These "fake null" objects throw exceptions or return "null" from `ToString()` when accessed. The wrapper was caching `MasterMechJeb` and `ManeuverPlannerModule` references that became stale after reload.

## Solution

### BaseWrapper.cs - Smart MasterMechJeb Property

The `MasterMechJeb` property now:
1. First tries the cached getter from `CoreInstance`
2. Validates the result isn't a destroyed Unity object (checks `ToString() != "null"`)
3. Falls back to `GetFreshMasterMechJeb()` which fetches from `FlightGlobals.ActiveVessel`

### MechJebManeuverPlannerWrapper.cs - Fresh Module Per Operation

Instead of caching `_maneuverPlannerModule`, `GetManeuverPlannerModule()` fetches it fresh from `MasterMechJeb` on each operation. This ensures we always have a valid reference.

## Files Changed

1. `kOS.MechJeb2.Addon/Wrapeers/BaseWrapper.cs`
2. `kOS.MechJeb2.Addon/Wrapeers/MechJebManeuverPlannerWrapper.cs`

## Testing

Both scenarios now work:
- Fresh KSP start → operations work
- Save reload (without KSP restart) → operations work
