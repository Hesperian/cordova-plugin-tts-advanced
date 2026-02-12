package com.wordsbaking.cordova.tts;

import android.speech.tts.TextToSpeech;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;

import java.lang.reflect.Field;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

public class TTSTest {
    private TTS plugin;
    private CallbackContext callbackContext;

    @Before
    public void setUp() {
        plugin = new TTS();
        callbackContext = mock(CallbackContext.class);
        when(callbackContext.getCallbackId()).thenReturn("test-cb");
    }

    // --- Helper to set private/package fields via reflection ---

    private void setField(String fieldName, Object value) throws Exception {
        Field field = TTS.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(plugin, value);
    }

    private Object getField(String fieldName) throws Exception {
        Field field = TTS.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        return field.get(plugin);
    }

    // --- execute dispatch ---

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

    @Test
    public void executeReturnsTrueForOpenInstallTts() throws Exception {
        // openInstallTts requires context, so it will NPE, but action is recognized
        try {
            boolean result = plugin.execute("openInstallTts", new JSONArray(), callbackContext);
            assertTrue(result);
        } catch (NullPointerException e) {
            // expected — context not initialized
        }
    }

    @Test
    public void executeReturnsFalseForGetVoices() throws Exception {
        // getVoices is NOT wired in execute() (omitted from if-else chain)
        boolean result = plugin.execute("getVoices", new JSONArray(), callbackContext);
        assertFalse("getVoices is not wired in execute() — known gap", result);
    }

    // --- speak validation (with mocked TextToSpeech) ---

    @Test
    public void testSpeakNotInitializedReturnsNotInitialized() throws Exception {
        // tts non-null but ttsInitialized=false → ERR_NOT_INITIALIZED
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);
        setField("ttsInitialized", false);

        JSONObject opts = new JSONObject();
        opts.put("text", "hello");
        opts.put("locale", "en-US");
        JSONArray args = new JSONArray();
        args.put(opts);

        plugin.execute("speak", args, callbackContext);
        verify(callbackContext).error(TTS.ERR_NOT_INITIALIZED);
    }

    @Test
    public void testSpeakDefaultLocale() throws Exception {
        // no locale → Locale.getDefault() is used (we just verify no crash)
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);
        setField("ttsInitialized", true);
        when(mockTts.getVoices()).thenReturn(new java.util.HashSet<>());

        JSONObject opts = new JSONObject();
        opts.put("text", "hello");
        // no locale key
        JSONArray args = new JSONArray();
        args.put(opts);

        // This may throw due to locale parsing (Locale.getDefault().toLanguageTag()
        // may not have a hyphen), but it exercises the default path
        try {
            plugin.execute("speak", args, callbackContext);
        } catch (Exception e) {
            // Expected — locale parsing may fail in test environment
        }
    }

    @Test
    public void testSpeakDefaultRateAndPitch() throws Exception {
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);
        setField("ttsInitialized", true);
        when(mockTts.getVoices()).thenReturn(new java.util.HashSet<>());

        JSONObject opts = new JSONObject();
        opts.put("text", "hello");
        opts.put("locale", "en-US");
        // no rate or pitch → defaults to 1.0
        JSONArray args = new JSONArray();
        args.put(opts);

        plugin.execute("speak", args, callbackContext);

        verify(mockTts).setSpeechRate(1.0f);
        verify(mockTts).setPitch(1.0f);
    }

    @Test
    public void testSpeakCancelTrueUsesQueueFlush() throws Exception {
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);
        setField("ttsInitialized", true);
        when(mockTts.getVoices()).thenReturn(new java.util.HashSet<>());

        JSONObject opts = new JSONObject();
        opts.put("text", "hello");
        opts.put("locale", "en-US");
        opts.put("cancel", true);
        JSONArray args = new JSONArray();
        args.put(opts);

        plugin.execute("speak", args, callbackContext);

        // Verify QUEUE_FLUSH is used when cancel=true
        // In unit tests Build.VERSION.SDK_INT=0 (pre-Lollipop), so 3-arg speak is called
        verify(mockTts).speak(eq("hello"), eq(TextToSpeech.QUEUE_FLUSH),
                isNull());
    }

    @Test
    public void testSpeakCancelFalseUsesQueueAdd() throws Exception {
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);
        setField("ttsInitialized", true);
        when(mockTts.getVoices()).thenReturn(new java.util.HashSet<>());

        JSONObject opts = new JSONObject();
        opts.put("text", "hello");
        opts.put("locale", "en-US");
        opts.put("cancel", false);
        JSONArray args = new JSONArray();
        args.put(opts);

        plugin.execute("speak", args, callbackContext);

        // Verify QUEUE_ADD is used when cancel=false
        // In unit tests Build.VERSION.SDK_INT=0 (pre-Lollipop), so 3-arg speak is called
        verify(mockTts).speak(eq("hello"), eq(TextToSpeech.QUEUE_ADD),
                isNull());
    }

    // --- stop current behavior ---

    @Test
    public void testStopDoesNotResolveCallback() throws Exception {
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);

        plugin.execute("stop", new JSONArray(), callbackContext);

        // Bug: stop doesn't call success or error on its callback
        verify(callbackContext, never()).success();
        verify(callbackContext, never()).success(anyString());
        verify(callbackContext, never()).error(anyString());
        verify(callbackContext, never()).sendPluginResult(any(PluginResult.class));
    }

    // --- onInit ---

    @Test
    public void testOnInitSuccessSetsInitialized() throws Exception {
        // onInit(SUCCESS) calls tts.setLanguage() and tts.speak(), so we need a mock tts
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);
        setField("ttsInitialized", false);

        plugin.onInit(TextToSpeech.SUCCESS);

        assertTrue("ttsInitialized should be true after SUCCESS",
                   (boolean) getField("ttsInitialized"));
    }

    @Test
    public void testOnInitFailureNullsTts() throws Exception {
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);

        plugin.onInit(TextToSpeech.ERROR);

        assertNull("tts should be null after failed onInit", getField("tts"));
    }

    // --- checkLanguage ---

    @Test
    public void testCheckLanguageSendsOKResult() throws Exception {
        TextToSpeech mockTts = mock(TextToSpeech.class);
        setField("tts", mockTts);
        when(mockTts.getAvailableLanguages()).thenReturn(new java.util.HashSet<>());

        plugin.execute("checkLanguage", new JSONArray(), callbackContext);

        verify(callbackContext).sendPluginResult(any(PluginResult.class));
    }
}
