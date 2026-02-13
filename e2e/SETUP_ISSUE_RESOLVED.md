# E2E Test App Setup Issue - RESOLVED

## Problem

When running the test app, got error: "TTS plugin is available - window.TTS is not defined"

## Root Cause

The plugin was referenced in `package.json` devDependencies with `"file:../.."`, but **Cordova doesn't automatically install plugins from devDependencies**. The plugin must be explicitly added with `cordova plugin add`.

## Additional Issue

Because the test app is nested inside the plugin directory (`e2e/tts-test-cordova-android13-ios7/`), Cordova's copy mechanism fails with:
```
Cannot copy 'node_modules/cordova-plugin-tts-advanced' to a subdirectory of itself
```

## Solution

Use `cordova plugin add ../../ --link` instead of relying on package.json reference:

1. The `--link` flag creates a symlink instead of copying
2. This allows the nested directory structure to work
3. Changes to plugin source are immediately reflected (no need to reinstall)

## Makefile Integration

Added `make e2e-setup` target:
```makefile
e2e-setup:
	@echo "Setting up E2E test app..."
	cd $(E2E_APP) && npm install
	cd $(E2E_APP) && rm -f plugins/cordova-plugin-tts-advanced
	cd $(E2E_APP) && cordova plugin add ../../ --link
	@echo "✅ E2E test app ready"
```

## Usage

**First time:**
```bash
make e2e-setup
```

**Then run:**
```bash
make e2e-android-run   # Builds and runs on device/emulator
```

## Verification

After setup, verify plugin is installed:
```bash
cd e2e/tts-test-cordova-android13-ios7
cordova plugin list
# Should show: cordova-plugin-tts-advanced 0.4.1 "TTS"
```

Check it's registered in cordova_plugins.js:
```bash
grep -A5 "cordova-plugin-tts-advanced" platforms/android/platform_www/cordova_plugins.js
```

Should see:
```javascript
{
  "id": "cordova-plugin-tts-advanced.tts",
  "file": "plugins/cordova-plugin-tts-advanced/www/tts.js",
  "pluginId": "cordova-plugin-tts-advanced",
  "clobbers": ["TTS"]
}
```

## Status

✅ **RESOLVED** - Plugin now loads correctly, `window.TTS` is defined, tests can run.
