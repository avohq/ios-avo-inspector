//
//  EventsListScreenViewController.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DebuggerEventItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventsListScreenViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (void) setExpendedStatus:(BOOL) expended forEvent:(DebuggerEventItem *) event;

@end

NS_ASSUME_NONNULL_END
