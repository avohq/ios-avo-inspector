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

SpecBegin(ListExtraction)

it(@"can extract array", ^{
    AvoStateOfTracking * sut = [AvoStateOfTracking new];
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
    
    NSArray * array = @[@"test", @42];
   
   [testParams setObject:array forKey:@"array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"array key"] class]).equal([AvoList class]);
});

it(@"can extract single object array", ^{
    AvoStateOfTracking * sut = [AvoStateOfTracking new];
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
    
    NSArray * array = @[@"test"];
   
   [testParams setObject:array forKey:@"array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"array key"] class]).equal([AvoList class]);
});

it(@"can extract single object set", ^{
    AvoStateOfTracking * sut = [AvoStateOfTracking new];
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
    
    NSSet * set = [[NSSet alloc] initWithArray:@[@""]];
   
   [testParams setObject:set forKey:@"set key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"set key"] class]).equal([AvoList class]);
});

it(@"can extract multiple objecta set", ^{
    AvoStateOfTracking * sut = [AvoStateOfTracking new];
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
    
    NSSet * set = [[NSSet alloc] initWithObjects:@"1", @42, nil];
   
   [testParams setObject:set forKey:@"set key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"set key"] class]).equal([AvoList class]);
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

it(@"can extract mutable single object array", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableArray * mutableArray = [NSMutableArray new];
   [mutableArray addObject:@"test"];
    
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

it(@"do not duplicate types in name", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableArray * mutableArray = [NSMutableArray new];
   [mutableArray addObject:@[@"Hello world"]];
   [mutableArray addObject:@[@"Give me a sign"]];
   
   [testParams setObject:mutableArray forKey:@"string array key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"string array key"] name]).equal(@"list(list(string))");
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
   
    NSString * propertyValue = [[extractedSchema objectForKey:@"string array key"] name];
   
    expect(propertyValue).to.startWith(@"list(");
    expect(propertyValue).to.contain(@"int");
    expect(propertyValue).to.contain(@"float");
    expect(propertyValue).to.contain(@"boolean");
    expect(propertyValue).to.contain(@"string");
    expect(propertyValue).to.contain(@"null");
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
