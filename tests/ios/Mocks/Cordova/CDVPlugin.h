#import <Foundation/Foundation.h>

@protocol CDVCommandDelegate <NSObject>
- (void)sendPluginResult:(id)result callbackId:(NSString *)callbackId;
@end

@interface CDVPlugin : NSObject
@property (nonatomic, weak) id<CDVCommandDelegate> commandDelegate;
- (void)pluginInitialize;
@end
