//
//  Utils.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 06.02.2020.
//

#import "Utils.h"

@implementation Utils

+ (NSString *) currentTimeAsISO8601UTCString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    return [formatter stringFromDate:[NSDate date]];
}

@end
