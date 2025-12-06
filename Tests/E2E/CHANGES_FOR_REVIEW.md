# Changes for Review - Tests Directory

## Summary

New test files added for comprehensive testing of kOS.MechJeb2.Addon functionality.

---

## 1. E2E Test Scripts

### NEW: E2E/test-coursecorrection.sh
Full integration test for COURSECORRECTION maneuver operation:
- Starts KSP with test2 save (orbiting vessel)
- Creates Hohmann transfer to Mun
- Executes transfer burn via MechJeb
- Tests COURSECORRECTION to fine-tune approach to 50km periapsis
- Uses shared helpers (`with-test-helpers.sh`, `validate-node-creation.sh`)

---

## 2. kOS Test Scripts

### NEW: AscentWrapperTest.ks
Comprehensive test suite for MechJeb ascent guidance wrapper:
- Tests ascent parameter getters/setters
- Tests autopilot enable/disable
- Tests ascent status monitoring
- 800+ lines of test coverage

### NEW: CoreWrapperTest.ks
Tests for MechJebCoreWrapper:
- Basic availability checks
- Core wrapper property access
- Initialization behavior

### NEW: InfoWrapperTest.ks
Tests for info/telemetry wrapper:
- Vessel state information
- Orbital parameters
- Various info suffixes

### NEW: VesselWrapperTest.ks
Tests for vessel state wrapper:
- Vessel-specific data access
- State monitoring capabilities

### NEW: TestRunner.ks
Test orchestration script:
- Runs all kOS test scripts
- Reports pass/fail status
- Provides summary output

---

## Files Changed

| File | Change Type | Purpose |
|------|-------------|---------|
| `E2E/test-coursecorrection.sh` | New | E2E test for course correction after Hohmann transfer |
| `AscentWrapperTest.ks` | New | Ascent guidance wrapper tests |
| `CoreWrapperTest.ks` | New | Core wrapper tests |
| `InfoWrapperTest.ks` | New | Info wrapper tests |
| `VesselWrapperTest.ks` | New | Vessel state wrapper tests |
| `TestRunner.ks` | New | Test orchestration script |

---

## Testing

All test scripts are new additions. The E2E test follows the established pattern using shared helpers.

---

## No Unexplained Changes

All files are new additions for test coverage.
