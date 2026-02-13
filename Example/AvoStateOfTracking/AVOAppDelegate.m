//
//  AVOAppDelegate.m
//  AvoInspector
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

#import "AVOAppDelegate.h"

// Local API key override (gitignored). Falls back to default if not present.
#if __has_include("LocalConfig.h")
#import "LocalConfig.h"
#endif

#ifndef AVO_INSPECTOR_API_KEY
#define AVO_INSPECTOR_API_KEY @"A4lTbBQTGVyD1f66213X"
#endif

@implementation AVOAppDelegate

AvoInspector * avoInspector;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    avoInspector = [[AvoInspector alloc] initWithApiKey:AVO_INSPECTOR_API_KEY env: AvoInspectorEnvDev publicEncryptionKey: @"024ec9c17ea2fb3e727d2815941eeb7d7c6e551536c9e2dde37fbbf0ffb9850579"]; // example key, decrypt with 2f6f681eb9b9ce4d72c40fc3c860e1b484fc9001ceb8de162c0086c1c8c619cf

    return YES;
}

+ (AvoInspector *)getAvoSot {
    return avoInspector;
}

@end
