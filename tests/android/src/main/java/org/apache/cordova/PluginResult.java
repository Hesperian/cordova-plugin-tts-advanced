package org.apache.cordova;

public class PluginResult {
    public enum Status {
        NO_RESULT,
        OK,
        CLASS_NOT_FOUND_EXCEPTION,
        ILLEGAL_ACCESS_EXCEPTION,
        INSTANTIATION_EXCEPTION,
        MALFORMED_URL_EXCEPTION,
        IO_EXCEPTION,
        INVALID_ACTION,
        JSON_EXCEPTION,
        ERROR
    }

    private final Status status;
    private final String message;

    public PluginResult(Status status) {
        this.status = status;
        this.message = null;
    }

    public PluginResult(Status status, String message) {
        this.status = status;
        this.message = message;
    }

    public Status getStatus() { return status; }
    public String getMessage() { return message; }
}
