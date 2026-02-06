#import <AvoInspector/AvoAnonymousId.h>
#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoStorage.h>
#import <OCMock/OCMock.h>

@interface AvoInspector ()
+ (id<AvoStorage>)avoStorage;
@end

SpecBegin(AvoAnonymousId)

describe(@"AvoAnonymousId", ^{
    
    beforeEach(^{
        [AvoAnonymousId clearCache];
    });
    
    it(@"generates and stores anonymous id", ^{
        id mockStorage = OCMProtocolMock(@protocol(AvoStorage));
        OCMStub([mockStorage isInitialized]).andReturn(YES);
        OCMStub([mockStorage getItem:[OCMArg any]]).andReturn(nil);
        
        // Mock AvoInspector to return our mock storage
        // AvoInspector is NSObject, so we can partial mock the class?
        // But avoStorage is a class method.
        id mockInspector = OCMClassMock([AvoInspector class]);
        OCMStub([mockInspector avoStorage]).andReturn(mockStorage);
        
        NSString *anonId = [AvoAnonymousId anonymousId];
        
        expect(anonId).toNot.beNil();
        OCMVerify([mockStorage setItem:[AvoAnonymousId storageKey] :anonId]);
        
        [mockInspector stopMocking];
    });
    
    it(@"loads anonymous id from storage", ^{
        id mockStorage = OCMProtocolMock(@protocol(AvoStorage));
        OCMStub([mockStorage isInitialized]).andReturn(YES);
        OCMStub([mockStorage getItem:[AvoAnonymousId storageKey]]).andReturn(@"stored_id");
        
        id mockInspector = OCMClassMock([AvoInspector class]);
        OCMStub([mockInspector avoStorage]).andReturn(mockStorage);
        
        NSString *anonId = [AvoAnonymousId anonymousId];
        
        expect(anonId).to.equal(@"stored_id");
        
        [mockInspector stopMocking];
    });
    
    it(@"returns unknown if not initialized", ^{
        id mockStorage = OCMProtocolMock(@protocol(AvoStorage));
        OCMStub([mockStorage isInitialized]).andReturn(NO);
        
        id mockInspector = OCMClassMock([AvoInspector class]);
        OCMStub([mockInspector avoStorage]).andReturn(mockStorage);
        
        NSString *anonId = [AvoAnonymousId anonymousId];
        
        expect(anonId).to.equal(@"unknown");
        
        [mockInspector stopMocking];
    });
});

SpecEnd
