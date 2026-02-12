#import <Foundation/Foundation.h>

@interface CDVInvokedUrlCommand : NSObject
@property (nonatomic, strong) NSString *callbackId;
@property (nonatomic, strong) NSArray *arguments;

+ (instancetype)commandWithCallbackId:(NSString *)callbackId arguments:(NSArray *)arguments;
@end
