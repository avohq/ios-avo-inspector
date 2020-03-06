//
//  AVOAppDelegate.h
//  AvoInspector
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

@import UIKit;

#import <AvoInspector/AvoInspector.h>

@interface AVOAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (AvoInspector *) getAvoSot;

@end
