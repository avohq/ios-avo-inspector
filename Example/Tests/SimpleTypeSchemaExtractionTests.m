//
//  AvoStateOfTrackingTests.m
//  AvoStateOfTrackingTests
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

// https://github.com/Specta/Specta

#import <AvoStateOfTracking/AvoStateOfTracking.h>
#import <AvoStateOfTracking/AvoInt.h>
#import <AvoStateOfTracking/AvoFloat.h>
#import <AvoStateOfTracking/AvoBoolean.h>
#import <AvoStateOfTracking/AvoNull.h>
#import <AvoStateOfTracking/AvoString.h>
//#import <AvoStateOfTracking/AvoUnknownType.h>

SpecBegin(PrimitiveTypeExtractionSpecs)

describe(@"testing primitive type extraction", ^{
    it(@"can extract int", ^{
        AvoStateOfTracking * sut = [AvoStateOfTracking new];
         
        NSMutableDictionary * testParams = [NSMutableDictionary new];
        
        [testParams setObject:@1 forKey:@"int key"];
        
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
        
        expect([extractedSchema objectForKey:@"int key"]).equal([AvoInt new]);
    });
         
     it(@"can extract double", ^{
        AvoStateOfTracking * sut = [AvoStateOfTracking new];
          
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@1.4 forKey:@"double key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"double key"]).equal([AvoFloat new]);
     });
         
     it(@"can extract float", ^{
        AvoStateOfTracking * sut = [AvoStateOfTracking new];
          
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@1.4f forKey:@"float key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"float key"]).equal([AvoFloat new]);
     });
         
     it(@"can extract boolean", ^{
        AvoStateOfTracking * sut = [AvoStateOfTracking new];
          
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@YES forKey:@"boolean key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"boolean key"]).equal([AvoBoolean new]);
     });
         
     it(@"can extract null", ^{
        AvoStateOfTracking * sut = [AvoStateOfTracking new];
          
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:[NSNull null] forKey:@"null key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"null key"]).equal([AvoNull new]);
     });
         
     it(@"can extract constant string", ^{
        AvoStateOfTracking * sut = [AvoStateOfTracking new];
          
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@"String" forKey:@"const string key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"const string key"]).equal([AvoString new]);
     });
});

SpecEnd

