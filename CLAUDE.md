# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cordova Text-to-Speech plugin (Hesperian fork of spasma/cordova-plugin-tts-advanced). Provides a Promise-based JavaScript API to native TTS engines on iOS and Android. Used in production by the hesperian-mobile app.

## Build & Development

There is no standalone build, test, or lint system. The plugin is integrated into Cordova apps via:
```
cordova plugin add cordova-plugin-tts-advanced
```
Native code compiles as part of the host Cordova app build (Xcode for iOS, Gradle for Android).

**Note:** `plugin.xml` version (0.3.0) differs from `package.json` version (0.4.1) — keep these in sync when updating.

## Architecture

```
www/tts.js          → JS API (Promise wrappers around cordova.exec)
src/ios/CDVTTS.m    → iOS native impl (AVSpeechSynthesizer, Objective-C)
src/ios/CDVTTS.h    → iOS header
src/android/TTS.java → Android native impl (TextToSpeech API, Java)
plugin.xml          → Cordova plugin manifest (feature registration, file mappings)
```

**Flow:** JS call → `www/tts.js` (Promise wrapper) → `cordova.exec` bridge → native platform code → OS TTS engine → audio output. Callbacks resolve/reject the JS Promise.

**API methods:** `speak(text|options)`, `stop()`, `checkLanguage()`, `getVoices()`, `openInstallTts()`

**Key design decisions:**
- Default behavior queues speech (doesn't cancel previous). Use `{cancel: true}` to cancel.
- Voice selection by `locale` (both platforms) or `voiceURI` (iOS only).
- Native code manages callback IDs to resolve the correct JS Promise when speech completes.

## Known Bugs (documented in IOS_CALLBACK_BUG_ANALYSIS.md)

- **iOS:** Missing `didCancelSpeechUtterance:` delegate and missing callback cleanup in `stop:` — causes orphaned callbacks during stop→speak transitions.
- **Android:** `TTS.java` line 253 passes `null` instead of the utterance ID created at line 225, breaking callback resolution.
- **Both platforms:** `stop()` command doesn't send a result for its own callback.
- The consuming app (hesperian-mobile) uses a JS-side `speakingID` guard as a workaround.

## Platform Support

- iOS 7+ (AVSpeechSynthesizer)
- Android 4.0.3+ (API 15, TextToSpeech)
- Windows Phone support was removed
