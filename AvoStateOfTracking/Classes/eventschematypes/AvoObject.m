//
//  AvoObject.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 20.02.2020.
//

#import "AvoObject.h"

@implementation AvoObject

-(id) init {
     if (self = [super init])  {
       self.fields = [NSMutableDictionary new];
     }
     return self;
}

- (NSString *) name {
    NSString *objectSchema = @"{";
    
    for (NSString * fieldKey in [self.fields allKeys]) {
        objectSchema = [objectSchema stringByAppendingString:[NSString stringWithFormat:@"\"%@\"", fieldKey]];
        objectSchema = [objectSchema stringByAppendingString:@":"];
        objectSchema = [objectSchema stringByAppendingString:[NSString stringWithFormat:@"\"%@\",", [[self.fields valueForKey:fieldKey] name]]];
    }
    objectSchema = [objectSchema stringByAppendingString:@"}"];
    
    return [NSString stringWithFormat:@"%@", objectSchema];
}

@end
