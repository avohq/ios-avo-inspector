//
//  AvoStateOfTrackingTests.m
//  AvoStateOfTrackingTests
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

// https://github.com/Specta/Specta

#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoInt.h>
#import <AvoInspector/AvoFloat.h>
#import <AvoInspector/AvoBoolean.h>
#import <AvoInspector/AvoNull.h>
#import <AvoInspector/AvoString.h>

SpecBegin(PrimitiveTypeExtraction)

__block AvoInspector * sut;

describe(@"testing primitive type extraction", ^{
    beforeAll(^{
        sut = [[AvoInspector alloc] initWithApiKey:@"api key" env:AvoInspectorEnvDev];
    });
    
    it(@"can extract int", ^{
         
        NSMutableDictionary * testParams = [NSMutableDictionary new];
        
        [testParams setObject:@1 forKey:@"int key"];
        
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
        
        expect([extractedSchema objectForKey:@"int key"]).equal([AvoInt new]);
    });
         
     it(@"can extract long long", ^{
         NSMutableDictionary * testParams = [NSMutableDictionary new];
         
         long long int longlon = 16;
    
         [testParams setObject:@(longlon) forKey:@"longlong key"];
         
         NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
         expect([extractedSchema objectForKey:@"longlong key"]).equal([AvoInt new]);
     });
         
     it(@"can extract long", ^{
          NSMutableDictionary * testParams = [NSMutableDictionary new];
          
          long int lon = 16;
     
          [testParams setObject:@(lon) forKey:@"long key"];
          
          NSDictionary * extractedSchema = [sut extractSchema:testParams];
          
          expect([extractedSchema objectForKey:@"long key"]).equal([AvoInt new]);
      });
     
     it(@"can extract short", ^{
             NSMutableDictionary * testParams = [NSMutableDictionary new];
             
             short int shor = 16;
        
             [testParams setObject:@(shor) forKey:@"short key"];
             
             NSDictionary * extractedSchema = [sut extractSchema:testParams];
             
             expect([extractedSchema objectForKey:@"short key"]).equal([AvoInt new]);
         });
         
     it(@"can extract char", ^{
         NSMutableDictionary * testParams = [NSMutableDictionary new];
         
         char ch = 'c';
    
         [testParams setObject:@(ch) forKey:@"char key"];
         
         NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
         expect([extractedSchema objectForKey:@"char key"]).equal([AvoString new]);
     });
         
     it(@"can extract double", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@1.4 forKey:@"double key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"double key"]).equal([AvoFloat new]);
     });
         
     it(@"can extract float", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@1.4f forKey:@"float key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"float key"]).equal([AvoFloat new]);
     });
         
     it(@"can extract boolean", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@YES forKey:@"boolean key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"boolean key"]).equal([AvoBoolean new]);
     });
         
     it(@"can extract null", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:[NSNull null] forKey:@"null key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"null key"]).equal([AvoNull new]);
     });
         
     it(@"can extract constant string", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
         
        [testParams setObject:@"String" forKey:@"const string key"];
         
        NSDictionary * extractedSchema = [sut extractSchema:testParams];
         
        expect([extractedSchema objectForKey:@"const string key"]).equal([AvoString new]);
     });
});

SpecEnd

