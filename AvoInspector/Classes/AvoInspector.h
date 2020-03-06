//
//  AvoInspector.h
//  AvoInspector
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>
#import "Inspector.h"
#import "AvoSessionTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoInspector : NSObject <Inspector>

@property (readonly, nonatomic) AvoSessionTracker * sessionTracker;

@property (readonly, nonatomic) NSString * appVersion;
@property (readonly, nonatomic) NSString * libVersion;

@property (readonly, nonatomic) NSString * apiKey;

-(instancetype) initWithApiKey: (NSString *) apiKey isDev: (Boolean) isDev;

@end

NS_ASSUME_NONNULL_END
