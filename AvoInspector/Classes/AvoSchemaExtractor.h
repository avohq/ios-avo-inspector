//
//  AvoSchemaExtractor.h
//  AvoInspector
//
//  Created by Alex Verein on 15.07.2020.
//

#import <Foundation/Foundation.h>
#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoSchemaExtractor : NSObject

-(NSDictionary<NSString *, AvoEventSchemaType *> *) extractSchema:(NSDictionary<NSString *, id> *) eventParams;

-(void)printAvoParsingError:(NSException *) exception;

@end

NS_ASSUME_NONNULL_END
