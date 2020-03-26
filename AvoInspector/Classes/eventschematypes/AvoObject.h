//
//  AvoObject.h
//  AvoInspector
//
//  Created by Alex Verein on 20.02.2020.
//

#import <Foundation/Foundation.h>

#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoObject : AvoEventSchemaType

@property (nonatomic, nonnull) NSMutableDictionary <NSString *, AvoEventSchemaType *> *fields;

@end

NS_ASSUME_NONNULL_END
