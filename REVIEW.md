# Review Findings

## 1. Vessel fallback mixes stale orbit data with the new vessel
- **Evidence:** In `kOS.MechJeb2.Addon/Wrapeers/MechJebManeuverPlannerWrapper.cs:199-247` the new fallback only replaces the `vessel` argument passed to `PlaceManeuverNode`. The `orbit`, `vesselState` (UT) and `target` that feed `MakeNodes` still come from `_maneuverPlannerModule`, i.e. from the destroyed vessel whose `Vessel` reference just went “fake null”.
- **Impact:** As soon as the planner falls into this path (scene switch, vessel swap, etc.) we compute maneuvers using the previous craft’s orbit/UT but then apply the nodes to the active vessel. The resulting burns are nonsensical or outright invalid instead of forcing a reinitialization.
- **Fix:** When the module reports an invalid vessel, stop and throw a `KOSException` (so the caller forces a reinitialization) or rebuild `_maneuverPlannerModule` for the active vessel before touching `MakeNodes`. Don’t mix data from two different vessels.

## 2. Unconditional UnityEngine.Debug logging will spam player logs
- **Evidence:** `kOS.MechJeb2.Addon/Wrapeers/MechJebManeuverPlannerWrapper.cs:202-408` writes every diagnostic through `UnityEngine.Debug.Log/LogError` instead of the existing `Log.Debug/Log.Error` helper. A single planner call now emits ~10 lines regardless of log level.
- **Impact:** In release builds every maneuver request floods KSP.log with verbose traces, hurting performance and drowning out actionable messages. This also bypasses the project’s log-level filtering.
- **Fix:** Replace these calls with the existing `Log.Debug`/`Log.Error` helpers (which respect build configuration) or remove them once the investigation is done.
