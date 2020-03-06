//
//  AvoList.h
//  AvoInspector
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>
#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoList : AvoEventSchemaType

@property (nonatomic, nonnull) NSMutableSet *subtypes;

@end

NS_ASSUME_NONNULL_END
