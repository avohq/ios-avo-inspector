//
//  AvoInspector.h
//  AvoInspector
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>
#import "Inspector.h"
#import "AvoStorage.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, AvoInspectorEnv) {
    AvoInspectorEnvProd = 0,
    AvoInspectorEnvDev = 1,
    AvoInspectorEnvStaging = 2
};

@interface AvoInspector : NSObject <Inspector>

@property (readonly, nonatomic) NSString * appVersion;
@property (readonly, nonatomic) NSString * libVersion;

@property (readonly, nonatomic) NSString * apiKey;

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env;

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env proxyEndpoint: (NSString *) proxyEndpoint;

+ (id<AvoStorage>)avoStorage;

@end

NS_ASSUME_NONNULL_END
