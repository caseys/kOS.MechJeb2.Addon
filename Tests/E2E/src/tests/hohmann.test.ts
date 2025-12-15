/**
 * E2E test for HOHMANN transfer maneuver operation
 *
 * Tests that MechJeb can create Hohmann transfer nodes to reach a target.
 */

import { ensureKspReady, getManeuverProgram, clearNodes, SAVES } from '../helpers/test-setup.js';

describe('HOHMANN', () => {
  beforeAll(async () => {
    await ensureKspReady(SAVES.ORBIT);
  });

  beforeEach(async () => {
    await clearNodes();
    const maneuver = await getManeuverProgram();
    await maneuver.clearTarget().catch(() => {});
  });

  it('creates Hohmann transfer nodes to Mun', async () => {
    const maneuver = await getManeuverProgram();
    console.log(`  Has target before set: ${await maneuver.hasTarget()}`);

    // Set target to Mun
    console.log('  Setting target to Mun...');
    const targetResult = await maneuver.setTarget('Mun', 'body');
    expect(targetResult.success).toBe(true);
    console.log(`  Target confirmed: ${targetResult.name} (${targetResult.type})`);

    // Create Hohmann transfer
    console.log('  Creating Hohmann transfer...');
    const result = await maneuver.hohmannTransfer('COMPUTED', true);

    expect(result.success).toBe(true);
    expect(result.deltaV).toBeDefined();
    expect(result.deltaV).toBeGreaterThan(0);

    console.log(`  Node created: ${result.deltaV?.toFixed(1)} m/s`);
    console.log(`  Time to node: ${result.timeToNode?.toFixed(0)}s`);
  });

  it('requires target to be set', async () => {
    const maneuver = await getManeuverProgram();
    console.log('  Clearing target via ManeuverProgram (triple-attempt workaround)...');
    const clearResult = await maneuver.clearTarget();
    console.log(`  Target cleared: ${clearResult.cleared} (success: ${clearResult.success})`);
    if (clearResult.warning) {
      console.log(`  Warning: ${clearResult.warning}`);
    }
    const hasTargetAfterClear = await maneuver.hasTarget();
    console.log(`  hasTarget after clear: ${hasTargetAfterClear}`);
    expect(hasTargetAfterClear).toBe(false);

    console.log('  No target set (expected)');
    const result = await maneuver.hohmannTransfer();
    expect(result.success).toBe(false);
    expect(result.error).toContain('No target');
  });
});
