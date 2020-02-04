//
//  AvoStateOfTracking.h
//  AvoStateOfTracking
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>
#import "StateOfTracking.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoStateOfTracking : NSObject <StateOfTracking>

@property (readonly, nonatomic) NSString * appVersion;
@property (readonly, nonatomic) NSInteger libVersion;

@end

NS_ASSUME_NONNULL_END
