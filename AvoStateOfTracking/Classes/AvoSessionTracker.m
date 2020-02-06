//
//  AvoSessionTracker.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 05.02.2020.
//

#import "AvoSessionTracker.h"

@interface AvoSessionTracker ()

@property (nonatomic) NSTimeInterval lastSessionTimestamp;
@property (readonly, nonatomic) NSTimeInterval sessionLength;

@end

@implementation AvoSessionTracker

-(instancetype) init {
    self = [super init];
    if (self) {
        self.lastSessionTimestamp = [[NSUserDefaults standardUserDefaults] doubleForKey:[AvoSessionTracker cacheKey]];
        if (self.lastSessionTimestamp == 0.0) {
            self.lastSessionTimestamp = INT_MIN;
        }
        _sessionLength = 20 * 60 * 1000;
    }
    return self;
}

- (void) schemaTracked: (NSNumber *) atUnixTime {
    
    NSTimeInterval inSession = [atUnixTime doubleValue] - self.sessionLength;
    if (self.lastSessionTimestamp < inSession) {
        [self callSessionStarted];
    }
    
    self.lastSessionTimestamp = [atUnixTime doubleValue];
    [[NSUserDefaults standardUserDefaults] setDouble:self.lastSessionTimestamp forKey:[AvoSessionTracker cacheKey]];
}

- (void) callSessionStarted {
        
}

+ (NSString *) cacheKey {
    return @"AvoStateOfTrackingSession";
}

@end
