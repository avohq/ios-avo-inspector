//
//  EventTableViewSecondaryCell.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DebuggerProp.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTableViewSecondaryCell : UITableViewCell

- (void) populateWithProp: (DebuggerProp *) prop;
- (void) showError: (NSAttributedString *) errorMessage;
- (void) hideError;

@end

NS_ASSUME_NONNULL_END
