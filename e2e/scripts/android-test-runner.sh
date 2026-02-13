#!/bin/bash
# Android E2E Test Runner
# Launches app with auto-run mode and captures test results from logcat

set -e

PACKAGE="org.hesperian.tts.test"
ACTIVITY="MainActivity"
APP_DIR="e2e/tts-test-cordova-android13-ios7"
TIMEOUT=120  # 2 minutes

echo "🤖 Android E2E Test Runner"
echo "================================"

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "❌ Error: adb not found. Please install Android SDK."
    exit 2
fi

# Check if device/emulator is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ Error: No Android device/emulator detected."
    echo "   Run 'make emulator-android' first."
    exit 2
fi

echo "📱 Device connected"

# Build and install app (if needed)
echo "🔨 Building app..."
cd "$APP_DIR"

# Build and install
cordova build android --quiet
cd ../..

echo "📦 Installing app..."
adb install -r "$APP_DIR/platforms/android/app/build/outputs/apk/debug/app-debug.apk" > /dev/null 2>&1 || {
    echo "   App already installed, continuing..."
}

# Clear logcat buffer
echo "🧹 Clearing logcat..."
adb logcat -c

# Start logcat capture in background
echo "📝 Starting logcat capture..."
LOGCAT_FILE="/tmp/cordova-tts-test-$$.log"
adb logcat -v brief "*:S" "chromium:I" 2>&1 | tee "$LOGCAT_FILE" &
LOGCAT_PID=$!

# Trap to cleanup on exit
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    kill $LOGCAT_PID 2>/dev/null || true
    rm -f "$LOGCAT_FILE.old" 2>/dev/null
    # Keep logcat file for debugging
    echo "   Logcat saved to: $LOGCAT_FILE"
}
trap cleanup EXIT

# Launch app
echo "🚀 Launching app with auto-run mode..."
adb shell am start -n "$PACKAGE/.$ACTIVITY" > /dev/null 2>&1

# Wait a fixed time for tests to complete (tests should finish in ~10 seconds)
echo "⏳ Waiting for tests to complete (20 seconds)..."
for i in {1..20}; do
    printf "."
    sleep 1
done
echo ""

echo ""
echo "✅ Tests completed, parsing results..."
echo ""

# Parse logcat for test results
echo "📊 Test Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

grep "TEST_RESULT::" "$LOGCAT_FILE" | while read -r line; do
    # Extract: TEST_RESULT::name::STATUS::duration
    TEST_INFO=$(echo "$line" | sed -n 's/.*TEST_RESULT::\(.*\)$/\1/p')
    # Split on :: delimiter
    TEST_NAME=$(echo "$TEST_INFO" | awk -F'::' '{print $1}')
    TEST_STATUS=$(echo "$TEST_INFO" | awk -F'::' '{print $2}')
    TEST_DURATION=$(echo "$TEST_INFO" | awk -F'::' '{print $3}')
    
    if [ "$TEST_STATUS" = "PASS" ]; then
        echo "  ✓ $TEST_NAME ($TEST_DURATION)"
    else
        echo "  ✗ $TEST_NAME ($TEST_DURATION)"
        # Show error message if present
        ERROR_MSG=$(echo "$TEST_INFO" | awk -F'::' '{for(i=4;i<=NF;i++) printf "%s%s", $i, (i<NF?":":"")}')
        if [ -n "$ERROR_MSG" ]; then
            echo "      Error: $ERROR_MSG"
        fi
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for summary
SUMMARY=$(grep "TEST_SUMMARY::" "$LOGCAT_FILE" | tail -1)
if [ -n "$SUMMARY" ]; then
    SUMMARY_INFO=$(echo "$SUMMARY" | sed -n 's/.*TEST_SUMMARY::\(.*\)$/\1/p')
    TESTS_COUNT=$(echo "$SUMMARY_INFO" | awk -F'::' '{print $1}')
    RESULT_STATUS=$(echo "$SUMMARY_INFO" | awk -F'::' '{print $2}')
    DURATION=$(echo "$SUMMARY_INFO" | awk -F'::' '{print $3}')
    
    echo ""
    echo "Summary: $TESTS_COUNT ($DURATION)"
    
    if [ "$RESULT_STATUS" = "SUCCESS" ]; then
        echo "✅ All tests passed!"
        exit 0
    else
        echo "❌ Some tests failed"
        exit 1
    fi
else
    echo ""
    echo "⚠️  No test summary found - tests may not have completed"
    exit 2
fi
