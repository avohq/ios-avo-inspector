//
//  EventsListScreenViewController.m
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import "EventsListScreenViewController.h"
#import "EventTableViewCell.h"
#import "AnalyticsDebugger.h"
#import "Util.h"

@interface EventsListScreenViewController ()

@property (weak, nonatomic) IBOutlet UIView *closeButton;
@property (weak, nonatomic) IBOutlet UITableView *eventsTableView;
@property (weak, nonatomic) IBOutlet UIImageView *closeButtonIcon;
@property (weak, nonatomic) IBOutlet UIImageView *avoLogoImage;

@property (strong, nonatomic) NSMutableSet *expendedEvents;

@end

@implementation EventsListScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self.closeButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSelf)]];
    
    self.expendedEvents = [NSMutableSet new];
    [self populateExpended];
    
    NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
    NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
    UINib *eventItemNib = [UINib nibWithNibName:@"EventTableViewCell" bundle:resBundle];
      
    [self.eventsTableView registerNib:eventItemNib forCellReuseIdentifier:@"EventTableViewCell"];
    
    [self.eventsTableView setDelegate:self];
    [self.eventsTableView setDataSource:self];
     
    UITableView * __weak weakTableView = self.eventsTableView;
    [AnalyticsDebugger setOnNewEventCallback:^(DebuggerEventItem * _Nonnull item) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [weakTableView reloadData];
        });
    }];
    
    [self.closeButtonIcon setImage:[UIImage imageNamed:@"avo_debugger_close_button" inBundle:resBundle compatibleWithTraitCollection:nil]];
    [self.avoLogoImage setImage:[UIImage imageNamed:@"avo_logo" inBundle:resBundle compatibleWithTraitCollection:nil]];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    self.eventsTableView.tableFooterView = [UIView new];
}

- (void)dealloc {
    [AnalyticsDebugger setOnNewEventCallback:nil];
}

- (void) populateExpended {
    
    for (int i = 0; i < [AnalyticsDebugger.events count]; i++) {
        DebuggerEventItem *event = [AnalyticsDebugger.events objectAtIndex:i];
        if (i == 0 || [Util eventHaveErrors:event]) {
            [self.expendedEvents addObject:event];
        }
    }
}

- (void) dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    EventTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"EventTableViewCell" forIndexPath:indexPath];
    cell.eventsListScreenViewController = self;
    [cell populateWithEvent:[AnalyticsDebugger.events objectAtIndex:indexPath.row]];
    
    if ([self.expendedEvents containsObject:cell.event]) {
        [cell expend];
    } else {
        [cell collapse];
    }
    
    [cell showError:[Util eventHaveErrors:cell.event]];
 
    [self showFullLengthSeparators:cell];
    
    return cell;
}

- (void)showFullLengthSeparators:(EventTableViewCell *)cell {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [AnalyticsDebugger.events count];
    return count;
}

- (void) setExpendedStatus:(BOOL) expended forEvent:(DebuggerEventItem *) event  {
    [self.eventsTableView beginUpdates];
    if (expended) {
        [self.expendedEvents addObject:event];
    } else {
        [self.expendedEvents removeObject:event];
    }
    [self.eventsTableView endUpdates];
}

@end
