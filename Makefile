.PHONY: test test-js test-ios test-android clean

IOS_SIM_ID := $(shell xcrun simctl list devices available -j | python3 -c "import sys,json; devs=[d for r in json.loads(sys.stdin.read())['devices'].values() for d in r if 'iPhone' in d['name'] and d['isAvailable']]; print(devs[0]['udid'])" 2>/dev/null)

test: test-js test-ios test-android

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

clean:
	rm -rf node_modules
	rm -rf tests/ios/CDVTTSTests.xcodeproj
	rm -rf tests/android/build tests/android/.gradle
