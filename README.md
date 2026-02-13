# Cordova Text-to-Speech Plugin Advanced
Updated Cordova Text-to-Speech plugin, with support for voices on android by locale and VoiceURI on iOS.

## Breaking changes with VILIC VANE version
In this tts plugin you'll need to provide the 'cancel' argument if you want to cancel earlier TTS commands, new lines are added to the queue. 
To keep old behaviour add: `{cancel: true}` to every call.

If no locale is provided, it will use the OS default language. to keep old behaviour, add: `{locale: 'en-US'}` to every call. 

Support for Windows Phone was removed, because it is no more..

## Platforms

iOS 7+  
Android 4.0.3+ (API Level 15+)

## Installation

```sh
cordova plugin add cordova-plugin-tts-advanced
```

## Usage

```javascript
// make sure your the code gets executed only after `deviceready`.
document.addEventListener('deviceready', function () {
    // basic usage
    TTS
        .speak('hello, world!').then(function () {
            alert('success');
        }, function (reason) {
            alert(reason);
        });

    // or with more options
    TTS
        .speak({
            text: 'hello, world!',
            locale: 'en-US',
            rate: 0.75,
            pitch: 0.9,
            cancel: true
        }).then(function () {
            alert('success');
        }, function (reason) {
            alert(reason);
        });
}, false);
```

**Tips:** `speak` an empty string to interrupt.

```typescript
declare namespace TTS {
    interface IOptions {
        /** text to speak */
        text: string;
        /** iOS ONLY: a voice URI **/
        voiceURI?: string;
        /** a string like 'en-US', 'zh-CN', etc [only used when no voiceURI is given] */
        locale?: string;
        /** speed rate, 0 ~ 1 */
        rate?: number;
        /** pitch, 0 ~ 1 */
        pitch?: number;
        /** cancel, boolean: true/false */
        cancel?: boolean;
    }

    function speak(options: IOptions): Promise<void>;
    function speak(text: string): Promise<void>;
    function stop(): Promise<void>;
    function checkLanguage(): Promise<string>;
    function openInstallTts(): Promise<void>;
}
```

## Development

### Testing

The plugin has comprehensive test coverage at multiple levels:

```bash
# Unit tests (fast, with mocked TTS engines)
make test               # All unit tests
make test-js            # JavaScript unit tests
make test-android       # Android unit tests
make test-ios           # iOS unit tests

# E2E tests (manual, with real TTS engines)
make e2e-setup          # One-time: install deps and link plugin
make e2e-android-run    # Launch emulator + run tests
make e2e-ios-run        # Launch simulator + run tests

# Launch devices manually (optional)
make emulator-android   # Launch Android emulator (Pixel 6)
make simulator-ios      # Launch iOS simulator (iPhone 16 Pro)
```

**E2E Testing:** A Cordova test app in `e2e/tts-test-cordova-android13-ios7/` provides manual testing with real TTS engines. This catches integration issues that unit tests can't detect (like the null utteranceId warmup bug).

**First time setup:**
```bash
make e2e-setup      # Install and link plugin
```

**Run tests (automatically launches emulator/simulator):**
```bash
make e2e-android-run    # Launches Pixel 6 emulator + runs tests
make e2e-ios-run        # Launches iPhone 16 Pro simulator + runs tests
```

See `e2e/tts-test-cordova-android13-ios7/README.md` for details.

**Multiple Cordova Versions:** Additional test apps can be added to `e2e/` with version-specific names (e.g., `tts-test-cordova-android12-ios6/`) to ensure compatibility across different Cordova versions.

### Contributing

1. Write tests for new features (unit tests + e2e verification)
2. Run `make test` to verify unit tests pass
3. Test manually with the Cordova test app on real devices/simulators
4. Update documentation as needed
