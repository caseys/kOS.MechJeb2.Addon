// Landing Wrapper Test Script
// Tests the Landing Autopilot and Landing Guidance wrappers
// Note: Some tests require being in orbit or on approach for meaningful results

CLEARSCREEN.
PRINT "=== Landing Wrapper Test ===".
PRINT "Testing ADDONS:MJ:LANDING and ADDONS:MJ:LANDINGGUIDANCE".
PRINT "".

SET totalTests TO 0.
SET passedTests TO 0.
SET failedTests TO LIST().

// Helper function for assertions
FUNCTION ASSERT_TRUE {
    PARAMETER name.
    PARAMETER value.
    SET totalTests TO totalTests + 1.
    IF value {
        SET passedTests TO passedTests + 1.
        PRINT "  PASS: " + name.
        RETURN TRUE.
    } ELSE {
        failedTests:ADD(name).
        PRINT "  FAIL: " + name.
        RETURN FALSE.
    }.
}.

FUNCTION ASSERT_EQ {
    PARAMETER name.
    PARAMETER expected.
    PARAMETER actual.
    SET totalTests TO totalTests + 1.
    IF expected = actual {
        SET passedTests TO passedTests + 1.
        PRINT "  PASS: " + name + " = " + actual.
        RETURN TRUE.
    } ELSE {
        failedTests:ADD(name + " (expected: " + expected + ", got: " + actual + ")").
        PRINT "  FAIL: " + name + " (expected: " + expected + ", got: " + actual + ")".
        RETURN FALSE.
    }.
}.

FUNCTION ASSERT_TYPE {
    PARAMETER name.
    PARAMETER value.
    PARAMETER expectedType.
    SET totalTests TO totalTests + 1.
    IF value:TYPENAME = expectedType {
        SET passedTests TO passedTests + 1.
        PRINT "  PASS: " + name + " is " + expectedType.
        RETURN TRUE.
    } ELSE {
        failedTests:ADD(name + " (expected type: " + expectedType + ", got: " + value:TYPENAME + ")").
        PRINT "  FAIL: " + name + " (expected type: " + expectedType + ", got: " + value:TYPENAME + ")".
        RETURN FALSE.
    }.
}.

// Wait for MechJeb to be available
PRINT "Waiting for MechJeb...".
SET mjAvailable TO FALSE.
SET waitCount TO 0.
UNTIL mjAvailable OR waitCount > 30 {
    SET mjAvailable TO ADDONS:MJ:AVAILABLE.
    IF NOT mjAvailable {
        WAIT 1.
        SET waitCount TO waitCount + 1.
    }.
}.

IF NOT mjAvailable {
    PRINT "ERROR: MechJeb not available after 30 seconds".
    PRINT "Aborting test.".
} ELSE {
    PRINT "MechJeb is available!".
    PRINT "".

    // Get wrapper references
    SET landing TO ADDONS:MJ:LANDING.
    SET guidance TO ADDONS:MJ:LANDINGGUIDANCE.

    // Test 1: Landing Wrapper Existence
    PRINT "TEST: Landing Wrapper Access".
    ASSERT_TRUE("LANDING wrapper exists", landing:ISTYPE("Structure")).
    PRINT "".

    // Test 2: Guidance Wrapper Existence
    PRINT "TEST: Guidance Wrapper Access".
    ASSERT_TRUE("LANDINGGUIDANCE wrapper exists", guidance:ISTYPE("Structure")).
    PRINT "".

    // Test 3: Landing Configuration Suffixes
    PRINT "TEST: Landing Configuration Suffixes".

    // TOUCHDOWNSPEED
    SET tdSpeed TO landing:TOUCHDOWNSPEED.
    PRINT "  Current TOUCHDOWNSPEED: " + tdSpeed.
    ASSERT_TRUE("TOUCHDOWNSPEED is numeric", tdSpeed:ISTYPE("Scalar")).

    // Set and verify
    SET landing:TOUCHDOWNSPEED TO 1.0.
    WAIT 0.1.
    ASSERT_EQ("TOUCHDOWNSPEED after set", 1.0, landing:TOUCHDOWNSPEED).

    // Restore default
    SET landing:TOUCHDOWNSPEED TO 0.5.
    PRINT "".

    // Test 4: Boolean Configuration
    PRINT "TEST: Boolean Configuration".

    // DEPLOYGEARS
    SET gears TO landing:DEPLOYGEARS.
    PRINT "  DEPLOYGEARS: " + gears.
    ASSERT_TRUE("DEPLOYGEARS is boolean", gears:ISTYPE("Boolean")).

    // DEPLOYCHUTES
    SET chutes TO landing:DEPLOYCHUTES.
    PRINT "  DEPLOYCHUTES: " + chutes.
    ASSERT_TRUE("DEPLOYCHUTES is boolean", chutes:ISTYPE("Boolean")).

    // RCSADJUSTMENT
    SET rcs TO landing:RCSADJUSTMENT.
    PRINT "  RCSADJUSTMENT: " + rcs.
    ASSERT_TRUE("RCSADJUSTMENT is boolean", rcs:ISTYPE("Boolean")).
    PRINT "".

    // Test 5: Status Properties
    PRINT "TEST: Status Properties".

    SET enabled TO landing:ENABLED.
    PRINT "  ENABLED: " + enabled.
    ASSERT_TRUE("ENABLED is boolean", enabled:ISTYPE("Boolean")).

    SET landingStatus TO landing:STATUS.
    PRINT "  STATUS: " + landingStatus.
    ASSERT_TRUE("STATUS is string", landingStatus:ISTYPE("String")).

    SET landAtTarget TO landing:LANDATTARGET.
    PRINT "  LANDATTARGET: " + landAtTarget.
    ASSERT_TRUE("LANDATTARGET is boolean", landAtTarget:ISTYPE("Boolean")).
    PRINT "".

    // Test 6: Prediction Properties (may be empty if not in descent)
    PRINT "TEST: Prediction Properties".

    SET predReady TO landing:PREDICTIONREADY.
    PRINT "  PREDICTIONREADY: " + predReady.
    ASSERT_TRUE("PREDICTIONREADY is boolean", predReady:ISTYPE("Boolean")).

    SET predLat TO landing:PREDICTEDLAT.
    PRINT "  PREDICTEDLAT: " + predLat.
    ASSERT_TRUE("PREDICTEDLAT is numeric", predLat:ISTYPE("Scalar")).

    SET predLng TO landing:PREDICTEDLNG.
    PRINT "  PREDICTEDLNG: " + predLng.
    ASSERT_TRUE("PREDICTEDLNG is numeric", predLng:ISTYPE("Scalar")).

    SET predAlt TO landing:PREDICTEDALT.
    PRINT "  PREDICTEDALT: " + predAlt.
    ASSERT_TRUE("PREDICTEDALT is numeric", predAlt:ISTYPE("Scalar")).

    SET predOutcome TO landing:PREDICTEDOUTCOME.
    PRINT "  PREDICTEDOUTCOME: " + predOutcome.
    ASSERT_TRUE("PREDICTEDOUTCOME is string", predOutcome:ISTYPE("String")).
    PRINT "".

    // Test 7: Info Properties (require specific conditions)
    PRINT "TEST: Info Properties".

    SET maxSpeed TO landing:MAXALLOWEDSPEED.
    PRINT "  MAXALLOWEDSPEED: " + maxSpeed.
    ASSERT_TRUE("MAXALLOWEDSPEED is numeric", maxSpeed:ISTYPE("Scalar")).

    SET decelAlt TO landing:DECELERATIONENDALT.
    PRINT "  DECELERATIONENDALT: " + decelAlt.
    ASSERT_TRUE("DECELERATIONENDALT is numeric", decelAlt:ISTYPE("Scalar")).

    SET atmBrake TO landing:USEATMOSPHERETOBRAKE.
    PRINT "  USEATMOSPHERETOBRAKE: " + atmBrake.
    ASSERT_TRUE("USEATMOSPHERETOBRAKE is boolean", atmBrake:ISTYPE("Boolean")).

    SET chutesReady TO landing:PARACHUTESDEPLOYABLE.
    PRINT "  PARACHUTESDEPLOYABLE: " + chutesReady.
    ASSERT_TRUE("PARACHUTESDEPLOYABLE is boolean", chutesReady:ISTYPE("Boolean")).
    PRINT "".

    // Test 8: Landing Sites (Guidance)
    PRINT "TEST: Landing Sites (Guidance)".

    SET sites TO guidance:LANDINGSITES.
    PRINT "  LANDINGSITES count: " + sites:LENGTH.
    ASSERT_TRUE("LANDINGSITES is a list", sites:ISTYPE("List")).

    IF sites:LENGTH > 0 {
        PRINT "  First few sites:".
        SET maxShow TO MIN(3, sites:LENGTH).
        FROM { LOCAL i IS 0. } UNTIL i >= maxShow STEP { SET i TO i + 1. } DO {
            PRINT "    - " + sites[i].
        }.
    } ELSE {
        PRINT "  (No landing sites loaded yet - may need flight scene)".
    }.
    PRINT "".

    // Test 9: Method Calls (non-destructive tests only)
    PRINT "TEST: Method Availability".

    // STOPLANDING should be callable (does nothing if not landing)
    SET stopResult TO landing:STOPLANDING().
    PRINT "  STOPLANDING() returned: " + stopResult.
    ASSERT_TRUE("STOPLANDING returns boolean", stopResult:ISTYPE("Boolean")).
    PRINT "".

    // Test 10: Alias Access
    PRINT "TEST: Suffix Aliases".

    // Test aliases
    SET tdSpeed2 TO landing:TDSPEED.
    ASSERT_EQ("TDSPEED alias", landing:TOUCHDOWNSPEED, tdSpeed2).

    SET predLat2 TO landing:PREDLAT.
    ASSERT_EQ("PREDLAT alias", landing:PREDICTEDLAT, predLat2).

    SET gears2 TO landing:GEARS.
    ASSERT_EQ("GEARS alias", landing:DEPLOYGEARS, gears2).
    PRINT "".

    // Test 11: Alias access
    PRINT "TEST: Access via aliases".
    SET landingAlias TO ADDONS:MJ:LANDINGAUTOPILOT.
    ASSERT_TRUE("LANDINGAUTOPILOT alias accessible", landingAlias:ISTYPE("Structure")).
    PRINT "".

    // =========================================
    // BEHAVIOR TESTS - Test actual functionality
    // =========================================
    PRINT "".
    PRINT "=== BEHAVIOR TESTS ===".
    PRINT "(These tests exercise actual autopilot behavior)".
    PRINT "".

    // Test 12: STOPLANDING behavior - ensure we start from clean state
    PRINT "TEST: STOPLANDING clears ENABLED".
    SET stopResult TO landing:STOPLANDING().
    WAIT 0.2.
    SET enabledAfterStop TO landing:ENABLED.
    ASSERT_TRUE("STOPLANDING returns true", stopResult).
    ASSERT_EQ("ENABLED after STOPLANDING", FALSE, enabledAfterStop).
    PRINT "".

    // Test 13: LANDATPOSITIONTARGET behavior
    // Note: This test requires a valid position target to be set
    PRINT "TEST: LANDATPOSITIONTARGET behavior".

    // Set a position target on the current body (use current position as base)
    SET currentBody TO SHIP:BODY.
    SET testLat TO SHIP:GEOPOSITION:LAT + 0.1.  // Slightly offset from current position
    SET testLng TO SHIP:GEOPOSITION:LNG + 0.1.
    SET testTarget TO LATLNG(testLat, testLng).
    PRINT "  Setting target on " + currentBody:NAME + " at " + ROUND(testLat,2) + ", " + ROUND(testLng,2).
    SET TARGET TO testTarget.
    WAIT 0.3.

    // Get initial state
    SET beforeEnabled TO landing:ENABLED.
    PRINT "  ENABLED before: " + beforeEnabled.

    // Call LANDATPOSITIONTARGET
    SET landResult TO landing:LANDATPOSITIONTARGET().
    WAIT 0.3.

    SET afterEnabled TO landing:ENABLED.
    SET afterLandAtTarget TO landing:LANDATTARGET.
    PRINT "  LANDATPOSITIONTARGET returned: " + landResult.
    PRINT "  ENABLED after: " + afterEnabled.
    PRINT "  LANDATTARGET: " + afterLandAtTarget.

    ASSERT_TRUE("LANDATPOSITIONTARGET returns true", landResult).
    ASSERT_TRUE("ENABLED is true after LANDATPOSITIONTARGET", afterEnabled).
    ASSERT_TRUE("LANDATTARGET is true", afterLandAtTarget).

    // Clean up - stop landing
    landing:STOPLANDING().
    WAIT 0.2.
    PRINT "".

    // Test 14: LANDSOMEWHERE (untargeted landing) behavior
    PRINT "TEST: LANDSOMEWHERE behavior".

    // Start from clean state
    landing:STOPLANDING().
    WAIT 0.2.

    SET beforeEnabled2 TO landing:ENABLED.
    PRINT "  ENABLED before: " + beforeEnabled2.

    // Call LANDSOMEWHERE
    SET landSomewhereResult TO landing:LANDSOMEWHERE().
    WAIT 0.3.

    SET afterEnabled2 TO landing:ENABLED.
    SET afterLandAtTarget2 TO landing:LANDATTARGET.
    PRINT "  LANDSOMEWHERE returned: " + landSomewhereResult.
    PRINT "  ENABLED after: " + afterEnabled2.
    PRINT "  LANDATTARGET: " + afterLandAtTarget2.

    ASSERT_TRUE("LANDSOMEWHERE returns true", landSomewhereResult).
    ASSERT_TRUE("ENABLED is true after LANDSOMEWHERE", afterEnabled2).
    // LANDATTARGET should be false for untargeted landing
    ASSERT_EQ("LANDATTARGET is false for untargeted", FALSE, afterLandAtTarget2).

    // Clean up
    landing:STOPLANDING().
    WAIT 0.2.
    PRINT "".

    // Test 15: GUIDANCE:SETANDLANDTARGETKSC behavior
    // Note: This test only works when orbiting Kerbin
    PRINT "TEST: GUIDANCE:SETANDLANDTARGETKSC behavior".

    IF SHIP:BODY:NAME = "Kerbin" {
        // Start from clean state
        landing:STOPLANDING().
        WAIT 0.2.

        SET beforeEnabled3 TO landing:ENABLED.
        PRINT "  ENABLED before: " + beforeEnabled3.

        // Call SETANDLANDTARGETKSC via guidance
        SET kscResult TO guidance:SETANDLANDTARGETKSC().
        WAIT 0.3.

        SET afterEnabled3 TO landing:ENABLED.
        PRINT "  SETANDLANDTARGETKSC returned: " + kscResult.
        PRINT "  ENABLED after: " + afterEnabled3.

        ASSERT_TRUE("SETANDLANDTARGETKSC returns true", kscResult).
        ASSERT_TRUE("ENABLED is true after SETANDLANDTARGETKSC", afterEnabled3).

        // Verify target moved near KSC coordinates (within ~1 degree tolerance)
        IF HASTARGET {
            SET tgtLat TO TARGET:GEOPOSITION:LAT.
            SET tgtLng TO TARGET:GEOPOSITION:LNG.
            PRINT "  Target lat/lng: " + ROUND(tgtLat,4) + ", " + ROUND(tgtLng,4).
            SET latOk TO ABS(tgtLat - (-0.0972)) < 1.
            SET lngOk TO ABS(tgtLng - (-74.5577)) < 1.
            ASSERT_TRUE("Target is near KSC", latOk AND lngOk).
        } ELSE {
            ASSERT_TRUE("Target set after SETANDLANDTARGETKSC", FALSE).
        }.

        // Clean up
        landing:STOPLANDING().
        WAIT 0.2.
    } ELSE {
        PRINT "  SKIPPED: Not at Kerbin (currently at " + SHIP:BODY:NAME + ")".
        PRINT "  SETANDLANDTARGETKSC only works at Kerbin".
    }.
    PRINT "".

    // Test 16: GUIDANCE:LANDSOMEWHERE behavior
    PRINT "TEST: GUIDANCE:LANDSOMEWHERE behavior".

    // Start from clean state
    landing:STOPLANDING().
    WAIT 0.2.

    SET beforeEnabled4 TO landing:ENABLED.
    PRINT "  ENABLED before: " + beforeEnabled4.

    // Call LANDSOMEWHERE via guidance
    SET guidanceLandResult TO guidance:LANDSOMEWHERE().
    WAIT 0.3.

    SET afterEnabled4 TO landing:ENABLED.
    PRINT "  GUIDANCE:LANDSOMEWHERE returned: " + guidanceLandResult.
    PRINT "  ENABLED after: " + afterEnabled4.

    ASSERT_TRUE("GUIDANCE:LANDSOMEWHERE returns true", guidanceLandResult).
    ASSERT_TRUE("ENABLED is true after GUIDANCE:LANDSOMEWHERE", afterEnabled4).

    // Final cleanup - ensure autopilot is stopped
    landing:STOPLANDING().
    WAIT 0.2.
    PRINT "  Final cleanup: STOPLANDING called".
    PRINT "".

    // Test 17: ENABLED toggle test
    PRINT "TEST: ENABLED engages/disengages correctly".

    // Setup: Set a position target first (required for MechJeb landing to work properly)
    // Use current body coordinates
    SET testLat2 TO SHIP:GEOPOSITION:LAT + 0.05.
    SET testLng2 TO SHIP:GEOPOSITION:LNG + 0.05.
    SET testTarget2 TO LATLNG(testLat2, testLng2).
    SET TARGET TO testTarget2.
    WAIT 0.3.

    SET landing:ENABLED TO TRUE.
    WAIT 0.3.  // Give MechJeb time to engage
    SET enabledAfterTrue TO landing:ENABLED.
    SET landing:ENABLED TO FALSE.
    WAIT 0.3.
    SET enabledAfterFalse TO landing:ENABLED.
    ASSERT_TRUE("ENABLED becomes true when set", enabledAfterTrue).
    ASSERT_EQ("ENABLED becomes false when cleared", FALSE, enabledAfterFalse).

    // Ensure cleanup
    landing:STOPLANDING().
    WAIT 0.1.
    PRINT "".

    // Summary
    PRINT "".
    PRINT "=================================".
    PRINT "TEST SUMMARY".
    PRINT "=================================".
    PRINT "Total Tests: " + totalTests.
    PRINT "Passed: " + passedTests.
    PRINT "Failed: " + (totalTests - passedTests).

    IF failedTests:LENGTH > 0 {
        PRINT "".
        PRINT "Failed tests:".
        FOR ft IN failedTests {
            PRINT "  - " + ft.
        }.
    } ELSE {
        PRINT "".
        PRINT "All tests passed!".
    }.
}.

PRINT "".
PRINT "Test complete.".
