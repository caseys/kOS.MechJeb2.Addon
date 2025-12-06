# kOS Testing Improvements - Implementation Plan

## Phase 1: Add kOS Monitoring to ksp-mcp (MCP Server)

### Files to Create/Modify

#### 1. `ksp-mcp/src/monitoring/kos-monitor.ts` (NEW)
Terminal output monitoring with error loop detection

```typescript
export class KosMonitor {
  private recentLines: string[] = [];
  private errorCounts: Map<string, number> = new Map();

  trackLine(line: string): void {
    this.recentLines.push(line);
    if (this.recentLines.length > 100) {
      this.recentLines.shift();
    }

    // Track errors
    if (line.includes('Error:') || line.includes('Exception')) {
      const key = this.normalizeError(line);
      this.errorCounts.set(key, (this.errorCounts.get(key) || 0) + 1);
    }
  }

  detectLoop(): { isLooping: boolean; pattern?: string } {
    // Check if same error appears 5+ times in last 20 lines
    const recent = this.recentLines.slice(-20);
    // ... implementation
  }

  getStatus(): MonitorStatus {
    return {
      recentLines: this.recentLines.slice(-50),
      hasErrors: this.errorCounts.size > 0,
      isLooping: this.detectLoop().isLooping,
      errorPattern: this.detectLoop().pattern
    };
  }
}
```

#### 2. `ksp-mcp/src/mcp-server.ts` (MODIFY)
Add MCP resources for monitoring

```typescript
// Add to resources section
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: "kos://status",
        name: "kOS Connection Status",
        description: "Current kOS connection state and error status",
        mimeType: "application/json"
      },
      {
        uri: "kos://terminal/recent",
        name: "Recent kOS Terminal Output",
        description: "Last 50 lines of kOS terminal with error detection",
        mimeType: "application/json"
      }
    ]
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri.toString();

  if (uri === "kos://status") {
    return {
      contents: [{
        uri,
        mimeType: "application/json",
        text: JSON.stringify({
          connected: kosConnection?.isConnected() || false,
          lastError: kosMonitor.getLastError(),
          errorCount: kosMonitor.getErrorCount()
        })
      }]
    };
  }

  if (uri === "kos://terminal/recent") {
    const status = kosMonitor.getStatus();
    return {
      contents: [{
        uri,
        mimeType: "application/json",
        text: JSON.stringify(status)
      }]
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});
```

#### 3. `ksp-mcp/src/tools/kos-execute.ts` (MODIFY)
Hook up monitoring to execute commands

```typescript
export async function kosExecute(command: string): Promise<KosResult> {
  const result = await connection.execute(command);

  // Track output in monitor
  kosMonitor.trackLine(result.output);

  // Check for loops
  const loopCheck = kosMonitor.detectLoop();

  return {
    output: result.output,
    success: !result.output.includes('Error'),
    isLooping: loopCheck.isLooping,
    errorPattern: loopCheck.pattern
  };
}
```

---

## Phase 2: Create kOS Testing Skill

### File: `.claude/skills/kos-monitoring.md`

```markdown
# kOS Test Monitoring Skill

This skill provides real-time monitoring of kOS tests to detect error loops, stuck states, and track progress.

## When to Use
- Running any kOS E2E test
- Executing long-running kOS operations
- Debugging kOS scripts
- Testing new MechJeb functionality

## Pattern

### 1. Check kOS Status Before Starting
\`\`\`
Use ReadMcpResourceTool with uri="kos://status"
Check for:
- Is kOS connected?
- Are there existing errors?
- Is there an error loop already running?

If error loop detected → ABORT, report to user
\`\`\`

### 2. Launch Test in Background
\`\`\`bash
# Run test in background, output to log file
npm run ascent > /tmp/test-output.log 2>&1 &
TEST_PID=$!
\`\`\`

### 3. Monitor Loop (every 5-10 seconds)
\`\`\`
while test is running:
  1. Check kos://terminal/recent resource
     - Look for isLooping: true
     - Check errorPattern

  2. Check test log file for changes
     - tail -20 /tmp/test-output.log
     - Compare to previous

  3. Detect stuck state:
     - No new output for 60 seconds → STUCK
     - Same output repeating → LOOP

  4. Report progress every 30-60 seconds:
     - Current phase from log
     - Last kOS terminal line
     - Time elapsed
\`\`\`

### 4. Abort Conditions
Immediately kill test and report if:
- isLooping: true (same error 5+ times)
- No output change for 90 seconds
- kOS disconnects unexpectedly
- Error pattern detected in terminal

### 5. Completion Check
After test finishes:
- Verify expected success messages
- Check final kOS status
- Report summary with timing

## Example Usage

\`\`\`
User: "Test the MechJeb ascent"

1. Check kos://status
   → connected: true, no errors ✓

2. Launch test:
   npm run ascent > /tmp/ascent.log 2>&1 &

3. Monitor (every 10s):
   [10s] kos://terminal → "Configuring MechJeb..."
   [20s] Log changed → "Autopilot engaged"
   [30s] kos://terminal → "Ascending, alt 5000m"
   [40s] Log changed → "Phase: Gravity turn"
   ...

4. Complete:
   ✓ Orbit achieved at 100km
   Total time: 3m 45s
\`\`\`

## Implementation Notes

- **NEVER** run tests blindly without monitoring
- **ALWAYS** check kos://status before starting
- **UPDATE** user every 30-60 seconds with progress
- **ABORT EARLY** if error loop detected (don't wait for timeout)
- **USE** log file + kOS terminal resource together
```

---

## Phase 3: Update E2E Test Script with Monitoring

### File: `Tests/E2E/test-ascent.sh`

Replace line 81 (blind execution) with monitored execution:

```bash
echo "Step 2: Testing MechJeb ascent guidance with monitoring..."
echo "  Target: ${TARGET_ALTITUDE}m (100km), 0° inclination"
echo ""

# Launch test in background
npm run ascent > /tmp/ascent-test-output.log 2>&1 &
ASCENT_PID=$!

# Monitor execution
LAST_SIZE=0
NO_CHANGE_COUNT=0
START_TIME=$(date +%s)

echo "  Monitoring ascent progress..."
for i in {1..180}; do  # 15 minutes max (180 * 5s)
    sleep 5

    # Check if process still running
    if ! kill -0 $ASCENT_PID 2>/dev/null; then
        echo "  Test process completed"
        break
    fi

    # Get current log state
    CURRENT_SIZE=$(wc -l < /tmp/ascent-test-output.log 2>/dev/null || echo "0")

    # Check for error loops
    ERROR_COUNT=$(tail -20 /tmp/ascent-test-output.log 2>/dev/null | grep -c "GET Suffix.*not found" || echo "0")
    if [ "$ERROR_COUNT" -gt 5 ]; then
        echo "  ✗ Error loop detected! Aborting test..."
        kill $ASCENT_PID 2>/dev/null
        tail -30 /tmp/ascent-test-output.log
        exit 1
    fi

    # Check for progress (log file growing)
    if [ "$CURRENT_SIZE" -gt "$LAST_SIZE" ]; then
        NO_CHANGE_COUNT=0
        LAST_SIZE=$CURRENT_SIZE

        # Show progress every 30 seconds (6 iterations)
        if [ $((i % 6)) -eq 0 ]; then
            ELAPSED=$(($(date +%s) - START_TIME))
            LAST_LINE=$(tail -1 /tmp/ascent-test-output.log 2>/dev/null || echo "")
            echo "  [${ELAPSED}s] $LAST_LINE"
        fi
    else
        NO_CHANGE_COUNT=$((NO_CHANGE_COUNT + 1))

        # Stuck for 90 seconds (18 * 5s)?
        if [ "$NO_CHANGE_COUNT" -gt 18 ]; then
            echo "  ✗ Test appears stuck (no output for 90s)"
            echo "  Last output:"
            tail -10 /tmp/ascent-test-output.log
            kill $ASCENT_PID 2>/dev/null
            exit 1
        fi
    fi
done

# Wait for process to fully exit
wait $ASCENT_PID 2>/dev/null
EXIT_CODE=$?

echo ""
echo "Step 3: Verifying results..."
# ... rest of verification unchanged
```

---

## Testing the Implementation

### Test 1: Error Loop Detection
```bash
# Manually trigger error loop
echo "Testing error loop detection..."
(while true; do echo "GET Suffix 'ENABLED' not found"; sleep 0.1; done) > /tmp/test.log &
PID=$!

# Should detect within 25 seconds (5 errors * 5s interval)
```

### Test 2: Stuck Detection
```bash
# Test that outputs then stops
echo "Initial output" > /tmp/test.log
sleep 100  # Should detect stuck after 90s
```

### Test 3: Normal Progress
```bash
# Test that continuously outputs
(for i in {1..100}; do echo "Progress $i"; sleep 2; done) > /tmp/test.log &
# Should show progress updates every 30s
```

---

## Implementation Order

1. ✅ Create TESTING-IMPROVEMENTS.md (done)
2. ✅ Create IMPLEMENTATION-PLAN.md (this file)
3. → Create ksp-mcp/src/monitoring/kos-monitor.ts
4. → Update ksp-mcp/src/mcp-server.ts with resources
5. → Create .claude/skills/kos-monitoring.md
6. → Update Tests/E2E/test-ascent.sh with monitoring
7. → Test with real ascent (after KSP restart)

---

## Success Criteria

- ✓ Can detect error loops within 25 seconds
- ✓ Can detect stuck tests within 90 seconds
- ✓ Provides progress updates every 30 seconds
- ✓ MCP resources provide real-time kOS status
- ✓ Skill document guides proper test monitoring
- ✓ E2E tests fail fast instead of hanging
