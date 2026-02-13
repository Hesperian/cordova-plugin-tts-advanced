# iOS Callback Management Bug in CDVTTS.m

## Summary

The iOS TTS plugin has a callback management bug that causes "Play from here" (stop→speak transitions) to break continuous audio playback in the consuming app (hesperian-mobile). After a stop→speak sequence, the current speak's Cordova callback is orphaned and never resolves on the JS side, preventing the app from knowing when speech finishes.

A JS-side workaround (speakingID guard) was deployed in commit `b84fd7d` of hesperian-mobile to prevent the most visible symptom (wrong block highlighted), but the underlying issue — orphaned callbacks — still causes playback to stall after one block.

A draft JS-side engine wrapper exists as an unstaged change in `hesperian-mobile/lib/audio-buttons/audio-engine.js` (`createCordovaTTSEngine`), but fixing the native plugin directly is the cleaner solution.

## The Bug

### Relevant code in CDVTTS.m

Instance variables (`CDVTTS.h` lines 16-17):
```objc
NSString* lastCallbackId;   // previously queued callback
NSString* callbackId;       // current callback
```

**`speak:`** (lines 41-97) saves the old callback before storing the new one:
```objc
if (callbackId) {
    lastCallbackId = callbackId;   // save old
}
callbackId = command.callbackId;   // store new
```

**`didFinishSpeechUtterance:`** (lines 25-39) resolves `lastCallbackId` first if set:
```objc
if (lastCallbackId) {
    [self.commandDelegate sendPluginResult:result callbackId:lastCallbackId];
    lastCallbackId = nil;
} else {
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    callbackId = nil;
}
```

**`stop:`** (lines 99-102) does **not** clear either callback ID:
```objc
- (void)stop:(CDVInvokedUrlCommand*)command {
    [synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    // callbackId and lastCallbackId are NOT cleared
    // No result is sent for the stop command's own callback
    // didCancelSpeechUtterance: delegate is NOT implemented
}
```

### Two missing pieces

1. **`didCancelSpeechUtterance:` is not implemented.** When `stopSpeakingAtBoundary:` cancels an utterance, iOS calls `didCancelSpeechUtterance:` (not `didFinishSpeechUtterance:`). Since this delegate method doesn't exist, the cancelled utterance's callback is never resolved or rejected on the JS side.

2. **`stop:` doesn't clear callback state.** After stop, `callbackId` still holds the cancelled speak's callback ID. When the next `speak:` arrives, this stale ID gets saved as `lastCallbackId`.

### Race condition timeline

```
1. Block A is speaking.
   callbackId = A_cb, lastCallbackId = nil

2. JS calls stop (user triggered "Play from here").
   → stopSpeakingAtBoundary cancels A's utterance
   → iOS calls didCancelSpeechUtterance: (NOT IMPLEMENTED)
   → A_cb is NEVER resolved
   → callbackId = A_cb (still set!)

3. JS calls speak(X) for the new block.
   → speak: sees callbackId (A_cb) is set → lastCallbackId = A_cb
   → callbackId = X_cb
   → utterance X starts speaking

4. X finishes speaking → didFinishSpeechUtterance: fires.
   → lastCallbackId (A_cb) is set → resolves A_cb (STALE!)
   → lastCallbackId = nil
   → callbackId (X_cb) is NOT resolved (if/else, not sequential)

5. Result: X_cb is orphaned. The JS-side promise for speak(X) never
   settles. The app cannot advance to the next block.
```

This creates a permanent chain: every subsequent stop→speak leaves one orphaned callback. The stale callback from the *previous* stop→speak gets resolved, but the *current* one is stuck.

### Effect on the app

- **Continuous playback breaks** after any "Play from here" interaction — the current block plays and highlights correctly, but the app never learns it finished, so it stops advancing.
- **"Stop first, then play from here" works** because the manual stop gives time for stale callbacks to resolve harmlessly (JS `nowPlaying` is already null), clearing the native callback chain.
- **Accumulated stale callbacks** can cause very delayed or unexpected playback resumption.

## Proposed Native Fixes

### Fix 1: Implement `didCancelSpeechUtterance:`

When iOS cancels an utterance (via `stopSpeakingAtBoundary:`), resolve the pending callbacks with an error status so the JS promise settles:

```objc
- (void)speechSynthesizer:(AVSpeechSynthesizer*)synth
    didCancelSpeechUtterance:(AVSpeechUtterance*)utterance {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                               messageAsString:@"cancelled"];
    if (lastCallbackId) {
        [self.commandDelegate sendPluginResult:result callbackId:lastCallbackId];
        lastCallbackId = nil;
    }
    if (callbackId) {
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        callbackId = nil;
    }

    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient
      withOptions: 0 error: nil];
    [[AVAudioSession sharedInstance] setActive:YES withOptions: 0 error:nil];
}
```

### Fix 2: Clear callbacks in `stop:`

As a belt-and-suspenders measure, also clear callbacks directly in the `stop:` method. This handles the case where `didCancelSpeechUtterance:` might not fire (e.g., if nothing is currently speaking):

```objc
- (void)stop:(CDVInvokedUrlCommand*)command {
    [synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];

    // Resolve any pending speak callbacks so the JS side isn't stuck
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                               messageAsString:@"cancelled"];
    if (lastCallbackId) {
        [self.commandDelegate sendPluginResult:result callbackId:lastCallbackId];
        lastCallbackId = nil;
    }
    if (callbackId) {
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        callbackId = nil;
    }

    // Also send a result for the stop command's own callback
    CDVPluginResult* stopResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:stopResult callbackId:command.callbackId];
}
```

### Fix interaction: both fixes together

If both `stop:` and `didCancelSpeechUtterance:` clear callbacks, there's a potential double-send if `didCancelSpeechUtterance:` fires after `stop:` already cleared them. The nil checks on `lastCallbackId`/`callbackId` prevent this — once set to nil, the second path is a no-op.

However, consider whether `didCancelSpeechUtterance:` fires synchronously within `stopSpeakingAtBoundary:` or asynchronously after. If synchronous, it fires *before* `stop:` clears callbacks, so `stop:` finds them already nil. If asynchronous, `stop:` clears them first, and `didCancelSpeechUtterance:` finds them nil. Either way, the nil guards prevent double-send.

### JS-side impact

The JS consumer (`hesperian-mobile/lib/audio-buttons/audio.js`) uses `.finally()` on the speak promise. When the promise rejects (with "cancelled"), `.finally()` still fires, calling `doSpeechCommandCompleted(expectedSpeakingID)`. The speakingID guard (commit `b84fd7d`) ensures stale completions are ignored — only the matching speakingID triggers block advancement. So rejecting stale callbacks with an error is safe.

## Android Issue (Separate Bug)

The Android plugin (`TTS.java`) has a separate bug: the `utteranceId` is not passed to `tts.speak()`.

**Line 224-225** creates a HashMap with the callback ID:
```java
HashMap<String, String> ttsParams = new HashMap<String, String>();
ttsParams.put(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, callbackContext.getCallbackId());
```

**But lines 252-256** pass `null` instead of using it:
```java
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    tts.speak(text, cancel?TextToSpeech.QUEUE_FLUSH:TextToSpeech.QUEUE_ADD, null, null);
                                                                            ^^^^  ^^^^
                                                               should be: params, callbackId
}
```

Without the utterance ID, Android's `UtteranceProgressListener.onDone(String callbackId)` receives `null`, so the `!callbackId.equals("")` check (line 70) would throw a NullPointerException, and the speak promise never resolves on the JS side.

### Android fix

```java
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    tts.speak(text,
              cancel ? TextToSpeech.QUEUE_FLUSH : TextToSpeech.QUEUE_ADD,
              null,
              callbackContext.getCallbackId());
} else {
    tts.speak(text,
              cancel ? TextToSpeech.QUEUE_FLUSH : TextToSpeech.QUEUE_ADD,
              ttsParams);
}
```

And add a null guard in the `onDone` listener:
```java
@Override
public void onDone(String callbackId) {
    if (callbackId != null && !callbackId.equals("")) {
        CallbackContext context = new CallbackContext(callbackId, webView);
        context.success();
    }
}

@Override
public void onError(String callbackId) {
    if (callbackId != null && !callbackId.equals("")) {
        CallbackContext context = new CallbackContext(callbackId, webView);
        context.error(ERR_UNKNOWN);
    }
}
```

Also, the `stop()` method (line 125-128) should resolve its own callback and, like the iOS fix, handle any pending speak callback:
```java
private void stop(JSONArray args, CallbackContext callbackContext)
        throws JSONException, NullPointerException {
    tts.stop();
    callbackContext.success();
}
```

## Context: JS-Side Architecture

The consuming app (`hesperian-mobile`) has three audio layers:

```
audio-buttons.js  → UI: toolbar, double-click "Play from here", block highlighting
audio.js          → State: speak/stop, nowPlaying tracking, speakingID
audio-engine.js   → Abstraction: Cordova TTS plugin / Web Speech API / debug engine
```

### How speak/stop flows through the JS:

**speak(context)** in `audio.js`:
1. Increments `speakingID`
2. Sets `nowPlaying = {speakingID, context, mode: STARTING}`
3. `setTimeout(checkSpeechQueue, 0)` — defers native speak one tick
4. `checkSpeechQueue()` calls `getAudioEngine().speak(context).finally(() => doSpeechCommandCompleted(speakingID))`

**stop()** in `audio.js`:
1. Calls `getAudioEngine().stop()` (async to native)
2. Sets `nowPlaying = null` (immediate)

**doSpeechCommandCompleted(expectedSpeakingID)**:
1. If `!nowPlaying` → return (already stopped)
2. If `nowPlaying.speakingID !== expectedSpeakingID` → return (stale completion, Fix 3)
3. Emits `speechStopped` event → triggers `playNextBlock()` in audio-buttons.js

### "Play from here" handler (audio-buttons.js):
```javascript
self.stopBlock();              // → audio.js stop() → native stop + nowPlaying = null
self.currentBlockIndex = idx;  // set to clicked block
self.playBlock();              // → highlight + audio.js speak() → native speak
```

All three calls are synchronous. The native stop and speak are dispatched via Cordova exec (async), and `checkSpeechQueue` runs on the next tick via `setTimeout(0)`.

### Existing JS-side fix (commit b84fd7d in hesperian-mobile):

Guards `doSpeechCommandCompleted` with a speakingID check so that stale promise completions (from orphaned callbacks) don't trigger block advancement for the wrong block. This prevents the "one behind highlighting" symptom but doesn't fix the orphaned callback problem itself — the current block's promise stays pending.

### Draft JS-side wrapper (unstaged in hesperian-mobile):

A `createCordovaTTSEngine()` wrapper in `audio-engine.js` that intercepts `window.TTS` and manages promise resolution at the JS level. Platform-specific behavior:
- **iOS path**: uses a shared `resolveActive()` so any native callback (even stale) resolves the current promise
- **Android path**: each speak's `.then(resolve, resolve)` uses its own closure, so stale callbacks only settle their own already-settled promise

This wrapper would be unnecessary if the native fixes above are applied.
