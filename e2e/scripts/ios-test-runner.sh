#!/bin/bash
# iOS E2E Test Runner
# Launches app with auto-run mode and captures test results from simulator logs

set -e

BUNDLE_ID="org.hesperian.tts.test"
APP_DIR="e2e/tts-test-cordova-android13-ios7"
SIM_UDID="6CA8AE03-48CA-4603-B5E8-97849CB65680"
TIMEOUT=120  # 2 minutes

echo "📱 iOS E2E Test Runner"
echo "================================"

# Check if xcrun is available
if ! command -v xcrun &> /dev/null; then
    echo "❌ Error: xcrun not found. Please install Xcode."
    exit 2
fi

# Check if simulator is available
if ! xcrun simctl list devices | grep -q "$SIM_UDID"; then
    echo "❌ Error: Simulator not found (UDID: $SIM_UDID)"
    exit 2
fi

# Check if simulator is booted
if ! xcrun simctl list devices | grep "$SIM_UDID" | grep -q "Booted"; then
    echo "📱 Booting simulator..."
    xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
    sleep 5
fi

echo "📱 Simulator ready"

# Build app
echo "🔨 Building app..."
cd "$APP_DIR"

# Build app
cordova build ios --buildFlag="-destination id=$SIM_UDID" --quiet
cd ../..

# Trap to cleanup on exit
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    # Restore config.xml
    if [ -f "$APP_DIR/config.xml.bak" ]; then
        mv "$APP_DIR/config.xml.bak" "$APP_DIR/config.xml"
    fi
    # Kill log stream if still running
    kill $LOG_PID 2>/dev/null || true
    rm -f "$LOG_FILE"
}
trap cleanup EXIT

# Start log capture
echo "📝 Starting log capture..."
LOG_FILE="/tmp/cordova-tts-test-$$.log"
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "TTSTest"' --style compact > "$LOG_FILE" 2>&1 &
LOG_PID=$!
sleep 2

# Install and launch app
echo "📦 Installing and launching app..."
xcrun simctl install booted "$APP_DIR/platforms/ios/build/Debug-iphonesimulator/TTSTest.app"
xcrun simctl launch booted "$BUNDLE_ID" > /dev/null 2>&1

# Wait a fixed time for tests to complete (tests should finish in ~10 seconds)
echo "⏳ Waiting for tests to complete (15 seconds)..."
for i in {1..15}; do
    printf "."
    sleep 1
done
echo ""

echo ""
echo "✅ Tests completed, parsing results..."
echo ""

# Parse simulator log for test results  
echo "📊 Test Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Note: iOS logs need to be captured via system log or Console.app
# For now, use a simple approach - check if we can find test output
if xcrun simctl spawn booted log show --predicate 'process == "TTSTest"' --last 30s 2>/dev/null | grep "TEST_RESULT::" > /tmp/ios-test-log-$$.txt; then
    LOG_FILE="/tmp/ios-test-log-$$.txt"
else
    # Fallback: just show we tried
    echo "⚠️  Could not capture iOS console output"
    echo "   iOS console.log capture requires additional setup"
    echo "   Run 'make e2e-ios-run' and check results visually for now"
    exit 2
fi

grep "TEST_RESULT::" "$LOG_FILE" | while read -r line; do
    TEST_INFO=$(echo "$line" | sed -n 's/.*TEST_RESULT::\(.*\)$/\1/p')
    TEST_NAME=$(echo "$TEST_INFO" | awk -F'::' '{print $1}')
    TEST_STATUS=$(echo "$TEST_INFO" | awk -F'::' '{print $2}')
    TEST_DURATION=$(echo "$TEST_INFO" | awk -F'::' '{print $3}')
    
    if [ "$TEST_STATUS" = "PASS" ]; then
        echo "  ✓ $TEST_NAME ($TEST_DURATION)"
    else
        echo "  ✗ $TEST_NAME ($TEST_DURATION)"
        ERROR_MSG=$(echo "$TEST_INFO" | awk -F'::' '{for(i=4;i<=NF;i++) printf "%s%s", $i, (i<NF?":":"")}')
        if [ -n "$ERROR_MSG" ]; then
            echo "      Error: $ERROR_MSG"
        fi
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for summary
SUMMARY=$(grep "TEST_SUMMARY::" "$LOG_FILE" | tail -1)
if [ -n "$SUMMARY" ]; then
    SUMMARY_INFO=$(echo "$SUMMARY" | sed -n 's/.*TEST_SUMMARY::\(.*\)$/\1/p')
    TESTS_COUNT=$(echo "$SUMMARY_INFO" | awk -F'::' '{print $1}')
    RESULT_STATUS=$(echo "$SUMMARY_INFO" | awk -F'::' '{print $2}')
    DURATION=$(echo "$SUMMARY_INFO" | awk -F'::' '{print $3}')
    
    echo ""
    echo "Summary: $TESTS_COUNT ($DURATION)"
    
    if [ "$RESULT_STATUS" = "SUCCESS" ]; then
        echo "✅ All tests passed!"
        rm -f "$LOG_FILE"
        exit 0
    else
        echo "❌ Some tests failed"
        rm -f "$LOG_FILE"
        exit 1
    fi
else
    echo ""
    echo "⚠️  No test summary found - tests may not have completed"
    rm -f "$LOG_FILE"
    exit 2
fi
