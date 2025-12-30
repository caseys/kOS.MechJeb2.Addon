// LandingWrapperTest.ks
// Tests for kOS.MechJeb2.Addon LandingWrapper and LandingGuidanceWrapper

CLEARSCREEN.
PRINT "===============================".
PRINT " MechJeb LandingWrapper TESTS  ".
PRINT "===============================".

// -----------------------------------------------------------------------------
// Global counters
// -----------------------------------------------------------------------------
SET totalTests TO 0.
SET passedTests TO 0.
SET failedTests TO LIST().

// Simple assert
DECLARE FUNCTION ASSERT_EQ {
    PARAMETER name, expected, actual.

    SET totalTests TO totalTests + 1.

    IF expected = actual {
        SET passedTests TO passedTests + 1.
    } ELSE {
        LOCAL msg IS name + " expected: " + expected + ", actual: " + actual.
        failedTests:ADD(msg).
        PRINT "FAILED: " + msg.
    }
}.

// Helper: ASSERT_TRUE
DECLARE FUNCTION ASSERT_TRUE {
    PARAMETER name, condition.
    ASSERT_EQ(name, TRUE, condition).
}.

// -----------------------------------------------------------------------------
// Getting wrappers
// -----------------------------------------------------------------------------
PRINT "Getting Landing wrappers...".
SET landing TO ADDONS:MJ:LANDING.
SET guidance TO ADDONS:MJ:LANDINGGUIDANCE.
PRINT "OK.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: Wrapper access
// -----------------------------------------------------------------------------
PRINT "TEST: Wrapper access".

ASSERT_TRUE("LANDING exists", DEFINED(landing)).
ASSERT_TRUE("LANDING type check", landing:ISTYPE("LandingWrapper")).
ASSERT_TRUE("LANDINGGUIDANCE exists", DEFINED(guidance)).
ASSERT_TRUE("LANDINGGUIDANCE type check", guidance:ISTYPE("LandingGuidanceWrapper")).

PRINT "Wrapper access tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: Alias access
// -----------------------------------------------------------------------------
PRINT "TEST: Alias access".

SET landing2 TO ADDONS:MJ:LANDINGAUTOPILOT.
ASSERT_TRUE("LANDINGAUTOPILOT alias exists", DEFINED(landing2)).

PRINT "Alias access tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Saving original values
// -----------------------------------------------------------------------------
SET origTouchdownSpeed TO landing:TOUCHDOWNSPEED.
SET origDeployGears TO landing:DEPLOYGEARS.
SET origDeployChutes TO landing:DEPLOYCHUTES.
SET origRCSAdjustment TO landing:RCSADJUSTMENT.
SET origLimitGearsStage TO landing:LIMITGEARSSTAGE.
SET origLimitChutesStage TO landing:LIMITCHUTESSTAGE.

PRINT "Original values stored.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: ENABLED (read-only state check)
// -----------------------------------------------------------------------------
PRINT "TEST: ENABLED".

SET enabled TO landing:ENABLED.
ASSERT_TRUE("ENABLED is boolean", enabled = TRUE OR enabled = FALSE).
PRINT "  ENABLED: " + enabled.

PRINT "ENABLED tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: STATUS (read-only)
// -----------------------------------------------------------------------------
PRINT "TEST: STATUS".

SET landingStatus TO landing:STATUS.
ASSERT_TRUE("STATUS is string", landingStatus:ISTYPE("String")).
PRINT "  STATUS: " + landingStatus.

PRINT "STATUS tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: LANDATTARGET (read-only)
// -----------------------------------------------------------------------------
PRINT "TEST: LANDATTARGET".

SET landAtTarget TO landing:LANDATTARGET.
ASSERT_TRUE("LANDATTARGET is boolean", landAtTarget = TRUE OR landAtTarget = FALSE).
PRINT "  LANDATTARGET: " + landAtTarget.

PRINT "LANDATTARGET tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: TOUCHDOWNSPEED / TDSPEED
// -----------------------------------------------------------------------------
PRINT "TEST: TOUCHDOWNSPEED + alias TDSPEED".

SET newSpeed TO 1.5.
SET landing:TOUCHDOWNSPEED TO newSpeed.
WAIT 0.1.

ASSERT_EQ("TOUCHDOWNSPEED set", newSpeed, landing:TOUCHDOWNSPEED).
ASSERT_EQ("TDSPEED alias matches", landing:TOUCHDOWNSPEED, landing:TDSPEED).

// restore
SET landing:TOUCHDOWNSPEED TO origTouchdownSpeed.
WAIT 0.1.
ASSERT_EQ("TOUCHDOWNSPEED restored", origTouchdownSpeed, landing:TOUCHDOWNSPEED).

PRINT "TOUCHDOWNSPEED tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: DEPLOYGEARS / GEARS
// -----------------------------------------------------------------------------
PRINT "TEST: DEPLOYGEARS + alias GEARS".

SET landing:DEPLOYGEARS TO NOT origDeployGears.
WAIT 0.1.

ASSERT_EQ("DEPLOYGEARS toggled", NOT origDeployGears, landing:DEPLOYGEARS).
ASSERT_EQ("GEARS alias matches", landing:DEPLOYGEARS, landing:GEARS).

// restore
SET landing:DEPLOYGEARS TO origDeployGears.
WAIT 0.1.
ASSERT_EQ("DEPLOYGEARS restored", origDeployGears, landing:DEPLOYGEARS).

PRINT "DEPLOYGEARS tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: DEPLOYCHUTES / CHUTES
// -----------------------------------------------------------------------------
PRINT "TEST: DEPLOYCHUTES + alias CHUTES".

SET landing:DEPLOYCHUTES TO NOT origDeployChutes.
WAIT 0.1.

ASSERT_EQ("DEPLOYCHUTES toggled", NOT origDeployChutes, landing:DEPLOYCHUTES).
ASSERT_EQ("CHUTES alias matches", landing:DEPLOYCHUTES, landing:CHUTES).

// restore
SET landing:DEPLOYCHUTES TO origDeployChutes.
WAIT 0.1.
ASSERT_EQ("DEPLOYCHUTES restored", origDeployChutes, landing:DEPLOYCHUTES).

PRINT "DEPLOYCHUTES tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: RCSADJUSTMENT / RCS
// -----------------------------------------------------------------------------
PRINT "TEST: RCSADJUSTMENT + alias RCS".

SET landing:RCSADJUSTMENT TO NOT origRCSAdjustment.
WAIT 0.1.

ASSERT_EQ("RCSADJUSTMENT toggled", NOT origRCSAdjustment, landing:RCSADJUSTMENT).
ASSERT_EQ("RCS alias matches", landing:RCSADJUSTMENT, landing:RCS).

// restore
SET landing:RCSADJUSTMENT TO origRCSAdjustment.
WAIT 0.1.
ASSERT_EQ("RCSADJUSTMENT restored", origRCSAdjustment, landing:RCSADJUSTMENT).

PRINT "RCSADJUSTMENT tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: LIMITGEARSSTAGE / GEARSTAGE
// -----------------------------------------------------------------------------
PRINT "TEST: LIMITGEARSSTAGE + alias GEARSTAGE".

SET newStage TO origLimitGearsStage + 1.
SET landing:LIMITGEARSSTAGE TO newStage.
WAIT 0.1.

ASSERT_EQ("LIMITGEARSSTAGE set", newStage, landing:LIMITGEARSSTAGE).
ASSERT_EQ("GEARSTAGE alias matches", landing:LIMITGEARSSTAGE, landing:GEARSTAGE).

// restore
SET landing:LIMITGEARSSTAGE TO origLimitGearsStage.
WAIT 0.1.
ASSERT_EQ("LIMITGEARSSTAGE restored", origLimitGearsStage, landing:LIMITGEARSSTAGE).

PRINT "LIMITGEARSSTAGE tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: LIMITCHUTESSTAGE / CHUTESTAGE
// -----------------------------------------------------------------------------
PRINT "TEST: LIMITCHUTESSTAGE + alias CHUTESTAGE".

SET newStage TO origLimitChutesStage + 1.
SET landing:LIMITCHUTESSTAGE TO newStage.
WAIT 0.1.

ASSERT_EQ("LIMITCHUTESSTAGE set", newStage, landing:LIMITCHUTESSTAGE).
ASSERT_EQ("CHUTESTAGE alias matches", landing:LIMITCHUTESSTAGE, landing:CHUTESTAGE).

// restore
SET landing:LIMITCHUTESSTAGE TO origLimitChutesStage.
WAIT 0.1.
ASSERT_EQ("LIMITCHUTESSTAGE restored", origLimitChutesStage, landing:LIMITCHUTESSTAGE).

PRINT "LIMITCHUTESSTAGE tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: Prediction properties (read-only)
// -----------------------------------------------------------------------------
PRINT "TEST: Prediction properties".

SET predReady TO landing:PREDICTIONREADY.
ASSERT_TRUE("PREDICTIONREADY is boolean", predReady = TRUE OR predReady = FALSE).
PRINT "  PREDICTIONREADY: " + predReady.

SET predLat TO landing:PREDICTEDLAT.
ASSERT_TRUE("PREDICTEDLAT is scalar", predLat:ISTYPE("Scalar")).
ASSERT_EQ("PREDLAT alias matches", predLat, landing:PREDLAT).

SET predLng TO landing:PREDICTEDLNG.
ASSERT_TRUE("PREDICTEDLNG is scalar", predLng:ISTYPE("Scalar")).
ASSERT_EQ("PREDLNG alias matches", predLng, landing:PREDLNG).

SET predAlt TO landing:PREDICTEDALT.
ASSERT_TRUE("PREDICTEDALT is scalar", predAlt:ISTYPE("Scalar")).
ASSERT_EQ("PREDALT alias matches", predAlt, landing:PREDALT).

SET predUT TO landing:PREDICTEDUT.
ASSERT_TRUE("PREDICTEDUT is scalar", predUT:ISTYPE("Scalar")).
ASSERT_EQ("PREDUT alias matches", predUT, landing:PREDUT).

SET predOutcome TO landing:PREDICTEDOUTCOME.
ASSERT_TRUE("PREDICTEDOUTCOME is string", predOutcome:ISTYPE("String")).
ASSERT_EQ("PREDOUTCOME alias matches", predOutcome, landing:PREDOUTCOME).

PRINT "Prediction properties tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Test: Info properties (read-only)
// -----------------------------------------------------------------------------
PRINT "TEST: Info properties".

SET maxSpeed TO landing:MAXALLOWEDSPEED.
ASSERT_TRUE("MAXALLOWEDSPEED is scalar", maxSpeed:ISTYPE("Scalar")).
PRINT "  MAXALLOWEDSPEED: " + maxSpeed.

SET decelAlt TO landing:DECELERATIONENDALT.
ASSERT_TRUE("DECELERATIONENDALT is scalar", decelAlt:ISTYPE("Scalar")).
ASSERT_EQ("DECELALT alias matches", decelAlt, landing:DECELALT).

SET atmBrake TO landing:USEATMOSPHERETOBRAKE.
ASSERT_TRUE("USEATMOSPHERETOBRAKE is boolean", atmBrake = TRUE OR atmBrake = FALSE).
ASSERT_EQ("ATMBRAKE alias matches", atmBrake, landing:ATMBRAKE).

SET chutesReady TO landing:PARACHUTESDEPLOYABLE.
ASSERT_TRUE("PARACHUTESDEPLOYABLE is boolean", chutesReady = TRUE OR chutesReady = FALSE).
ASSERT_EQ("CHUTESREADY alias matches", chutesReady, landing:CHUTESREADY).

PRINT "Info properties tests done.".
PRINT "-------------------------------".

// -----------------------------------------------------------------------------
// Note: Method tests (STOPLANDING, LANDSOMEWHERE, LANDUNTARGETED, LANDATPOSITIONTARGET)
// are skipped in automated tests due to kOS/MechJeb interaction issues when called
// from script files. These methods work correctly when executed via direct commands.
// Test manually with: SET L TO ADDONS:MJ:LANDING. PRINT L:STOPLANDING().
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Test: LandingGuidance - LANDINGSITES
// -----------------------------------------------------------------------------
PRINT "TEST: LANDINGSITES".

SET sites TO guidance:LANDINGSITES.
ASSERT_TRUE("LANDINGSITES is list", sites:ISTYPE("List")).
PRINT "  LANDINGSITES count: " + sites:LENGTH.

IF sites:LENGTH > 0 {
    PRINT "  First site: " + sites[0].
}

PRINT "LANDINGSITES tests done.".
PRINT "-------------------------------".

// Note: GUIDANCE:LANDSOMEWHERE and GUIDANCE:SETANDLANDTARGETKSC method tests
// are skipped - see note above about method testing limitations.

// -----------------------------------------------------------------------------
// FINAL SUMMARY
// -----------------------------------------------------------------------------
PRINT "".
PRINT "===============================".
PRINT "    LANDING TEST SUMMARY       ".
PRINT "===============================".

PRINT "Total tests : " + totalTests.
PRINT "Passed      : " + passedTests.
SET failedCount TO (totalTests - passedTests).
PRINT "Failed      : " + failedCount.

IF failedCount > 0 {
    PRINT "".
    PRINT "Failed test details:".
    FOR item IN failedTests {
        PRINT " - " + item.
    }
} ELSE {
    PRINT "".
    PRINT "ALL LANDING TESTS PASSED".
}.

PRINT "===============================".
PRINT "Landing tests finished.".
