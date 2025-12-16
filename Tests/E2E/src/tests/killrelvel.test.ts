/**
 * E2E test for KILLRELVEL maneuver operation
 *
 * Tests that MechJeb can create a node to match velocity with target.
 * Most useful for rendezvous operations.
 */

import { ensureKspReady, getManeuverProgram, clearNodes, SAVES, TIMEOUTS } from '../helpers/test-setup.js';
import type { ManeuverResult, SetTargetResult } from 'ksp-mcp/mechjeb';

describe('KILLRELVEL', () => {
  beforeAll(async () => {
    await ensureKspReady(SAVES.ORBIT);
  }, TIMEOUTS.KSP_STARTUP);

  describe('at closest approach to Mun', () => {
    let targetResult: SetTargetResult;
    let killResult: ManeuverResult;

    beforeAll(async () => {
      await clearNodes();
      const maneuver = await getManeuverProgram();
      targetResult = await maneuver.setTarget('Mun');
      killResult = await maneuver.killRelVel('CLOSEST_APPROACH');
    }, TIMEOUTS.BURN_EXECUTION);

    it('sets target', () => {
      expect(targetResult.success).toBe(true);
    });

    it('creates node', () => {
      // deltaV will be large since we're matching a moon's orbital velocity
      expect(killResult.success).toBe(true);
      expect(killResult.deltaV).toBeDefined();
      expect(killResult.deltaV).toBeGreaterThan(0);
    });
  });

  describe('with X_FROM_NOW timing', () => {
    let targetResult: SetTargetResult;
    let killResult: ManeuverResult;

    beforeAll(async () => {
      await clearNodes();
      const maneuver = await getManeuverProgram();
      targetResult = await maneuver.setTarget('Mun');
      killResult = await maneuver.killRelVel('X_FROM_NOW');
    }, TIMEOUTS.BURN_EXECUTION);

    it('sets target', () => {
      expect(targetResult.success).toBe(true);
    });

    it('creates node', () => {
      expect(killResult.success).toBe(true);
      expect(killResult.deltaV).toBeDefined();
    });
  });
});
