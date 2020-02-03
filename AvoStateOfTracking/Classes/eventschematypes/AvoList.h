//
//  AvoList.h
//  AvoStateOfTracking
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>
#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoList : AvoEventSchemaType

@property (nonatomic, nonnull) NSMutableArray *subtypes;

@end

NS_ASSUME_NONNULL_END
