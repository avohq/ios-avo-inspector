#import "AvoGuid.h"

@implementation AvoGuid
+ (NSString *)newGuid {
    return [[NSUUID UUID] UUIDString];
}
@end
