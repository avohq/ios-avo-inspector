#import <Foundation/Foundation.h>

@protocol AvoStorage <NSObject>
- (BOOL)isInitialized;
- (NSString *)getItem:(NSString *)key;
- (void)setItem:(NSString *)key :(NSString *)value;
@end
