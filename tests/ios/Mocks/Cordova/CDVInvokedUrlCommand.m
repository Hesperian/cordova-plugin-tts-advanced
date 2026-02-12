#import "CDVInvokedUrlCommand.h"

@implementation CDVInvokedUrlCommand

+ (instancetype)commandWithCallbackId:(NSString *)callbackId arguments:(NSArray *)arguments {
    CDVInvokedUrlCommand *cmd = [[CDVInvokedUrlCommand alloc] init];
    cmd.callbackId = callbackId;
    cmd.arguments = arguments;
    return cmd;
}

@end
