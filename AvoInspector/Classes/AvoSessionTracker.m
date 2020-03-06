//
//  AvoSessionTracker.m
//  AvoInspector
//
//  Created by Alex Verein on 05.02.2020.
//

#import "AvoSessionTracker.h"

@interface AvoSessionTracker ()

@property (nonatomic) NSTimeInterval lastSessionTimestamp;
@property (readonly, nonatomic) NSTimeInterval sessionLength;
@property (readonly, nonatomic) AvoBatcher * avoBatcher;

@end

@implementation AvoSessionTracker

-(instancetype) initWithBatcher: (AvoBatcher *) avoBatcher {
    self = [super init];
    if (self) {
        self.lastSessionTimestamp = [[NSUserDefaults standardUserDefaults] doubleForKey:[AvoSessionTracker cacheKey]];
        if (self.lastSessionTimestamp == 0.0) {
            self.lastSessionTimestamp = INT_MIN;
        }
        _avoBatcher = avoBatcher;
        _sessionLength = 5 * 60;
    }
    return self;
}

- (void) schemaTracked: (NSNumber *) atUnixTime {
    
    NSTimeInterval timeSinceLastSession = [atUnixTime doubleValue] - self.lastSessionTimestamp;
    if (timeSinceLastSession > self.sessionLength) {
        [self.avoBatcher handleSessionStarted];
    }
    
    self.lastSessionTimestamp = [atUnixTime doubleValue];
    [[NSUserDefaults standardUserDefaults] setDouble:self.lastSessionTimestamp forKey:[AvoSessionTracker cacheKey]];
}

+ (NSString *) cacheKey {
    return @"AvoInspectorSession";
}

@end
