#import "AvoAnonymousId.h"
#import "AvoGuid.h"
#import "AvoInspector.h"

@implementation AvoAnonymousId
static NSString * ___anonymousId = nil;
+ (NSString *)_anonymousId {
  return ___anonymousId;
}
+ (void)set_anonymousId:(NSString *)val {
  ___anonymousId = val;
}
static NSString * __storageKey = @"AvoInspectorAnonymousId";
+ (NSString *)storageKey {
  return __storageKey;
}


+ (NSString *)anonymousId {
  @synchronized(self) {
    if (![[AvoAnonymousId _anonymousId] isEqual:nil] && [[AvoAnonymousId _anonymousId] length] != 0) {
      return [AvoAnonymousId _anonymousId];
    }
    if (![[AvoInspector avoStorage] isInitialized]) {
      return @"unknown";
    }
    NSString * maybeAnonymousId = nil;
    @try {
      maybeAnonymousId = [[AvoInspector avoStorage] getItem:[AvoAnonymousId storageKey]];
    } @catch (NSException *e) {
      NSLog(@"%@", [NSString stringWithFormat:@"%@ %@", @"Avo Inspector: Error reading anonymous ID from storage. Please report to support@avo.app.", e]);
    }
    if ([maybeAnonymousId isEqual:nil] || [maybeAnonymousId length] == 0) {
      [AvoAnonymousId set_anonymousId:[AvoGuid newGuid]];
      @try {
        [[AvoInspector avoStorage] setItem:[AvoAnonymousId storageKey] :[AvoAnonymousId _anonymousId]];
      } @catch (NSException *e) {
        NSLog(@"%@", [NSString stringWithFormat:@"%@ %@", @"Avo Inspector: Error saving anonymous ID to storage. Please report to support@avo.app.", e]);
      }
    } else {
      [AvoAnonymousId set_anonymousId:maybeAnonymousId];
    }
    return [AvoAnonymousId _anonymousId];
  }
}

+ (void)setAnonymousId:(NSString *)_id {
  @synchronized(self) {
    [AvoAnonymousId set_anonymousId:_id];
    @try {
      [[AvoInspector avoStorage] setItem:[AvoAnonymousId storageKey] :[AvoAnonymousId _anonymousId]];
    } @catch (NSException *e) {
      NSLog(@"%@", [NSString stringWithFormat:@"%@ %@", @"Avo Inspector: Error saving anonymous ID to storage. Please report to support@avo.app.", e]);
    }
  }
}


+ (void)clearCache {
  @synchronized(self) {
    [AvoAnonymousId set_anonymousId:nil];
  }
}

@end
