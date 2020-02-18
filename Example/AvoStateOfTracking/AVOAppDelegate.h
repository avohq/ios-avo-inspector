//
//  AVOAppDelegate.h
//  AvoStateOfTracking
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

@import UIKit;

#import <AvoStateOfTracking/AvoStateOfTracking.h>

@interface AVOAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (AvoStateOfTracking *) getAvoSot;

@end
