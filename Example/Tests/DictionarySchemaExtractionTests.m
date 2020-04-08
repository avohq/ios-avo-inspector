//
//  DictionarySchemaExtractionTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 20.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoList.h>
#import <AvoInspector/AvoObject.h>
#import <AvoInspector/AvoInt.h>
#import <AvoInspector/AvoFloat.h>
#import <AvoInspector/AvoBoolean.h>
#import <AvoInspector/AvoNull.h>
#import <AvoInspector/AvoString.h>

SpecBegin(DictionaryExtraction)

it(@"can extract dictionary", ^{
    AvoInspector * sut = [AvoInspector new];
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
    
   NSDictionary * dict = @{@"field0": @"test", @"field1": @42};
   
   [testParams setObject:dict forKey:@"dict key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"dict key"] class]).equal([AvoObject class]);
});

it(@"can extract mutable dictionary", ^{
   AvoInspector * sut = [AvoInspector new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableDictionary * mutableDict = [NSMutableDictionary new];
   [mutableDict setValue:@"test" forKey:@"field0"];
   [mutableDict setValue:@42 forKey:@"field1"];
    
   [testParams setObject:mutableDict forKey:@"mutable dict key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"mutable dict key"] class]).equal([AvoObject class]);
});

it(@"can extract single entry dictionary", ^{
    AvoInspector * sut = [AvoInspector new];
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
    
   NSDictionary * dict = @{@"field0": @"test"};
   
   [testParams setObject:dict forKey:@"dict key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"dict key"] class]).equal([AvoObject class]);
});

it(@"can extract single entry mutable dictionary", ^{
   AvoInspector * sut = [AvoInspector new];
   
   NSMutableDictionary * testParams = [NSMutableDictionary new];
   
   NSMutableDictionary * mutableDict = [NSMutableDictionary new];
   [mutableDict setValue:@"test" forKey:@"field0"];
    
   [testParams setObject:mutableDict forKey:@"mutable dict key"];
   
   NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
   expect([[extractedSchema objectForKey:@"mutable dict key"] class]).equal([AvoObject class]);
});

it(@"can extract nullable string int float boolean list(string) object{field0:string, filed1:int, filed3:list(null)} subtype array", ^{
    AvoInspector * sut = [AvoInspector new];
   
    NSMutableDictionary * testParams = [NSMutableDictionary new];
   
    NSMutableDictionary * mutableDict = [NSMutableDictionary new];
    [mutableDict setValue:@"Hello world" forKey:@"strKey"];
    [mutableDict setValue:NSNull.null forKey:@"nullStrKey"];
    [mutableDict setValue:@42 forKey:@"intKey"];
    [mutableDict setValue:@42.0 forKey:@"floatKey"];
    [mutableDict setValue:@YES forKey:@"boolKey"];
    [mutableDict setValue:@[@"test str"] forKey:@"listKey"];
    [mutableDict setValue:@{@"field0" : @"some string", @"filed1" : @-1, @"filed3" : @[NSNull.null]} forKey:@"nestedObjKey"];
   
    [testParams setObject:mutableDict forKey:@"complex object key"];
   
    NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
    expect([[extractedSchema objectForKey:@"complex object key"] name])
   .to.equal( @"{\"strKey\":\"string\",\"intKey\":\"int\",\"nullStrKey\":\"null\",\"nestedObjKey\":{\"field0\":\"string\",\"filed1\":\"int\",\"filed3\":\"list(null)\"},\"listKey\":\"list(string)\",\"boolKey\":\"boolean\",\"floatKey\":\"float\"}");
});

it(@"can extract list with double nested objects", ^{
    AvoInspector * sut = [AvoInspector new];
   
    NSMutableDictionary * testParams = [NSMutableDictionary new];
   
    NSMutableArray * arrayWithDoubleNestedObj = [NSMutableArray new];
    [arrayWithDoubleNestedObj addObject:@{@"int": @10}];
    [arrayWithDoubleNestedObj addObject:@{@"obj": @{@"nested": @{@"nested int":@1, @"nested bool":@YES}}}];
   
    [testParams setObject:arrayWithDoubleNestedObj forKey:@"2nested array"];
   
    NSDictionary * extractedSchema = [sut extractSchema:testParams];
   
    expect([[extractedSchema objectForKey:@"2nested array"] name])
   .to.equal( @"list({\"int\":\"int\"}|{\"obj\":{\"nested\":{\"nested int\":\"int\",\"nested bool\":\"boolean\"}}})");
});

SpecEnd
