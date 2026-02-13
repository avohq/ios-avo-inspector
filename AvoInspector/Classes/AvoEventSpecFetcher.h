#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AvoEventSpecResponse;
@class AvoFetchEventSpecParams;

typedef void (^AvoEventSpecFetchCompletion)(AvoEventSpecResponse * _Nullable response);

@interface AvoEventSpecFetcher : NSObject

- (instancetype)initWithTimeout:(NSTimeInterval)timeout
                            env:(NSString *)env NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTimeout:(NSTimeInterval)timeout
                            env:(NSString *)env
                        baseUrl:(NSString *)baseUrl;

- (instancetype)init NS_UNAVAILABLE;

- (void)fetchEventSpec:(AvoFetchEventSpecParams *)params
            completion:(AvoEventSpecFetchCompletion)completion;

@end

NS_ASSUME_NONNULL_END