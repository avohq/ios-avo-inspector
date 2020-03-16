//
//  VisualDebuggerTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 13.03.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoInspector/Inspector.h>
#import <AvoInspector/AvoInspector.h>
#import <OCMock/OCMock.h>
#import <AnalyticsDebugger.h>

@interface AvoInspector ()

@property (readwrite, nonatomic) AnalyticsDebugger * debugger;

@end

SpecBegin(VisualDebugger)

it(@"Shows bar visual inspector", ^{
   
    AvoInspector * sut = [AvoInspector new];
   
    sut.debugger = OCMClassMock([AnalyticsDebugger class]);
   
    [sut showVisualInspector:Bar];
    
    OCMVerify([sut.debugger showBarDebugger]);
});

it(@"Shows bubble visual inspector", ^{
   
    AvoInspector * sut = [AvoInspector new];
   
    sut.debugger = OCMClassMock([AnalyticsDebugger class]);
   
    [sut showVisualInspector:Bubble];
    
    OCMVerify([sut.debugger showBubbleDebugger]);
});

it(@"Hides visual inspector", ^{
   
    AvoInspector * sut = [AvoInspector new];
   
    sut.debugger = OCMClassMock([AnalyticsDebugger class]);
   
    [sut hideVisualInspector];
    
    OCMVerify([sut.debugger hideDebugger]);
});

SpecEnd
