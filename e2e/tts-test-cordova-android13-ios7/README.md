# E2E Testing with Cordova Test App

## Overview

A minimal Cordova app for end-to-end testing of the TTS plugin with real TTS engines on Android and iOS devices/simulators.

**Location:** `e2e/tts-test-cordova-android13-ios7/`

This test app uses:
- Cordova Android 13 (requires Java 17)
- Cordova iOS 7
- Latest plugin code via `file:../..` reference

## Quick Start

**First Time Setup:**
```bash
# From plugin root
make e2e-setup      # Install dependencies and link plugin

# Then run
make e2e-android-run

# Or manually
cd e2e/tts-test-cordova-android13-ios7
npm install
cordova plugin add ../../ --link
cordova run android
```

## Features

- Automated test suite that runs in the app
- Tests real TTS engine initialization and callbacks
- Tests that would have caught the warmup bug (null utteranceId)
- Manual "Test Speak" button for quick verification
- Visual pass/fail feedback

## Setup

The test app is in `e2e/tts-test-cordova-android13-ios7/` and uses a relative `file:` reference to the plugin.

### Directory Structure
```
cordova-plugin-tts-advanced/
├── e2e/
│   └── tts-test-cordova-android13-ios7/   # Current test app
│       ├── www/
│       │   ├── index.html
│       │   └── js/tests.js                 # Test suite
│       └── package.json                     # References ../../
└── (future: additional test apps for other Cordova versions)
```

## Running on Android

```bash
# From plugin root (recommended)
make e2e-android-run

# Or manually
cd e2e/tts-test-cordova-android13-ios7
cordova run android

# Or build and install manually
cordova build android
adb install -r platforms/android/app/build/outputs/apk/debug/app-debug.apk
```

**Requirements:**
- Android device or emulator running
- `adb devices` shows your device
- Google TTS engine installed (usually pre-installed)

## Running on iOS

```bash
# From plugin root (recommended)
make e2e-ios-run

# Or manually
cd e2e/tts-test-cordova-android13-ios7
cordova run ios

# Or open in Xcode
cordova build ios
open platforms/ios/TTSTest.xcworkspace
```

**Requirements:**
- macOS with Xcode
- iOS Simulator

## Test Suite

When the app loads, it shows:
- **Run Tests** button - Runs automated test suite
- **Test Speak** button - Speaks a test phrase

### Automated Tests

1. ✅ TTS plugin is available
2. ✅ Speak short text completes
3. ✅ Speak empty string completes
4. ✅ Stop when idle succeeds
5. ✅ Stop interrupts speech
6. ✅ Sequential speaks work
7. ✅ Cancel=true interrupts previous speech
8. ✅ Check language returns languages

### What These Tests Catch

**The Warmup Bug** - Tests #2 and #3 verify that speak() calls complete successfully. With the null utteranceId bug, the TTS engine wouldn't initialize properly and these would fail or timeout.

**Callback Issues** - Tests #5, #6, #7 verify that callbacks fire correctly and promises resolve/reject appropriately.

**Real Engine Behavior** - Unlike unit tests with mocks, these run against actual Android TextToSpeech and iOS AVSpeechSynthesizer.

## Updating After Plugin Changes

When you make changes to the plugin:

```bash
# From plugin root
make e2e-prepare    # Updates test app with latest plugin code
make e2e-android-run   # Build and run

# Or manually
cd e2e/tts-test-cordova-android13-ios7
cordova prepare
cordova run android
```

The app uses `file:../..` reference so it automatically picks up changes.

## Troubleshooting

### Android: TTS not working
- Check `adb logcat | grep TTS` for errors
- Ensure Google TTS is installed (Settings → Accessibility → Text-to-speech)
- Try on a real device if emulator has issues

### iOS: TTS not working
- Check Xcode console for errors
- Ensure VoiceOver/TTS is enabled in simulator settings
- Try different simulator models

### Plugin not updating
```bash
# Force reinstall the plugin
cd e2e/tts-test-cordova-android13-ios7
rm -rf node_modules/cordova-plugin-tts-advanced
npm install
cordova prepare
```

## Adding New Tests

Edit `www/js/tests.js` and add to the `runTests()` function:

```javascript
await test('Your test name', async () => {
    // Your test code
    await TTS.speak({text: 'test', cancel: true});
    // Throw error if test fails
    if (somethingWrong) throw new Error('Test failed');
});
```

## CI Integration

This test app can be integrated into CI with:
- **Android**: GitHub Actions with `reactivecircus/android-emulator-runner`
- **iOS**: GitHub Actions macOS runner with simulator

The automated test suite can be run headlessly by checking console output for test results.

## Comparison to Unit Tests

| Aspect | Unit Tests | E2E Test App |
|--------|-----------|--------------|
| Speed | Fast (~2s) | Slow (~1-2 min) |
| TTS Engine | Mocked | Real |
| Coverage | Logic, callbacks | Integration |
| When to Run | Every commit | Before releases |
| Catches | Logic bugs | Integration bugs |

**Recommendation**: Run unit tests frequently, run e2e test app before merging to main or releasing.
