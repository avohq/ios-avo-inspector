//
//  ListSchemaExtractionTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 01.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoStateOfTracking.h>
#import <AvoStateOfTracking/AvoList.h>
#import <AvoStateOfTracking/AvoInt.h>
#import <AvoStateOfTracking/AvoFloat.h>
#import <AvoStateOfTracking/AvoBoolean.h>
#import <AvoStateOfTracking/AvoNull.h>
#import <AvoStateOfTracking/AvoString.h>
//#import <AvoStateOfTracking/AvoUnknownType.h>

SpecBegin(ListExtractionSpecs)

it(@"can extract array", ^{
    AvoStateOfTracking * sut = [AvoStateOfTracking new];
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
    
    NSArray * array = @[@"test", @42];
   
   [testParams setObject:array forKey:@"array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"array key"] class]).equal([AvoList class]);
});

it(@"can extract mutable array", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableArray * mutableArray = [NSMutableArray new];
   [mutableArray addObject:@"test"];
   [mutableArray addObject:@42];
    
   [testParams setObject:mutableArray forKey:@"mutable array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"mutable array key"] class]).equal([AvoList class]);
});

it(@"can extract string subtype array", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableArray * mutableArray = [NSMutableArray new];
   [mutableArray addObject:@"Hello world"];
   
   [testParams setObject:mutableArray forKey:@"string array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"string array key"] name]).equal(@"list(string)");
});

it(@"can extract nullable string subtype array", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableArray * mutableArray = [NSMutableArray new];
   [mutableArray addObject:@"Hello world"];
   [mutableArray addObject:NSNull.null];
   
   [testParams setObject:mutableArray forKey:@"string array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"string array key"] name]).equal(@"list(string|null)");
});

it(@"can extract nullable string int float boolean subtype array", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableArray * mutableArray = [NSMutableArray new];
   [mutableArray addObject:@"Hello world"];
   [mutableArray addObject:NSNull.null];
    [mutableArray addObject:@42];
    [mutableArray addObject:@41.1f];
     [mutableArray addObject:@YES];
   
   [testParams setObject:mutableArray forKey:@"string array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"string array key"] name]).equal(@"list(string|null|int|float|boolean)");
});

it(@"can extract double subtype array", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableArray * mutableArray = [NSMutableArray new];
    [mutableArray addObject:@41.1];
   
   [testParams setObject:mutableArray forKey:@"string array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"string array key"] name]).equal(@"list(float)");
});

SpecEnd
