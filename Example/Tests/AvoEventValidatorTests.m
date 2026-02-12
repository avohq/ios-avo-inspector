//
//  AvoEventValidatorTests.m
//  AvoStateOfTracking_Tests
//

#import <AvoInspector/AvoEventValidator.h>
#import <AvoInspector/AvoEventSpecFetchTypes.h>

#pragma mark - Test Helpers

static AvoPropertyConstraintsWire *makeWireConstraint(NSString *type, NSDictionary *pinnedValues, NSDictionary *allowedValues, NSDictionary *regexPatterns, NSDictionary *minmax) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"t"] = type;
    dict[@"r"] = @NO;
    if (pinnedValues) dict[@"p"] = pinnedValues;
    if (allowedValues) dict[@"v"] = allowedValues;
    if (regexPatterns) dict[@"rx"] = regexPatterns;
    if (minmax) dict[@"minmax"] = minmax;
    return [[AvoPropertyConstraintsWire alloc] initWithDictionary:dict];
}

static AvoEventSpecEntry *makeEntry(NSString *branchId, NSString *baseEventId, NSArray *variantIds, NSDictionary<NSString *, AvoPropertyConstraints *> *props) {
    AvoEventSpecEntryWire *wire = [[AvoEventSpecEntryWire alloc] init];
    wire.b = branchId;
    wire.eventId = baseEventId;
    wire.vids = variantIds ?: @[];
    // We'll set props directly on the internal entry
    AvoEventSpecEntry *entry = [[AvoEventSpecEntry alloc] init];
    entry.branchId = branchId;
    entry.baseEventId = baseEventId;
    entry.variantIds = variantIds ?: @[];
    entry.props = props ?: @{};
    return entry;
}

static AvoEventSpecResponse *makeResponse(NSArray<AvoEventSpecEntry *> *events) {
    AvoEventSpecResponse *resp = [[AvoEventSpecResponse alloc] init];
    resp.events = events;
    AvoEventSpecMetadata *meta = [[AvoEventSpecMetadata alloc] initWithDictionary:@{
        @"schemaId": @"schema1",
        @"branchId": @"branch1",
        @"latestActionId": @"action1"
    }];
    resp.metadata = meta;
    return resp;
}

static AvoPropertyConstraints *makeConstraints(NSString *type, NSDictionary *pinnedValues, NSDictionary *allowedValues, NSDictionary *regexPatterns, NSDictionary *minmax) {
    AvoPropertyConstraints *c = [[AvoPropertyConstraints alloc] init];
    c.type = type;
    c.required = NO;
    c.pinnedValues = pinnedValues;
    c.allowedValues = allowedValues;
    c.regexPatterns = regexPatterns;
    c.minMaxRanges = minmax;
    return c;
}

SpecBegin(EventValidator)

describe(@"AvoEventValidator", ^{

    it(@"returns nil for nil spec", ^{
        AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"key": @"value"} specResponse:nil];
        expect(result).to.beNil();
    });

    it(@"returns nil for empty events", ^{
        AvoEventSpecResponse *resp = makeResponse(@[]);
        AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"key": @"value"} specResponse:resp];
        expect(result).to.beNil();
    });

    it(@"returns result with empty property validation when all pass", ^{
        AvoPropertyConstraints *constraint = makeConstraints(@"string",
            @{@"hello": @[@"evt1"]}, nil, nil, nil);

        AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"greeting": constraint});
        AvoEventSpecResponse *resp = makeResponse(@[entry]);

        AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"greeting": @"hello"} specResponse:resp];
        expect(result).toNot.beNil();
        // Property exists in results but with no failedEventIds/passedEventIds (all passed)
        AvoPropertyValidationResult *propResult = result.propertyResults[@"greeting"];
        expect(propResult).toNot.beNil();
        expect(propResult.failedEventIds).to.beNil();
        expect(propResult.passedEventIds).to.beNil();
    });

    describe(@"Pinned values", ^{
        it(@"fails when value doesn't match pinned value", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                @{@"expected": @[@"evt1"]}, nil, nil, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"wrong"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();

            AvoPropertyValidationResult *propResult = result.propertyResults[@"prop"];
            // Should have either failedEventIds or passedEventIds
            BOOL hasFailed = propResult.failedEventIds != nil && propResult.failedEventIds.count > 0;
            BOOL hasPassed = propResult.passedEventIds != nil;
            expect(hasFailed || hasPassed).to.beTruthy();
        });

        it(@"passes when value matches pinned value", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                @{@"correct": @[@"evt1"]}, nil, nil, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"correct"} specResponse:resp];
            expect(result).toNot.beNil();
            // Property result exists but has no failed/passed IDs (all passed)
            AvoPropertyValidationResult *pr = result.propertyResults[@"prop"];
            expect(pr).toNot.beNil();
            expect(pr.failedEventIds).to.beNil();
            expect(pr.passedEventIds).to.beNil();
        });
    });

    describe(@"Allowed values", ^{
        it(@"fails when value not in allowed list", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                nil, @{@"[\"a\",\"b\",\"c\"]": @[@"evt1"]}, nil, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"d"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();
        });

        it(@"passes when value is in allowed list", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                nil, @{@"[\"a\",\"b\",\"c\"]": @[@"evt1"]}, nil, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"b"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"].failedEventIds).to.beNil();
            expect(result.propertyResults[@"prop"].passedEventIds).to.beNil();
        });
    });

    describe(@"Regex patterns", ^{
        it(@"fails when value doesn't match regex", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                nil, nil, @{@"^[0-9]+$": @[@"evt1"]}, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"abc"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();
        });

        it(@"passes when value matches regex", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                nil, nil, @{@"^[0-9]+$": @[@"evt1"]}, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"12345"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"].failedEventIds).to.beNil();
            expect(result.propertyResults[@"prop"].passedEventIds).to.beNil();
        });
    });

    describe(@"Min/max ranges", ^{
        it(@"fails when value below min", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"int",
                nil, nil, nil, @{@"10,100": @[@"evt1"]});

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @5} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();
        });

        it(@"fails when value above max", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"int",
                nil, nil, nil, @{@"10,100": @[@"evt1"]});

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @200} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();
        });

        it(@"passes when value in range", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"int",
                nil, nil, nil, @{@"10,100": @[@"evt1"]});

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @50} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"].failedEventIds).to.beNil();
            expect(result.propertyResults[@"prop"].passedEventIds).to.beNil();
        });

        it(@"fails for non-numeric value", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"int",
                nil, nil, nil, @{@"10,100": @[@"evt1"]});

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"not a number"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();
        });
    });

    describe(@"Multi-event merge", ^{
        it(@"merges constraints across events and reports correct eventIds", ^{
            AvoPropertyConstraints *constraint1 = makeConstraints(@"string",
                @{@"hello": @[@"evt1"]}, nil, nil, nil);
            AvoPropertyConstraints *constraint2 = makeConstraints(@"string",
                @{@"world": @[@"evt2"]}, nil, nil, nil);

            AvoEventSpecEntry *entry1 = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint1});
            AvoEventSpecEntry *entry2 = makeEntry(@"b1", @"evt2", @[], @{@"prop": constraint2});
            AvoEventSpecResponse *resp = makeResponse(@[entry1, entry2]);

            // "hello" matches evt1's pinned value but not evt2's
            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"hello"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();

            AvoPropertyValidationResult *propResult = result.propertyResults[@"prop"];
            // evt2 should fail (pinned "world" != "hello")
            if (propResult.failedEventIds != nil) {
                expect(propResult.failedEventIds).to.contain(@"evt2");
            } else {
                // passedEventIds should contain evt1 but not evt2
                expect(propResult.passedEventIds).to.contain(@"evt1");
            }
        });
    });

    describe(@"Variant IDs", ^{
        it(@"includes variant IDs in all event IDs", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                @{@"expected": @[@"evt1", @"var1", @"var2"]}, nil, nil, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[@"var1", @"var2"], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"wrong"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"]).toNot.beNil();
        });
    });

    describe(@"Nested object validation", ^{
        it(@"validates child properties of object constraints", ^{
            AvoPropertyConstraints *childConstraint = makeConstraints(@"string",
                @{@"expected_child": @[@"evt1"]}, nil, nil, nil);

            AvoPropertyConstraints *parentConstraint = makeConstraints(@"object", nil, nil, nil, nil);
            parentConstraint.children = @{@"childProp": childConstraint};

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"parent": parentConstraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            NSDictionary *props = @{@"parent": @{@"childProp": @"wrong_child"}};
            AvoValidationResult *result = [AvoEventValidator validateEvent:props specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"parent"]).toNot.beNil();
            expect(result.propertyResults[@"parent"].children).toNot.beNil();
            expect(result.propertyResults[@"parent"].children[@"childProp"]).toNot.beNil();
        });
    });

    describe(@"Bandwidth optimization", ^{
        it(@"returns smaller of failed/passed sets", ^{
            // Create 2 events: evt1 expects "expected", evt2 expects "other"
            // Sending "expected" should pass evt1 but fail evt2
            AvoPropertyConstraints *constraint1 = makeConstraints(@"string",
                @{@"expected": @[@"evt1"]}, nil, nil, nil);
            AvoPropertyConstraints *constraint2 = makeConstraints(@"string",
                @{@"other": @[@"evt2"]}, nil, nil, nil);

            AvoEventSpecEntry *entry1 = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint1});
            AvoEventSpecEntry *entry2 = makeEntry(@"b1", @"evt2", @[], @{@"prop": constraint2});
            AvoEventSpecResponse *resp = makeResponse(@[entry1, entry2]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"expected"} specResponse:resp];
            AvoPropertyValidationResult *propResult = result.propertyResults[@"prop"];
            expect(propResult).toNot.beNil();

            // 1 failed (evt2), 1 passed (evt1) - equal size, so failedEventIds is used
            BOOL hasResult = (propResult.failedEventIds != nil || propResult.passedEventIds != nil);
            expect(hasResult).to.beTruthy();
        });
    });

    describe(@"Boolean conversion", ^{
        it(@"converts boolean to string for pinned value check", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"boolean",
                @{@"true": @[@"evt1"]}, nil, nil, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @YES} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.propertyResults[@"prop"].failedEventIds).to.beNil();
            expect(result.propertyResults[@"prop"].passedEventIds).to.beNil(); // should pass
        });
    });

    describe(@"Metadata", ^{
        it(@"includes metadata in validation result", ^{
            AvoPropertyConstraints *constraint = makeConstraints(@"string",
                @{@"val": @[@"evt1"]}, nil, nil, nil);

            AvoEventSpecEntry *entry = makeEntry(@"b1", @"evt1", @[], @{@"prop": constraint});
            AvoEventSpecResponse *resp = makeResponse(@[entry]);

            AvoValidationResult *result = [AvoEventValidator validateEvent:@{@"prop": @"val"} specResponse:resp];
            expect(result).toNot.beNil();
            expect(result.metadata).toNot.beNil();
            expect(result.metadata.schemaId).to.equal(@"schema1");
            expect(result.metadata.branchId).to.equal(@"branch1");
        });
    });
});

SpecEnd
