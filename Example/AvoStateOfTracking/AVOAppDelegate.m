//
//  AVOAppDelegate.m
//  AvoInspector
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

#import "AVOAppDelegate.h"

@implementation AVOAppDelegate

AvoInspector * avoInspector;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    avoInspector = [[AvoInspector alloc] initWithApiKey:@"A4lTbBQTGVyD1f66213X" env: AvoInspectorEnvDev];
    
    return YES;
}

+ (AvoInspector *)getAvoSot {
    return avoInspector;
}

@end
