#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CDVCommandStatus) {
    CDVCommandStatus_NO_RESULT = 0,
    CDVCommandStatus_OK,
    CDVCommandStatus_CLASS_NOT_FOUND_EXCEPTION,
    CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION,
    CDVCommandStatus_INSTANTIATION_EXCEPTION,
    CDVCommandStatus_MALFORMED_URL_EXCEPTION,
    CDVCommandStatus_IO_EXCEPTION,
    CDVCommandStatus_INVALID_ACTION,
    CDVCommandStatus_JSON_EXCEPTION,
    CDVCommandStatus_ERROR
};

@interface CDVPluginResult : NSObject
@property (nonatomic) CDVCommandStatus status;
@property (nonatomic, strong) id message;

+ (instancetype)resultWithStatus:(CDVCommandStatus)status;
+ (instancetype)resultWithStatus:(CDVCommandStatus)status messageAsString:(NSString *)message;
+ (instancetype)resultWithStatus:(CDVCommandStatus)status messageAsArray:(NSArray *)message;
@end
