# Review Notes - Tests/E2E

## Findings

1. **`test-coursecorrection.sh` never uses its burn timeout**  
   `BURN_TIMEOUT` is defined at `Tests/E2E/test-coursecorrection.sh:15` to cap the 20–40 minute maneuver, but nothing ever enforces it before the long-running `npm run hohmann` call at `Tests/E2E/test-coursecorrection.sh:31`. If MechJeb hangs, this test will block forever (and `validate-all-tests.sh` will be stuck on this case). Please wrap the burn step in a timeout so the suite fails fast instead of wedging the entire pipeline.

2. **`ksp_init` quietly proceeds after a failed vessel init**  
   When `wait-for-kos-vessel.sh` times out, the helper simply sleeps for another minute and then returns success (`Tests/E2E/with-test-helpers.sh:64` and `Tests/E2E/with-test-helpers.sh:80`). The rest of the test now runs against an undefined vessel/kOS state, which is exactly when we need a hard failure. Consider looping until the helper succeeds (with a max retry count) or aborting immediately so the failure is reported where it happens instead of surfacing as random downstream behavior.

3. **Helper scripts bake in one machine’s paths and tools**  
   Several helpers assume the repo lives under `/Users/casey` with the game installed on `/Volumes/Flatty` and Homebrew’s `gtimeout` in `PATH` (see `Tests/E2E/with-test-helpers.sh:92`, `Tests/E2E/wait-for-kos-vessel.sh:12`, `Tests/E2E/write-autoload-config.sh:11`, and `Tests/E2E/wait-for-ksp-ready.sh:45`). Nobody else (including CI) can run these tests without mirroring your exact directory layout and installing GNU coreutils as `gtimeout`. Please route these through configuration (env vars or arguments) and fall back to `timeout` when `gtimeout` is absent so the suite is portable.

4. **`InfoWrapperTest` contains assertions that can never fail**  
   The maneuver/target/biome sections only assert `TRUE` constants (`Tests/InfoWrapperTest.ks:55`, `Tests/InfoWrapperTest.ks:123`, `Tests/InfoWrapperTest.ks:138`), so they succeed even if the wrapper returns nonsense. That means we would not catch regressions such as suffixes disappearing or returning the wrong type. Please assert something meaningful (e.g., verify the values are numbers, are `-1` only when no node is present, or that they change after creating a node) so the tests actually exercise the wrappers.

5. **`VesselWrapperTest` has the same “always true” assertions**  
   The orbit smoke test at `Tests/VesselWrapperTest.ks:117`, `Tests/VesselWrapperTest.ks:118`, and `Tests/VesselWrapperTest.ks:119` also just asserts `TRUE`, so it can never fail and consequently provides no coverage for the orbit suffixes. Similar to the info tests, make the assertions check the retrieved values (numeric type, not `NaN`, sane magnitudes, etc.) so that regressions are detectable.

6. **`TestRunner` cannot run the full suite unattended**  
   Option 5 is described as “Run ALL tests”, but each `RUN` is immediately followed by `WAIT_FOR_KEY()` (see `Tests/TestRunner.ks:92` and `Tests/TestRunner.ks:94` for the first pair, with the same pattern repeated for the other suites). That means automation stops four times waiting for manual key presses, so the runner never actually runs all suites end-to-end. Consider only pausing in interactive modes and letting the “run all” flow execute every script back-to-back before prompting.
