//
//  AvoStateOfTracking.h
//  AvoStateOfTracking
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>
#import "StateOfTracking.h"
#import "AvoSessionTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoStateOfTracking : NSObject <StateOfTracking>

@property (readonly, nonatomic) AvoSessionTracker * sessionTracker;

@property (readonly, nonatomic) NSString * appVersion;
@property (readonly, nonatomic) NSInteger libVersion;

@property (readonly, nonatomic) NSString *apiKey;

-(instancetype) initWithApiKey: (NSString *) apiKey isDev: (Boolean) isDev;

@end

NS_ASSUME_NONNULL_END
