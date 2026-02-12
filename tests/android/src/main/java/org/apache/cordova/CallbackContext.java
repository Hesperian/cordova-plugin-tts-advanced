package org.apache.cordova;

public class CallbackContext {
    private final String callbackId;
    private final CordovaWebView webView;

    public CallbackContext(String callbackId, CordovaWebView webView) {
        this.callbackId = callbackId;
        this.webView = webView;
    }

    public String getCallbackId() {
        return callbackId;
    }

    public void success() {}
    public void success(String message) {}
    public void error(String message) {}

    public void sendPluginResult(PluginResult result) {}
}
