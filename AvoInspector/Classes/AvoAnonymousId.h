#import <Foundation/Foundation.h>

@interface AvoAnonymousId : NSObject
+ (NSString *)anonymousId;
+ (void)setAnonymousId:(NSString *)_id;
+ (void)clearCache;
@end
