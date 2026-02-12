#import "CDVPluginResult.h"

@implementation CDVPluginResult

+ (instancetype)resultWithStatus:(CDVCommandStatus)status {
    CDVPluginResult *r = [[CDVPluginResult alloc] init];
    r.status = status;
    return r;
}

+ (instancetype)resultWithStatus:(CDVCommandStatus)status messageAsString:(NSString *)message {
    CDVPluginResult *r = [self resultWithStatus:status];
    r.message = message;
    return r;
}

+ (instancetype)resultWithStatus:(CDVCommandStatus)status messageAsArray:(NSArray *)message {
    CDVPluginResult *r = [self resultWithStatus:status];
    r.message = message;
    return r;
}

@end
