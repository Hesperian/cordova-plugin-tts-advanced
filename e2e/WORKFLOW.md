# E2E Testing Workflow

Complete guide for running E2E tests on Android emulator and iOS simulator.

## Quick Reference

```bash
# Setup (first time only)
make e2e-setup

# Run tests (automatically launches devices)
make e2e-android-run    # Pixel 6 emulator + tests
make e2e-ios-run        # iPhone 16 Pro simulator + tests
```

## Complete Workflow

### 1. Setup Test App (First Time Only)

```bash
make e2e-setup
```

This does:
1. `npm install` - Install Cordova dependencies
2. `cordova plugin add ../../ --link` - Link plugin (not copy)
3. Prepares platforms with plugin code

### 2. Run Tests

**Android:**
```bash
make e2e-android-run
```
- Automatically launches Pixel 6 API UpsideDownCake emulator (if not running)
- Waits for emulator to boot
- Builds and deploys test app
- Opens app automatically

**iOS:**
```bash
make e2e-ios-run
```
- Automatically launches iPhone 16 Pro / iOS 18.5 simulator (if not booted)
- Opens Simulator.app
- Builds and deploys test app
- Opens app automatically

### 3. Using the Test App

Once app launches:

1. **Device Ready** - Shows "Device ready - click Run Tests"
2. **Run Tests** button - Runs 8 automated tests
3. **Test Speak** button - Speaks a sample phrase for manual verification

### 4. After Making Plugin Changes

```bash
# Update test app with latest plugin code
make e2e-prepare

# Run again (automatically launches device if needed)
make e2e-android-run
# or
make e2e-ios-run
```

The `--link` flag means most changes are automatically reflected, but `e2e-prepare` ensures platforms are synced.

## Manual Device Launch (Optional)

You can launch devices manually before running tests:

```bash
# Android
make emulator-android   # Pixel 6 API UpsideDownCake

# iOS
make simulator-ios      # iPhone 16 Pro / iOS 18.5
```

The test targets will detect the device is already running and skip the launch step.

## Test Coverage

The automated test suite includes:

1. ✅ TTS plugin is available (window.TTS defined)
2. ✅ Speak short text completes
3. ✅ Speak empty string completes
4. ✅ Stop when idle succeeds
5. ✅ Stop interrupts ongoing speech
6. ✅ Sequential speaks work
7. ✅ Cancel=true interrupts previous speech
8. ✅ checkLanguage returns available languages

**Critical:** Tests #2 and #3 would have caught the null utteranceId warmup bug!

## Device Configuration

Edit `Makefile` to change default devices:

```makefile
IOS_SIM_TARGET := "iPhone 16 Pro / 18.5"
IOS_SIM_UDID := 6CA8AE03-48CA-4603-B5E8-97849CB65680
ANDROID_AVD := Pixel_6_API_UpsideDownCake
```

Find available devices:
```bash
# Android
emulator -list-avds

# iOS
xcrun simctl list devices available | grep iPhone
```

## Troubleshooting

### Android: Emulator won't start
```bash
# Check available AVDs
emulator -list-avds

# Start manually
emulator @Pixel_6_API_UpsideDownCake

# Check if running
adb devices
```

### iOS: Simulator already open but app doesn't deploy
```bash
# Reset simulator
xcrun simctl shutdown all
make simulator-ios
make e2e-ios-run
```

### Plugin changes not reflected
```bash
# Force rebuild
make e2e-prepare
make e2e-android-run
```

### Can't find device
- Android: Ensure `adb devices` shows your device
- iOS: Ensure simulator is booted (`xcrun simctl list devices`)

## Build Only (No Run)

```bash
# Build Android APK only
make e2e-android
# Shows APK location for manual installation
```

## Manual Installation

```bash
# Android
adb install -r e2e/tts-test-cordova-android13-ios7/platforms/android/app/build/outputs/apk/debug/app-debug.apk

# iOS - use Xcode or xcrun simctl install
```

## Notes

- Emulator/simulator launch is **idempotent** - safe to run multiple times
- `emulator-android` runs in background, returns when device is ready
- `simulator-ios` opens Simulator.app UI
- Test app uses `--link` so plugin changes are mostly automatic
- Tests run in the app UI, not headless
