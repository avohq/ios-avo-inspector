//
//  AvoEventSpecFetcherTests.m
//  AvoStateOfTracking_Tests
//

#import <AvoInspector/AvoEventSpecFetcher.h>
#import <AvoInspector/AvoEventSpecFetchTypes.h>
#import <AvoInspector/AvoInspector.h>

@interface AvoEventSpecFetcher ()
@property (nonatomic, copy, readonly) NSString *baseUrl;
@property (nonatomic, assign, readonly) NSTimeInterval timeout;
@property (nonatomic, copy, readonly) NSString *env;
- (NSString *)buildUrl:(AvoFetchEventSpecParams *)params;
- (BOOL)hasExpectedShape:(AvoEventSpecResponseWire *)response;
@end

SpecBegin(EventSpecFetcher)

describe(@"AvoEventSpecFetcher", ^{

    it(@"initializes with default baseUrl", ^{
        AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:5.0 env:@"dev"];
        expect(fetcher.baseUrl).to.equal(@"https://api.avo.app");
        expect(fetcher.timeout).to.equal(5.0);
        expect(fetcher.env).to.equal(@"dev");
    });

    it(@"initializes with custom baseUrl", ^{
        AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:3.0 env:@"staging" baseUrl:@"https://custom.api.com"];
        expect(fetcher.baseUrl).to.equal(@"https://custom.api.com");
    });

    it(@"builds correct URL", ^{
        AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:5.0 env:@"dev"];
        AvoFetchEventSpecParams *params = [[AvoFetchEventSpecParams alloc] initWithApiKey:@"testKey" streamId:@"stream1" eventName:@"Test Event"];

        NSString *url = [fetcher buildUrl:params];
        expect(url).to.contain(@"https://api.avo.app/trackingPlan/eventSpec");
        expect(url).to.contain(@"apiKey=testKey");
        expect(url).to.contain(@"streamId=stream1");
        expect(url).to.contain(@"eventName=Test%20Event");
    });

    it(@"escapes reserved query delimiters in parameter values", ^{
        AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:5.0 env:@"dev"];
        AvoFetchEventSpecParams *params = [[AvoFetchEventSpecParams alloc] initWithApiKey:@"k&=y" streamId:@"s&t=r" eventName:@"Foo&Bar=Baz"];

        NSString *url = [fetcher buildUrl:params];
        expect(url).to.contain(@"apiKey=k%26%3Dy");
        expect(url).to.contain(@"streamId=s%26t%3Dr");
        expect(url).to.contain(@"eventName=Foo%26Bar%3DBaz");
    });

    describe(@"Environment gating", ^{
        it(@"returns nil for prod env via callback", ^{
            AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:5.0 env:@"prod"];
            AvoFetchEventSpecParams *params = [[AvoFetchEventSpecParams alloc] initWithApiKey:@"key" streamId:@"stream" eventName:@"event"];

            __block AvoEventSpecResponse *callbackResponse = (id)@"sentinel";
            __block BOOL callbackCalled = NO;

            [fetcher fetchEventSpec:params completion:^(AvoEventSpecResponse * _Nullable response) {
                callbackResponse = response;
                callbackCalled = YES;
            }];

            // Should call back immediately with nil since env is "prod"
            expect(callbackCalled).to.beTruthy();
            expect(callbackResponse).to.beNil();
        });
    });

    describe(@"hasExpectedShape", ^{
        it(@"returns YES for valid response", ^{
            AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:5.0 env:@"dev"];

            NSDictionary *responseDict = @{
                @"events": @[],
                @"metadata": @{
                    @"schemaId": @"schema1",
                    @"branchId": @"branch1",
                    @"latestActionId": @"action1"
                }
            };
            AvoEventSpecResponseWire *wire = [[AvoEventSpecResponseWire alloc] initWithDictionary:responseDict];

            expect([fetcher hasExpectedShape:wire]).to.beTruthy();
        });

        it(@"returns NO when metadata is missing", ^{
            AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:5.0 env:@"dev"];

            NSDictionary *responseDict = @{@"events": @[]};
            AvoEventSpecResponseWire *wire = [[AvoEventSpecResponseWire alloc] initWithDictionary:responseDict];

            expect([fetcher hasExpectedShape:wire]).to.beFalsy();
        });

        it(@"returns NO when schemaId is empty", ^{
            AvoEventSpecFetcher *fetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:5.0 env:@"dev"];

            NSDictionary *responseDict = @{
                @"events": @[],
                @"metadata": @{
                    @"schemaId": @"",
                    @"branchId": @"branch1",
                    @"latestActionId": @"action1"
                }
            };
            AvoEventSpecResponseWire *wire = [[AvoEventSpecResponseWire alloc] initWithDictionary:responseDict];

            expect([fetcher hasExpectedShape:wire]).to.beFalsy();
        });
    });
});

describe(@"AvoEventSpecFetchTypes wire parsing", ^{

    it(@"parses AvoPropertyConstraintsWire from dictionary", ^{
        NSDictionary *dict = @{
            @"t": @"string",
            @"r": @YES,
            @"p": @{@"hello": @[@"evt1", @"evt2"]},
            @"v": @{@"[\"a\",\"b\"]": @[@"evt1"]}
        };
        AvoPropertyConstraintsWire *wire = [[AvoPropertyConstraintsWire alloc] initWithDictionary:dict];
        expect(wire.t).to.equal(@"string");
        expect(wire.r).to.beTruthy();
        expect(wire.p[@"hello"]).to.contain(@"evt1");
        expect(wire.v[@"[\"a\",\"b\"]"]).to.contain(@"evt1");
    });

    it(@"parses AvoEventSpecEntryWire from dictionary", ^{
        NSDictionary *dict = @{
            @"b": @"branch1",
            @"id": @"event1",
            @"vids": @[@"var1", @"var2"],
            @"p": @{
                @"prop1": @{@"t": @"string", @"r": @NO}
            }
        };
        AvoEventSpecEntryWire *wire = [[AvoEventSpecEntryWire alloc] initWithDictionary:dict];
        expect(wire.b).to.equal(@"branch1");
        expect(wire.eventId).to.equal(@"event1");
        expect(wire.vids.count).to.equal(2);
        expect(wire.p[@"prop1"]).toNot.beNil();
        expect(wire.p[@"prop1"].t).to.equal(@"string");
    });

    it(@"parses full wire response and converts to internal", ^{
        NSDictionary *responseDict = @{
            @"events": @[
                @{
                    @"b": @"branch1",
                    @"id": @"event1",
                    @"vids": @[@"var1"],
                    @"p": @{
                        @"name": @{@"t": @"string", @"r": @YES, @"p": @{@"John": @[@"event1"]}}
                    }
                }
            ],
            @"metadata": @{
                @"schemaId": @"schema1",
                @"branchId": @"branch1",
                @"latestActionId": @"action1",
                @"sourceId": @"source1"
            }
        };

        AvoEventSpecResponseWire *wire = [[AvoEventSpecResponseWire alloc] initWithDictionary:responseDict];
        expect(wire.events.count).to.equal(1);
        expect(wire.metadata.schemaId).to.equal(@"schema1");
        expect(wire.metadata.sourceId).to.equal(@"source1");

        AvoEventSpecResponse *internal = [[AvoEventSpecResponse alloc] initFromWire:wire];
        expect(internal.events.count).to.equal(1);
        expect(internal.events[0].branchId).to.equal(@"branch1");
        expect(internal.events[0].baseEventId).to.equal(@"event1");
        expect(internal.events[0].variantIds).to.contain(@"var1");
        expect(internal.events[0].props[@"name"]).toNot.beNil();
        expect(internal.events[0].props[@"name"].type).to.equal(@"string");
        expect(internal.events[0].props[@"name"].required).to.beTruthy();
        expect(internal.events[0].props[@"name"].pinnedValues[@"John"]).to.contain(@"event1");
    });

    it(@"parses nested children constraints", ^{
        NSDictionary *dict = @{
            @"t": @"object",
            @"r": @NO,
            @"children": @{
                @"child1": @{@"t": @"string", @"r": @YES},
                @"child2": @{@"t": @"int", @"r": @NO}
            }
        };
        AvoPropertyConstraintsWire *wire = [[AvoPropertyConstraintsWire alloc] initWithDictionary:dict];
        expect(wire.children).toNot.beNil();
        expect(wire.children[@"child1"].t).to.equal(@"string");
        expect(wire.children[@"child2"].t).to.equal(@"int");
    });
});

SpecEnd
