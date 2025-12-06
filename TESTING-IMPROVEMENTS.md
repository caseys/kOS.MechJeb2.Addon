3# Testing & Monitoring Improvements Plan

## Problems Identified in Current E2E Tests

### 1. **Blind Test Execution** (test-ascent.sh:81)
```bash
npm run ascent > /tmp/ascent-test-output.log 2>&1
```
**Problem**: Launches ascent script and waits blindly for completion. No monitoring during execution means:
- Error loops go undetected until timeout
- No visibility into what's happening
- Can't abort if things go wrong
- No incremental progress updates

### 2. **Fallback to Sleep** (test-ascent.sh:35, 53)
```bash
if ! "$SCRIPT_DIR/wait-for-kos-vessel.sh" 60; then
    echo "  ⚠️  Vessel initialization timeout, falling back to extended wait..."
    sleep 60  # Fallback: 2x original timeout
fi
```
**Problem**: When active monitoring fails, falls back to blind sleep. This is a sign the monitoring isn't reliable.

### 3. **No Early Error Detection**
The test only checks for success/failure AFTER completion (lines 88-104). If `npm run ascent` gets stuck in an error loop, we won't know until it times out or runs forever.

### 4. **No Real-time kOS Terminal Access**
We can't see what kOS is doing right now. We have to wait for the test to finish and check logs.

---

## Solution 1: Add kOS Monitoring to ksp-mcp

### New MCP Resources to Add

Add these to `ksp-mcp/src/mcp-server.ts`:

#### Resource: `kos://status`
Returns current kOS connection status and last error (if any)

```typescript
{
  connected: boolean,
  cpuId: number,
  vessel: string | null,
  lastCommand: string | null,
  lastError: string | null,
  errorCount: number  // Errors in last minute
}
```

#### Resource: `kos://terminal/recent`
Returns last N lines of kOS terminal output (like recent command history)

```typescript
{
  lines: string[],  // Last 50 lines
  hasErrors: boolean,
  errorPattern: string | null  // Repeating error if detected
}
```

### New MCP Tools to Add

#### Tool: `kos_execute_monitored`
Execute a kOS command and return result with error detection

```typescript
{
  command: string,
  timeout?: number,
  detectLoops?: boolean  // Detect if same error repeats
}
```

Returns:
```typescript
{
  output: string,
  success: boolean,
  isLooping: boolean,  // True if error pattern detected
  errorPattern?: string
}
```

---

## Solution 2: Create Testing Skill

Create `.claude/skills/kos-test-with-monitoring.md`:

```markdown
# kOS Test with Monitoring Skill

When running kOS E2E tests, always use this pattern:

## Setup Monitoring
1. Check kOS status using `kos://status` resource
2. If error loop detected, abort and report
3. Set up terminal monitoring

## Run Test
1. Launch test in background
2. Monitor progress using `kos://terminal/recent` every 5-10 seconds
3. Check for:
   - Repeating errors (error loop detection)
   - Progress indicators (altitude changes, phase changes)
   - Stuck state (no output for 30+ seconds)

## Early Abort Conditions
- Same error appears 3+ times in 15 seconds
- No terminal output for 60 seconds
- kOS disconnects

## Report Progress
- Update user every 30 seconds with current phase
- Show last kOS terminal line
- Estimated time remaining

## On Completion
- Verify success conditions
- Save full logs
- Report summary
```

---

## Solution 3: Improve E2E Test Scripts

### Pattern for Better test-ascent.sh

```bash
# OLD (line 81):
npm run ascent > /tmp/ascent-test-output.log 2>&1

# NEW:
# Launch in background with monitoring
npm run ascent > /tmp/ascent-test-output.log 2>&1 &
ASCENT_PID=$!

# Monitor progress
LAST_OUTPUT=""
NO_CHANGE_COUNT=0
for i in {1..30}; do  # 10 minutes max
    sleep 15

    # Check if process still running
    if ! kill -0 $ASCENT_PID 2>/dev/null; then
        break  # Process finished
    fi

    # Get recent output
    CURRENT_OUTPUT=$(tail -20 /tmp/ascent-test-output.log)

    # Check for error loops
    if echo "$CURRENT_OUTPUT" | grep -q "GET Suffix.*not found"; then
        ERROR_COUNT=$(echo "$CURRENT_OUTPUT" | grep -c "GET Suffix.*not found")
        if [ "$ERROR_COUNT" -gt 3 ]; then
            echo "✗ Error loop detected! Aborting..."
            kill $ASCENT_PID 2>/dev/null
            cat /tmp/ascent-test-output.log
            exit 1
        fi
    fi

    # Check for progress (output changed)
    if [ "$CURRENT_OUTPUT" != "$LAST_OUTPUT" ]; then
        NO_CHANGE_COUNT=0
        # Show progress every 10 iterations (50 seconds)
        if [ $((i % 10)) -eq 0 ]; then
            echo "  Progress: $(tail -1 /tmp/ascent-test-output.log)"
        fi
    else
        NO_CHANGE_COUNT=$((NO_CHANGE_COUNT + 1))
        # No output change for 60 seconds (12 * 5s) = stuck?
        if [ "$NO_CHANGE_COUNT" -gt 12 ]; then
            echo "✗ Test appears stuck (no output for 60s). Last line:"
            tail -5 /tmp/ascent-test-output.log
            kill $ASCENT_PID 2>/dev/null
            exit 1
        fi
    fi

    LAST_OUTPUT="$CURRENT_OUTPUT"
done

# Wait for process to fully exit
wait $ASCENT_PID 2>/dev/null
EXIT_CODE=$?
```


## Files to Modify

1. **ksp-mcp/src/mcp-server.ts** - Add MCP resources and tools
2. **Tests/E2E/test-ascent.sh** - Add monitoring loop
3. **.claude/skills/kos-test-with-monitoring.md** - New skill
4. **Tests/E2E/test-*.sh** - Update all tests with monitoring

---

## Current Status Summary

- **Problem**: E2E tests run blindly, can't detect error loops
- **Root Cause**: No real-time monitoring during test execution
- **Impact**: Tests hang forever when kOS gets stuck in error loops
- **Solution**: Add monitoring to MCP server + improve E2E scripts + create monitoring skill
