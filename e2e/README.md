# E2E Test Apps

This directory contains Cordova test apps for end-to-end testing of the TTS plugin with real TTS engines on actual devices and simulators.

## Current Test Apps

### tts-test-cordova-android13-ios7
- **Cordova Android:** 13.0.0 (requires Java 17)
- **Cordova iOS:** 7.1.1
- **Purpose:** Primary test app for latest Cordova versions
- **Status:** ✅ Android working, ⚠️ iOS needs simulator target fix

## Running Tests

**First time setup:**
```bash
make e2e-setup    # From plugin root
```

**Run tests (automatically launches devices):**
```bash
# Android - launches emulator if not running, then runs tests
make e2e-android-run

# iOS - launches simulator if not running, then runs tests
make e2e-ios-run

# Update test app after plugin changes
make e2e-prepare
```

**Launch devices manually (optional):**
```bash
make emulator-android   # Pixel 6 API UpsideDownCake
make simulator-ios      # iPhone 16 Pro / iOS 18.5
```

## Adding New Test Apps

To test compatibility with different Cordova versions:

1. **Create new test app:**
   ```bash
   cd e2e
   cordova create tts-test-cordova-android12-ios6 org.hesperian.tts.test TTSTest
   cd tts-test-cordova-android12-ios6
   ```

2. **Add platforms:**
   ```bash
   cordova platform add android@12
   cordova platform add ios@6
   ```

3. **Add plugin with relative reference:**
   Edit `package.json`:
   ```json
   "devDependencies": {
     "cordova-android": "^12.0.0",
     "cordova-ios": "^6.3.0",
     "cordova-plugin-tts-advanced": "file:../.."
   }
   ```

4. **Copy test harness:**
   ```bash
   cp ../tts-test-cordova-android13-ios7/www/index.html www/
   cp ../tts-test-cordova-android13-ios7/www/js/tests.js www/js/
   ```

5. **Update Makefile:**
   Add targets for the new app in `../../Makefile`

## Test Coverage

Each test app includes:
- ✅ 8 automated tests via UI
- ✅ Manual "Test Speak" button
- ✅ Visual pass/fail feedback
- ✅ Tests that catch warmup/initialization bugs
- ✅ Tests for callbacks and promise resolution

## Why Multiple Test Apps?

Different Cordova versions have different:
- Gradle versions and Android build tools
- Xcode project structures
- Plugin integration mechanisms
- JavaScript bridge implementations

Testing across versions ensures the plugin works reliably for all users regardless of their Cordova setup.

## Recommended Test Matrix

| Test App | Cordova Android | Cordova iOS | Java | Use Case |
|----------|----------------|-------------|------|----------|
| android13-ios7 | 13.x | 7.x | 17 | Latest (current) |
| android12-ios6 | 12.x | 6.x | 11/17 | Stable previous version |
| android11-ios6 | 11.x | 6.x | 11 | Legacy apps |

## Notes

- All test apps use `file:../..` reference to the plugin, so changes are immediately reflected
- Run `make e2e-prepare` after plugin changes to update all test apps
- Test apps are in `.gitignore` for `platforms/`, `plugins/`, and `node_modules/`
