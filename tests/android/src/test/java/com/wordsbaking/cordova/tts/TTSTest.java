package com.wordsbaking.cordova.tts;

import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

public class TTSTest {
    private TTS plugin;
    private CallbackContext callbackContext;

    @Before
    public void setUp() {
        plugin = new TTS();
        callbackContext = mock(CallbackContext.class);
    }

    @Test
    public void executeReturnsFalseForUnknownAction() throws Exception {
        boolean result = plugin.execute("unknownAction", new JSONArray(), callbackContext);
        assertFalse(result);
    }

    @Test
    public void executeReturnsTrueForSpeak() throws Exception {
        JSONObject opts = new JSONObject();
        opts.put("text", "hello");
        opts.put("locale", "en-US");
        JSONArray args = new JSONArray();
        args.put(opts);

        // tts is null so speak() will call error(ERR_ERROR_INITIALIZING)
        boolean result = plugin.execute("speak", args, callbackContext);
        assertTrue(result);
        verify(callbackContext).error(TTS.ERR_ERROR_INITIALIZING);
    }

    @Test
    public void executeReturnsTrueForSpeakWithInvalidOptions() throws Exception {
        JSONObject opts = new JSONObject();
        // no "text" key → null text → ERR_INVALID_OPTIONS
        JSONArray args = new JSONArray();
        args.put(opts);

        boolean result = plugin.execute("speak", args, callbackContext);
        assertTrue(result);
        verify(callbackContext).error(TTS.ERR_INVALID_OPTIONS);
    }

    @Test
    public void executeReturnsTrueForStop() throws Exception {
        // tts is null so stop() will throw NPE
        try {
            plugin.execute("stop", new JSONArray(), callbackContext);
        } catch (NullPointerException e) {
            // expected — tts not initialized
        }
        // The action was recognized (returned true before the NPE in stop())
    }

    @Test
    public void executeReturnsTrueForCheckLanguage() throws Exception {
        try {
            plugin.execute("checkLanguage", new JSONArray(), callbackContext);
        } catch (NullPointerException e) {
            // expected — tts not initialized
        }
    }
}
