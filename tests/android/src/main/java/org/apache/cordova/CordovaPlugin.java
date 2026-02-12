package org.apache.cordova;

import org.json.JSONArray;
import org.json.JSONException;

public class CordovaPlugin {
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {}

    public boolean execute(String action, JSONArray args, CallbackContext callbackContext)
            throws JSONException {
        return false;
    }
}
