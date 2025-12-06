# kOS.MechJeb2.Addon Development Notes

## Critical Learnings for Implementing Maneuver Operations

### 1. kOS Suffix Getter Behavior (CRITICAL!)

**Problem**: When you call a kOS suffix like `PRINT PLANNER:CIRCULARIZE("APOAPSIS")`, kOS may evaluate the suffix getter **multiple times** (once to get the value, possibly again for printing/type conversion).

**Impact**: If your C# implementation has checks that cause it to return different values on subsequent calls (like checking if vessel is null), the second call may fail even though the first succeeded.

**Example from CIRCULARIZE bug**:
```
First call:  CIRCULARIZE() → vessel valid → creates node → returns True → node count = 1
Second call: CIRCULARIZE() → vessel became null → returns False ← THIS IS WHAT kOS SEES
```

**Solution**: Keep suffix implementations simple and idempotent. Avoid state checks that can fail on retry:

```csharp
// ❌ BAD - vessel check can fail on second call
var vesselObj = vessel as Vessel;
if (vesselObj == null)
{
    return false;  // Second kOS evaluation sees this!
}

// ✅ GOOD - simple, idempotent
foreach (var node in nodes)
{
    _placeManeuverNodeMethod.Invoke(null, new[] { vessel, orbit, dV, nodeUT });
}
return true;
```

### 2. No Delays Needed in TypeScript (ksp-mcp)

**Finding**: JavaScript `setTimeout()` delays between creating nodes and checking them are NOT necessary.

**Why**: The C# code places nodes synchronously using MechJeb's `PlaceManeuverNode`, and kOS can see them immediately after the suffix returns.

**Pattern**: Use the simple pattern from CHANGEINCLINATION:
```typescript
// Create node
const result = await conn.execute(
  `SET PLANNER TO ADDONS:MJ:CORE:MANEUVERPLANNER. ` +
  `PRINT PLANNER:OPERATION("PARAMS").`
);

// Immediately check node - no delay needed!
const nodeInfo = await conn.execute(
  'IF HASNODE { SET ND TO NEXTNODE. PRINT ND:DELTAV:MAG. }'
);
```

**Don't do this** (unnecessary complexity):
```typescript
// ❌ Unnecessary
await new Promise(r => setTimeout(r, 1000));
// or
`WAIT 1.`  // Not needed in the kOS command
```

### 3. Vessel Loading Timing Issues

**Problem**: Tests can fail with "Cannot find MechJebCore running module" if commands are executed before the vessel fully loads.

**Symptoms**:
- kOS connection gets reset/garbled
- CPU selection menu appears repeatedly
- Commands don't execute
- Test shows "SUCCESS" but no actual results

**Root cause**: `wait-for-kos-vessel.sh` checks if kOS is initialized, but **NOT** if MechJeb is initialized. Operations will fail if MechJeb hasn't started yet.

**Example (CHANGEAP test)**:
- Test started immediately after save loaded
- kOS was ready, but MechJeb wasn't initialized yet
- Commands failed with connection resets
- Manual retry after vessel settled worked perfectly

**Current mitigation**:
- Use `wait-for-kos-vessel.sh` helper to check for vessel initialization
- Add fallback waits (60s) if helper times out
- Tests should verify MechJeb is initialized before executing operations

**Proper fix needed**: Create `wait-for-mechjeb.sh` that checks if MechJeb is initialized:
```bash
# Verify MechJeb is ready
timeout 60 bash -c 'until echo "PRINT ADDONS:MJ:AVAILABLE." | nc 127.0.0.1 5410 | grep -q "True"; do sleep 2; done'
```

**Workaround**: Add longer sleep (30-60s) after `wait-for-kos-vessel.sh` to allow MechJeb to initialize.

### 4. Test Script Improvements

**Key pattern for reliable tests**:
```bash
# 1. Check if KSP running with pgrep (fast, reliable)
if pgrep -q KSP; then
    # 2. Reload with timeout to prevent hanging
    timeout 30 "$SCRIPT_DIR/LoadSaveKSP.scpt" test2 || {
        echo "Reload failed"
    }

    # 3. Verify KSP still running after reload
    if ! pgrep -q KSP; then
        KSP_RUNNING="false"  # Start fresh
    fi
fi

# 4. Clear error messages about what happened
```

**Why this matters**: Prevents confusion when KSP crashes during reload.

## Implementing New Maneuver Operations - Checklist

When adding a new maneuver operation:

1. **Keep C# implementation simple**
   - Don't add vessel null checks or state validation that can fail on retry
   - Let `ExecuteOperation` handle all the work
   - Operations should be idempotent

2. **Follow the working pattern**
   - Model after CHANGEINCLINATION or CHANGEPE (both working)
   - Don't add unnecessary delays
   - Trust that nodes are visible immediately after creation

3. **Test with E2E script**
   - Create test script following test-changeinclination.sh pattern
   - Use timeout-protected reloads
   - Verify vessel loading before executing commands

4. **Validate properly**
   - Check that commands actually executed (not just "success" status)
   - Verify nodes are visible in kOS (HASNODE check)
   - Confirm target orbit parameters are correct

## Common Pitfalls to Avoid

1. ❌ Adding vessel validation that fails on kOS retry
2. ❌ Using delays to "fix" visibility issues (fix the root cause instead)
3. ❌ Trusting test "SUCCESS" without verifying actual results
4. ❌ Running commands before vessel/MechJeb fully initialized
5. ❌ AppleScript calls without timeout (can hang indefinitely)

## Working Operations (Reference)

These operations have been tested and work correctly:
- CIRCULARIZE (after removing vessel check)
- CHANGEPE (with simple pattern)
- CHANGEINCLINATION (gold standard - simple, clean)
- HOHMANN (after adding Rendezvous=true and checking for empty nodes)

Study these implementations when adding new operations.
