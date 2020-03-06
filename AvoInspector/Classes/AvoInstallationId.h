//
//  AvoInstallationId.h
//  AvoInspector
//
//  Created by Alex Verein on 06.02.2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AvoInstallationId : NSObject

- (NSString *) getInstallationId;

+ (NSString *) cacheKey;

@end

NS_ASSUME_NONNULL_END
