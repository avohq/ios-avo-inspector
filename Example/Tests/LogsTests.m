//
//  LogsTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 03.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoStateOfTracking.h>

SpecBegin(LoggingSpecs)

it(@"logs event parameters", ^{
   
    AvoStateOfTracking * sut = [AvoStateOfTracking new];
    
    sut.isLogging = YES;
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
     
     NSArray * array = @[@"test", @42];
    
    [testParams setObject:array forKey:@"array key"];
    [testParams setObject:@42 forKey:@"int key"];
    
    [sut trackSchemaFromEvent:@"Test Event" eventParams:testParams];
});

SpecEnd

