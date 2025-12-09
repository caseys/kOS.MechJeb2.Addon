# kOS Test Monitoring Skill

This skill provides real-time monitoring of kOS tests to detect error loops, stuck states, and track progress.

## When to Use

Use this monitoring pattern when:
- Running any kOS E2E test
- Executing long-running kOS operations
- Debugging kOS scripts
- Testing new MechJeb functionality

**Important:** E2E test scripts handle KSP startup automatically. If testing new DLL changes, kill KSP first (`pkill -9 KSP`), then run the test script - it will start KSP, load the save, wait for kOS, and execute the test autonomously.

## Available MCP Resources

### `kos://status`

Returns current kOS connection status and error summary:
```json
{
  "connected": boolean,
  "cpuId": number | null,
  "vessel": string | null,
  "lastError": string | null,
  "errorCount": number,
  "isLooping": boolean,
  "hasErrors": boolean
}
```

### `kos://terminal/recent`

Returns last 50 lines of kOS terminal output with error detection:
```json
{
  "recentLines": string[],
  "hasErrors": boolean,
  "isLooping": boolean,
  "errorPattern": string | null,
  "errorCount": number,
  "summary": string
}
```

## Monitoring Pattern for E2E Tests

### 1. Check kOS Status Before Starting

```
Use ReadMcpResourceTool:
  server: "ksp-mcp"
  uri: "kos://status"

Check for:
- Is kOS connected?
- Are there existing errors?
- Is there an error loop already running?

If error loop detected (isLooping: true) → ABORT, report to user
```

### 2. Launch Test in Background

```bash
# Run test in background, output to log file
npm run ascent > /tmp/test-output.log 2>&1 &
TEST_PID=$!
```

### 3. Monitor Loop (every 10-15 seconds)

```
while test is running:
  1. Check kos://terminal/recent resource
     - Look for isLooping: true
     - Check errorPattern
     - Check summary for status

  2. Check test log file for changes
     - tail -20 /tmp/test-output.log
     - Compare to previous

  3. Detect stuck state:
     - No new output for 60 seconds → STUCK
     - Same output repeating → LOOP
     - isLooping: true from resource → ABORT

  4. Report progress every 30-60 seconds:
     - Current phase from log
     - Last kOS terminal line from resource
     - Time elapsed
```

### 4. Abort Conditions

Immediately kill test and report if:
- `isLooping: true` (same error 5+ times)
- No output change for 90 seconds
- kOS disconnects unexpectedly
- Error pattern detected in terminal resource

### 5. Completion Check

After test finishes:
- Verify expected success messages
- Check final kOS status via resource
- Report summary with timing

## Example Usage

```
User: "Test the MechJeb ascent"

1. Check kos://status
   → connected: true, no errors, isLooping: false ✓

2. Launch test:
   npm run ascent > /tmp/ascent.log 2>&1 &

3. Monitor (every 10-15s):
   [10s] kos://terminal/recent → recentLines shows "Configuring MechJeb..."
   [25s] Log shows → "Autopilot engaged"
   [40s] kos://terminal/recent → "Ascending, alt 5000m"
   [55s] Log shows → "Phase: Gravity turn"
   ...

4. Complete:
   ✓ Orbit achieved at 100km
   Total time: 3m 45s
```

## Implementation Notes

- **NEVER** run tests blindly without monitoring
- **ALWAYS** check kos://status before starting
- **UPDATE** user every 30-60 seconds with progress
- **ABORT EARLY** if error loop detected (don't wait for timeout)
- **USE** MCP resources (`kos://status`, `kos://terminal/recent`) + log file together
- MCP resources update automatically as kOS commands execute
- Error loop detection is built into the monitoring system (5+ same errors in last 20 lines)

## Error Loop Detection

The monitoring system automatically tracks:
- Last 100 lines of terminal output
- Error counts and patterns
- Loop detection (same error 5+ times in last 20 lines)

When `isLooping` is true in the resource response, the test should be aborted immediately.

## Progress Reporting

Always show:
- Elapsed time since test start
- Current kOS terminal status (from `kos://terminal/recent`)
- Test log status (last line from log file)
- Any errors detected

Report format:
```
[Xs elapsed] Phase: <current phase>
  kOS: <last terminal line>
  Test: <last log line>
```
