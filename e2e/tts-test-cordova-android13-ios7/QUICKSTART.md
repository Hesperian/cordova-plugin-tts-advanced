# E2E Test App - Quick Start

## Location

`e2e/tts-test-cordova-android13-ios7/`

## First Time Setup

```bash
# From plugin root
make e2e-setup          # Install dependencies and link plugin
```

This installs dependencies and links the plugin with `--link` flag so changes are immediately reflected.

## Running Tests

The test targets automatically launch emulator/simulator if needed:

```bash
# Android - auto-launches Pixel 6 emulator
make e2e-android-run

# iOS - auto-launches iPhone 16 Pro simulator  
make e2e-ios-run
```

### Setup Requirements

**Android:**
- Java 17 (already configured)
- Android SDK
- Pixel 6 API UpsideDownCake emulator (auto-launched by test target)
- Google TTS installed on emulator (usually pre-installed)

**iOS:**
- Xcode with iOS 18.5 SDK
- iPhone 16 Pro simulator (auto-launched by test target)
- iOS speech synthesis (built-in)

### What to Do in the App

1. App loads and shows "Device ready"
2. Tap **"Run Tests"** - runs 8 automated tests
3. Tap **"Test Speak"** - speaks a sample phrase
4. Watch for green (pass) or red (fail) results

## After Plugin Changes

```bash
# From plugin root
make e2e-prepare         # Update with latest plugin code
make e2e-android-run     # Automatically launches emulator + runs tests
make e2e-ios-run         # Automatically launches simulator + runs tests
```

## Manual Device Launch (Optional)

You can launch devices manually before running tests:

```bash
make emulator-android   # Pixel 6 emulator
make simulator-ios      # iPhone 16 Pro simulator
```

The test targets will auto-launch devices if needed, so manual launch is optional.

## Test Coverage

The app tests:
1. ✅ TTS plugin availability
2. ✅ Speak short text (catches warmup bug!)
3. ✅ Speak empty string
4. ✅ Stop when idle
5. ✅ Stop interrupts speech
6. ✅ Sequential speaks
7. ✅ Cancel interrupts previous
8. ✅ Language check

## Success! 🎉

Both Android and iOS builds are working with automated emulator/simulator launch. The warmup bug fix can now be verified by running the test suite on real devices with actual TTS engines.
