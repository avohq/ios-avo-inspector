//
//  AVOViewController.m
//  AvoStateOfTracking
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

#import "AVOViewController.h"

#import <AvoStateOfTracking/AvoList.h>
#import <AvoStateOfTracking/AvoInt.h>
#import <AvoStateOfTracking/AvoNull.h>
#import <AvoStateOfTracking/AvoStateOfTracking.h>

@interface AVOViewController ()

@end

@implementation AVOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    AvoList *avoList = [AvoList new];
    
    [[avoList subtypes] addObject: [AvoInt new]];
    [[avoList subtypes] addObject: [AvoNull new]];
    
    AvoStateOfTracking * avoSot = [AvoStateOfTracking new];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
