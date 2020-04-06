//
//  AvoSessionTracker.h
//  AvoInspector
//
//  Created by Alex Verein on 05.02.2020.
//

#import <Foundation/Foundation.h>
#import "AvoBatcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoSessionTracker : NSObject

@property (class, nonatomic) NSString *sessionId;

-(instancetype) initWithBatcher: (AvoBatcher *) avoBatcher;

- (void) startOrProlongSession: (NSNumber *) atUnixTime;

+ (NSString *) timestampCacheKey;
+ (NSString *) idCacheKey;

@end

NS_ASSUME_NONNULL_END
