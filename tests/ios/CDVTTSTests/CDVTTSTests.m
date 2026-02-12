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

- (void)testCheckLanguageReturnsOK {
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb1" arguments:@[]];
    [self.plugin checkLanguage:cmd];

    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    NSString *cbId = self.mockDelegate.sentResults[0][@"callbackId"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(cbId, @"cb1");
}

- (void)testGetVoicesReturnsOK {
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb2" arguments:@[]];
    [self.plugin getVoices:cmd];

    XCTAssertEqual(self.mockDelegate.sentResults.count, 1);
    CDVPluginResult *result = self.mockDelegate.sentResults[0][@"result"];
    NSString *cbId = self.mockDelegate.sentResults[0][@"callbackId"];
    XCTAssertEqual(result.status, CDVCommandStatus_OK);
    XCTAssertEqualObjects(cbId, @"cb2");
}

- (void)testSpeakSetsCallbackId {
    NSDictionary *options = @{@"text": @"hello"};
    CDVInvokedUrlCommand *cmd = [CDVInvokedUrlCommand commandWithCallbackId:@"cb3" arguments:@[options]];
    [self.plugin speak:cmd];

    // speak is async (result sent via delegate callback), so no immediate result
    XCTAssertEqual(self.mockDelegate.sentResults.count, 0);
}

@end
