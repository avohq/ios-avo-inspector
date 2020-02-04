//
//  AvoList.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 28.01.2020.
//

#import "AvoList.h"

@implementation AvoList

-(id) init {
     if (self = [super init])  {
       self.subtypes = [NSMutableArray new];
     }
     return self;
}

- (NSString *) name {
    NSString *listTypes = @"";
    
    BOOL first = YES;
    for (id subtype in [self subtypes]) {
        NSString *subtypeName = @"";
        
        if (!first) {
            subtypeName = @"|";
        }
        
        subtypeName = [subtypeName stringByAppendingString:[subtype name]];
        
        first = false;
        
        listTypes = [listTypes stringByAppendingString:subtypeName];
    }
    
    return [NSString stringWithFormat:@"list(%@)", listTypes];
}

@end
