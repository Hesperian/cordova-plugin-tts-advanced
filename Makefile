.PHONY: test test-all test-js test-ios test-android e2e-setup e2e-prepare e2e-android e2e-android-run e2e-ios-run e2e-android-test e2e-ios-test emulator-android simulator-ios clean

IOS_SIM_ID := $(shell xcrun simctl list devices available -j | python3 -c "import sys,json; devs=[d for r in json.loads(sys.stdin.read())['devices'].values() for d in r if 'iPhone' in d['name'] and d['isAvailable']]; print(devs[0]['udid'])" 2>/dev/null)
IOS_SIM_NAME := "iPhone 16 Pro / 18.5"
IOS_SIM_UDID := 6CA8AE03-48CA-4603-B5E8-97849CB65680
IOS_SIM_TARGET := iPhone-16-Pro
ANDROID_AVD := Pixel_6_API_UpsideDownCake
E2E_APP := e2e/tts-test-cordova-android13-ios7

test: test-js test-ios test-android

test-all: test e2e-android-test
	@echo ""
	@echo "======================================"
	@echo "✅ ALL TESTS PASSED!"
	@echo "======================================"
	@echo "Unit tests: JavaScript, iOS, Android"
	@echo "E2E tests: Android"
	@echo "======================================"
	@echo ""
	@echo "Note: iOS E2E tests (make e2e-ios-test) require manual verification"
	@echo "      Run 'make e2e-ios-run' and check test output in app UI"

test-js: node_modules
	npx vitest run

node_modules: package.json
	npm install
	@touch node_modules

test-ios:
	cd tests/ios && xcodegen generate
	xcodebuild test \
		-project tests/ios/CDVTTSTests.xcodeproj \
		-scheme CDVTTSTests \
		-destination 'platform=iOS Simulator,id=$(IOS_SIM_ID)' \
		-quiet

test-android:
	cd tests/android && ANDROID_HOME=$(or $(ANDROID_HOME),$(HOME)/Library/Android/sdk) \
		gradle test --quiet

# E2E test app targets
e2e-setup:
	@echo "Setting up E2E test app..."
	cd $(E2E_APP) && npm install
	cd $(E2E_APP) && rm -f plugins/cordova-plugin-tts-advanced
	cd $(E2E_APP) && cordova plugin add ../../ --link
	@echo "✅ E2E test app ready"

e2e-prepare:
	@echo "Preparing E2E test app with latest plugin code..."
	cd $(E2E_APP) && cordova prepare

e2e-android:
	@echo "Building Android E2E test app..."
	cd $(E2E_APP) && cordova build android
	@echo ""
	@echo "✅ Build successful!"
	@echo "APK: $(E2E_APP)/platforms/android/app/build/outputs/apk/debug/app-debug.apk"
	@echo ""
	@echo "To install: adb install -r $(E2E_APP)/platforms/android/app/build/outputs/apk/debug/app-debug.apk"

e2e-android-run: emulator-android
	@echo "Building and running Android E2E test app..."
	cd $(E2E_APP) && cordova run android

e2e-ios-run: simulator-ios
	@echo "Building and running iOS E2E test app..."
	@cd $(E2E_APP) && cordova build ios --buildFlag="-destination id=$(IOS_SIM_UDID)"
	@echo "Deploying to booted simulator..."
	@xcrun simctl install booted $(E2E_APP)/platforms/ios/build/Debug-iphonesimulator/TTSTest.app
	@xcrun simctl launch booted org.hesperian.tts.test
	@echo "✅ App launched on iPhone 16 Pro / 18.5"

# Automated E2E tests (with result capture)
e2e-android-test: emulator-android
	@echo "Running automated Android E2E tests..."
	@bash e2e/scripts/android-test-runner.sh

e2e-ios-test: simulator-ios
	@echo "Running automated iOS E2E tests..."
	@bash e2e/scripts/ios-test-runner.sh

# Launch Android emulator
emulator-android:
	@echo "Launching Android emulator: $(ANDROID_AVD)..."
	@if pgrep -f "$(ANDROID_AVD)" > /dev/null; then \
		echo "✅ Emulator $(ANDROID_AVD) is already running"; \
	else \
		echo "Starting emulator..."; \
		emulator @$(ANDROID_AVD) & \
		echo "⏳ Waiting for emulator to boot..."; \
		adb wait-for-device; \
		echo "✅ Emulator ready"; \
	fi

# Launch iOS simulator
simulator-ios:
	@echo "Launching iOS simulator: $(IOS_SIM_NAME)..."
	@if xcrun simctl list devices | grep "$(IOS_SIM_UDID)" | grep -q "Booted"; then \
		echo "✅ Simulator already running"; \
	else \
		echo "Booting simulator..."; \
		xcrun simctl boot $(IOS_SIM_UDID) 2>/dev/null || true; \
		open -a Simulator; \
		echo "⏳ Waiting for simulator to boot..."; \
		sleep 5; \
		echo "✅ Simulator ready"; \
	fi

clean:
	rm -rf node_modules
	rm -rf tests/ios/CDVTTSTests.xcodeproj
	rm -rf tests/android/build tests/android/.gradle
	rm -rf $(E2E_APP)/platforms $(E2E_APP)/plugins $(E2E_APP)/node_modules
