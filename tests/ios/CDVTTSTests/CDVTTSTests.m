#import <XCTest/XCTest.h>
#import "CDVTTS.h"
#import "CDVPluginResult.h"
#import "CDVInvokedUrlCommand.h"

#pragma mark - MockCommandDelegate

@interface MockCommandDelegate : NSObject <CDVCommandDelegate>
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *sentResults;
@end

@implementation MockCommandDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _sentResults = [NSMutableArray array];
    }
    return self;
}

- (void)sendPluginResult:(CDVPluginResult *)result callbackId:(NSString *)callbackId {
    [self.sentResults addObject:@{
        @"result": result,
        @"callbackId": callbackId ?: @""
    }];
}

@end

#pragma mark - CDVTTSTests

@interface CDVTTSTests : XCTestCase
@property (nonatomic, strong) CDVTTS *plugin;
@property (nonatomic, strong) MockCommandDelegate *mockDelegate;
@end

@implementation CDVTTSTests

- (void)setUp {
    [super setUp];
    self.plugin = [[CDVTTS alloc] init];
    self.mockDelegate = [[MockCommandDelegate alloc] init];
    self.plugin.commandDelegate = self.mockDelegate;
    [self.plugin pluginInitialize];
}

#pragma mark - Helper

- (void)simulateDidFinish {
    [(id<AVSpeechSynthesizerDelegate>)self.plugin speechSynthesizer:nil didFinishSpeechUtterance:nil];
}

- (void)simulateDidCancel {
    [(id<AVSpeechSynthesizerDelegate>)self.plugin speechSynthesizer:nil didCancelSpeechUtterance:nil];
}

#pragma mark - checkLanguage

- (void)testCheckLanguageReturnsOK {
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb1" arguments:@[]];
    [self.plugin checkLanguage:cmd];

    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    NSString *cbId = self.mockDelegate.sentResults[0][@"callbackId"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(cbId, @"cb1");
}

- (void)testCheckLanguageResultIsString {
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb1" arguments:@[]];
    [self.plugin checkLanguage:cmd];

    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    XCTAssertTrue([result.message isKindOfClass:[NSString class]],
                  @"checkLanguage message should be an NSString");
}

#pragma mark - getVoices

- (void)testGetVoicesReturnsOK {
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb2" arguments:@[]];
    [self.plugin getVoices:cmd];

    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    NSString *cbId = self.mockDelegate.sentResults[0][@"callbackId"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(cbId, @"cb2");
}

- (void)testGetVoicesResultIsArray {
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb2" arguments:@[]];
    [self.plugin getVoices:cmd];

    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    XCTAssertTrue([result.message isKindOfClass:[NSArray class]],
                  @"getVoices message should be an NSArray");
}

#pragma mark - speak variations

- (void)testSpeakSetsCallbackId {
    NSDictionary *options = @{@"text": @"hello"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb3" arguments:@[options]];
    [self.plugin speak:cmd];

    // speak is async (result sent via delegate callback), so no immediate result
    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

- (void)testSpeakWithAllOptions {
    NSDictionary *options = @{
        @"text": @"hello world",
        @"locale": @"en-US",
        @"rate": @0.5,
        @"pitch": @1.2,
        @"volume": @0.8,
        @"cancel": @YES
    };
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-all" arguments:@[options]];
    [self.plugin speak:cmd];

    // No crash, no immediate result (async)
    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

- (void)testSpeakWithTextOnly {
    NSDictionary *options = @{@"text": @"just text"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-text" arguments:@[options]];
    [self.plugin speak:cmd];

    // Defaults apply, no crash
    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

- (void)testSpeakWithCancelTrue {
    NSDictionary *options = @{@"text": @"cancel me", @"cancel": @YES};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-cancel" arguments:@[options]];
    [self.plugin speak:cmd];

    // cancel=true path exercised, no crash
    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

- (void)testSpeakWithVoiceURI {
    // voiceURI path — voice may not be found but should not crash
    NSDictionary *options = @{@"text": @"voice uri", @"voiceURI": @"com.apple.ttsbundle.siri_Nicky_en-US_compact"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-uri" arguments:@[options]];
    [self.plugin speak:cmd];

    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

- (void)testSpeakDefaultRatePitchVolume {
    // No rate/pitch/volume → defaults applied without crash
    NSDictionary *options = @{@"text": @"defaults"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-def" arguments:@[options]];
    [self.plugin speak:cmd];

    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

#pragma mark - didFinishSpeechUtterance delegate

- (void)testDidFinishResolvesCallbackWithOK {
    NSDictionary *options = @{@"text": @"hello"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-finish" arguments:@[options]];
    [self.plugin speak:cmd];

    [self simulateDidFinish];

    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    NSString *cbId = self.mockDelegate.sentResults[0][@"callbackId"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(cbId, @"cb-finish");
}

- (void)testDidFinishClearsCallbackId {
    NSDictionary *options = @{@"text": @"hello"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-clear" arguments:@[options]];
    [self.plugin speak:cmd];

    [self simulateDidFinish];

    // callbackId should be cleared after didFinish
    NSString *storedCallbackId = [self.plugin valueForKey:@"callbackId"];
    XCTAssertNil(storedCallbackId, @"callbackId should be nil after didFinish");

    // Second didFinish should do nothing (sends result with nil callbackId)
    NSUInteger countBefore = self.mockDelegate.sentResults.count;
    [self simulateDidFinish];
    // It will still send a result (with nil callbackId → empty string in mock), documenting current behavior
    XCTAssertEqual(self.mockDelegate.sentResults.count, countBefore + 1);
}

- (void)testDidFinishWithQueuedSpeaks {
    // Two speaks → first sets callbackId, second moves it to lastCallbackId
    NSDictionary *options1 = @{@"text": @"first"};
    CDVInvokedUrlCommand *cmd1 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-first" arguments:@[options1]];
    [self.plugin speak:cmd1];

    NSDictionary *options2 = @{@"text": @"second"};
    CDVInvokedUrlCommand *cmd2 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-second" arguments:@[options2]];
    [self.plugin speak:cmd2];

    // First didFinish resolves lastCallbackId (cb-first)
    [self simulateDidFinish];
    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    XCTAssertEqualObjects(self.mockDelegate.sentResults[0][@"callbackId"], @"cb-first");

    // Second didFinish resolves callbackId (cb-second)
    [self simulateDidFinish];
    XCTAssertEqual(self.mockDelegate.sentResults.count, 2);
    XCTAssertEqualObjects(self.mockDelegate.sentResults[1][@"callbackId"], @"cb-second");
}

- (void)testDidFinishResolvesLastCallbackIdFirst {
    // Verify that when both callbackId and lastCallbackId are set,
    // lastCallbackId is resolved first
    NSDictionary *options1 = @{@"text": @"first"};
    CDVInvokedUrlCommand *cmd1 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-old" arguments:@[options1]];
    [self.plugin speak:cmd1];

    NSDictionary *options2 = @{@"text": @"second"};
    CDVInvokedUrlCommand *cmd2 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-new" arguments:@[options2]];
    [self.plugin speak:cmd2];

    // Verify lastCallbackId is set
    NSString *lastCbId = [self.plugin valueForKey:@"lastCallbackId"];
    XCTAssertEqualObjects(lastCbId, @"cb-old");

    // First finish should resolve lastCallbackId
    [self simulateDidFinish];
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(self.mockDelegate.sentResults[0][@"callbackId"], @"cb-old");

    // lastCallbackId should now be nil
    lastCbId = [self.plugin valueForKey:@"lastCallbackId"];
    XCTAssertNil(lastCbId);
}

#pragma mark - didCancelSpeechUtterance delegate

- (void)testDidCancelResolvesCallbackWithError {
    NSDictionary *options = @{@"text": @"hello"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-cancel" arguments:@[options]];
    [self.plugin speak:cmd];

    // Call stop: which should resolve the callback, then didCancel delegate fires
    CDVInvokedUrlCommand *stopCmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-stop" arguments:@[]];
    [self.plugin stop:stopCmd];

    // Should have 2 results: one for the speak callback, one for stop callback
    XCTAssertEqual(self.mockDelegate.sentResults.count, 2);
    
    // First result should be the speak callback with error
    CDVPluginResult *speakResult = self.mockDelegate.sentResults[0][@"result"];
    NSString *speakCbId = self.mockDelegate.sentResults[0][@"callbackId"];
    XCTAssertEqual(speakResult.status, CDVCommandStatus_ERROR);
    XCTAssertEqualObjects(speakResult.message, @"cancelled");
    XCTAssertEqualObjects(speakCbId, @"cb-cancel");
    
    // Second result should be the stop callback with OK
    CDVPluginResult *stopResult = self.mockDelegate.sentResults[1][@"result"];
    NSString *stopCbId = self.mockDelegate.sentResults[1][@"callbackId"];
    XCTAssertEqual(stopResult.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(stopCbId, @"cb-stop");
}

- (void)testDidCancelClearsBothCallbackIds {
    NSDictionary *options1 = @{@"text": @"first"};
    CDVInvokedUrlCommand *cmd1 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-1" arguments:@[options1]];
    [self.plugin speak:cmd1];

    NSDictionary *options2 = @{@"text": @"second"};
    CDVInvokedUrlCommand *cmd2 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-2" arguments:@[options2]];
    [self.plugin speak:cmd2];

    // Call stop: which should resolve both callbacks
    CDVInvokedUrlCommand *stopCmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-stop" arguments:@[]];
    [self.plugin stop:stopCmd];

    // Should have 3 results: cb-1 (cancelled), cb-2 (cancelled), cb-stop (OK)
    XCTAssertEqual(self.mockDelegate.sentResults.count, 3);
    XCTAssertEqualObjects(self.mockDelegate.sentResults[0][@"callbackId"], @"cb-1");
    XCTAssertEqualObjects(self.mockDelegate.sentResults[1][@"callbackId"], @"cb-2");
    XCTAssertEqualObjects(self.mockDelegate.sentResults[2][@"callbackId"], @"cb-stop");

    // Both speak callbacks should be cleared
    XCTAssertNil([self.plugin valueForKey:@"callbackId"]);
    XCTAssertNil([self.plugin valueForKey:@"lastCallbackId"]);
}

- (void)testDidCancelWithNoCallbacksIsNoop {
    // No speaks → no callbacks to resolve
    [self simulateDidCancel];
    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

#pragma mark - stop (fixed behavior)

- (void)testStopSendsOKResult {
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-stop" arguments:@[]];
    [self.plugin stop:cmd];

    // stop sends OK for its own callback
    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    NSString *cbId = self.mockDelegate.sentResults[0][@"callbackId"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(cbId, @"cb-stop");
}

- (void)testStopClearsCallbackState {
    // speak sets callbackId, then stop clears it
    NSDictionary *options = @{@"text": @"hello"};
    CDVInvokedUrlCommand *speakCmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-speak" arguments:@[options]];
    [self.plugin speak:speakCmd];

    CDVInvokedUrlCommand *stopCmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-stop" arguments:@[]];
    [self.plugin stop:stopCmd];

    // callbackId cleared after stop
    XCTAssertNil([self.plugin valueForKey:@"callbackId"]);
    XCTAssertNil([self.plugin valueForKey:@"lastCallbackId"]);
}

- (void)testStopResolvesPendingSpeakCallbackWithError {
    NSDictionary *options = @{@"text": @"hello"};
    CDVInvokedUrlCommand *speakCmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-speak" arguments:@[options]];
    [self.plugin speak:speakCmd];

    CDVInvokedUrlCommand *stopCmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-stop" arguments:@[]];
    [self.plugin stop:stopCmd];

    // Should have 2 results: cancelled speak + OK stop
    XCTAssertEqual(self.mockDelegate.sentResults.count, 2);

    // First: speak callback cancelled
    CDVPluginResult *speakResult = self.mockDelegate.sentResults[0][@"result"];
    XCTAssertEqual(speakResult.status, CDVCommandStatus_ERROR);
    XCTAssertEqualObjects(speakResult.message, @"cancelled");
    XCTAssertEqualObjects(self.mockDelegate.sentResults[0][@"callbackId"], @"cb-speak");

    // Second: stop's own OK result
    CDVPluginResult *stopResult = self.mockDelegate.sentResults[1][@"result"];
    XCTAssertEqual(stopResult.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(self.mockDelegate.sentResults[1][@"callbackId"], @"cb-stop");
}

- (void)testStopThenSpeakDoesNotOrphanCallback {
    // This is the core bug scenario: stop→speak should not leave orphaned callbacks
    NSDictionary *optionsA = @{@"text": @"block A"};
    CDVInvokedUrlCommand *speakA = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-A" arguments:@[optionsA]];
    [self.plugin speak:speakA];

    // Stop cancels A
    CDVInvokedUrlCommand *stopCmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-stop" arguments:@[]];
    [self.plugin stop:stopCmd];

    // Clear sent results to focus on the new speak
    [self.mockDelegate.sentResults removeAllObjects];

    // Speak X (the new block)
    NSDictionary *optionsX = @{@"text": @"block X"};
    CDVInvokedUrlCommand *speakX = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-X" arguments:@[optionsX]];
    [self.plugin speak:speakX];

    // No stale callback should be queued
    XCTAssertNil([self.plugin valueForKey:@"lastCallbackId"],
                 @"No stale lastCallbackId after stop cleared state");
    XCTAssertEqualObjects([self.plugin valueForKey:@"callbackId"], @"cb-X");

    // When X finishes, it should resolve cb-X (not a stale callback)
    [self simulateDidFinish];
    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    XCTAssertEqualObjects(self.mockDelegate.sentResults[0][@"callbackId"], @"cb-X");
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
}

#pragma mark - Queuing

- (void)testSpeakTwiceQueuesCallbackIds {
    NSDictionary *options1 = @{@"text": @"first"};
    CDVInvokedUrlCommand *cmd1 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-q1" arguments:@[options1]];
    [self.plugin speak:cmd1];

    NSDictionary *options2 = @{@"text": @"second"};
    CDVInvokedUrlCommand *cmd2 = [CDVInvokedUrlCommand commandWithCallbackId:@"cb-q2" arguments:@[options2]];
    [self.plugin speak:cmd2];

    // Second speak should have saved first callbackId as lastCallbackId
    NSString *currentCbId = [self.plugin valueForKey:@"callbackId"];
    NSString *lastCbId = [self.plugin valueForKey:@"lastCallbackId"];
    XCTAssertEqualObjects(currentCbId, @"cb-q2");
    XCTAssertEqualObjects(lastCbId, @"cb-q1");
}

@end
