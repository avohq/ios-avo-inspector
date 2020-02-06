//
//  AvoInstallationId.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 06.02.2020.
//

#import "AvoInstallationId.h"

@interface AvoInstallationId ()

@property (nonatomic) NSString * installationId;

@end

@implementation AvoInstallationId

- (NSString *) getInstallationId {
    if (self.installationId == nil) {
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        self.installationId = [userDefaults stringForKey:[AvoInstallationId cacheKey]];
        if (self.installationId == nil) {
            self.installationId = [[NSUUID UUID] UUIDString];;
            [userDefaults setObject:self.installationId forKey:[AvoInstallationId cacheKey]];
        }
    }
    return self.installationId;
}

+ (NSString *) cacheKey {
    return @"AvoInstallationId";
}

@end
