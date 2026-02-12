import { describe, it, expect, vi, beforeEach } from "vitest";

let tts;

beforeEach(() => {
  vi.resetModules();
  globalThis.cordova = { exec: vi.fn() };
});

async function loadTts() {
  tts = await import("../../www/tts.js");
}

describe("speak", () => {
  it("calls cordova.exec with service TTS and action speak", async () => {
    await loadTts();
    tts.speak({ text: "hello" });
    expect(cordova.exec).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      "TTS",
      "speak",
      [{ text: "hello" }]
    );
  });

  it("wraps a string argument into { text: string }", async () => {
    await loadTts();
    tts.speak("hello");
    expect(cordova.exec).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      "TTS",
      "speak",
      [{ text: "hello" }]
    );
  });

  it("passes an object argument through unchanged", async () => {
    await loadTts();
    const opts = { text: "hi", locale: "en-US", rate: 1.5 };
    tts.speak(opts);
    expect(cordova.exec).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      "TTS",
      "speak",
      [opts]
    );
  });

  it("resolves when exec success callback fires", async () => {
    cordova.exec.mockImplementation((success) => success("done"));
    await loadTts();
    const result = await tts.speak("hello");
    expect(result).toBe("done");
  });

  it("rejects when exec error callback fires", async () => {
    cordova.exec.mockImplementation((_success, error) => error("fail"));
    await loadTts();
    await expect(tts.speak("hello")).rejects.toBe("fail");
  });
});

describe("stop", () => {
  it("calls cordova.exec with action stop and empty args", async () => {
    await loadTts();
    tts.stop();
    expect(cordova.exec).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      "TTS",
      "stop",
      []
    );
  });
});

describe("checkLanguage", () => {
  it("calls cordova.exec with action checkLanguage", async () => {
    await loadTts();
    tts.checkLanguage();
    expect(cordova.exec).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      "TTS",
      "checkLanguage",
      []
    );
  });
});

describe("getVoices", () => {
  it("calls cordova.exec with action getVoices", async () => {
    await loadTts();
    tts.getVoices();
    expect(cordova.exec).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      "TTS",
      "getVoices",
      []
    );
  });
});

describe("openInstallTts", () => {
  it("calls cordova.exec with action openInstallTts", async () => {
    await loadTts();
    tts.openInstallTts();
    expect(cordova.exec).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      "TTS",
      "openInstallTts",
      []
    );
  });
});
