//
//  AvoSessionTracker.m
//  AvoInspector
//
//  Created by Alex Verein on 05.02.2020.
//

#import "AvoSessionTracker.h"

@interface AvoSessionTracker ()

@property (nonatomic) NSTimeInterval lastSessionTimestamp;
@property (readwrite, nonatomic) NSTimeInterval sessionLength;
@property (readwrite, nonatomic) AvoBatcher * avoBatcher;

@end

@implementation AvoSessionTracker

static NSString * sessionId;

-(instancetype) initWithBatcher: (AvoBatcher *) avoBatcher {
    self = [super init];
    if (self) {
        self.lastSessionTimestamp = [[NSUserDefaults standardUserDefaults] doubleForKey:[AvoSessionTracker timestampCacheKey]];
        sessionId = [[NSUserDefaults standardUserDefaults] stringForKey:[AvoSessionTracker idCacheKey]];
        if (self.lastSessionTimestamp == 0.0) {
            self.lastSessionTimestamp = INT_MIN;
        }
        if (sessionId == nil) {
            AvoSessionTracker.sessionId = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setValue:AvoSessionTracker.sessionId forKey:[AvoSessionTracker idCacheKey]];
        }
        self.avoBatcher = avoBatcher;
        self.sessionLength = 5 * 60;
   
    }
    return self;
}

- (void) startOrProlongSession: (NSNumber *) atUnixTime {
    
    NSTimeInterval timeSinceLastSession = [atUnixTime doubleValue] - self.lastSessionTimestamp;
    if (timeSinceLastSession > self.sessionLength) {
        AvoSessionTracker.sessionId = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setValue:AvoSessionTracker.sessionId forKey:[AvoSessionTracker idCacheKey]];
        [self.avoBatcher handleSessionStarted];
    }

    self.lastSessionTimestamp = [atUnixTime doubleValue];
    [[NSUserDefaults standardUserDefaults] setDouble:self.lastSessionTimestamp forKey:[AvoSessionTracker timestampCacheKey]];
}

+ (NSString*) sessionId
{
    return sessionId;
}

+ (void) setSessionId:(NSString *)newSessionId
{
    if(sessionId != newSessionId) {
        sessionId = [newSessionId copy];
    }
}

+ (NSString *) timestampCacheKey {
    return @"AvoInspectorSession";
}

+ (NSString *) idCacheKey {
    return @"AvoInspectorSessionId";
}

@end
