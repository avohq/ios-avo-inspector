//
//  EventTableViewCell.m
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import "EventTableViewCell.h"
#import "Util.h"
#import "DebuggerProp.h"
#import "EventTableViewSecondaryCell.h"
#import "DebuggerMessage.h"

@interface EventTableViewCell()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *additionalRowsHeight;
@property (weak, nonatomic) IBOutlet UIImageView *expendCollapseImage;
@property (weak, nonatomic) IBOutlet UIView *mainRow;
@property (weak, nonatomic) IBOutlet UIImageView *statusIcon;
@property (weak, nonatomic) IBOutlet UILabel *eventName;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UITableView *additionalRows;

@property (nonatomic, readwrite) NSInteger additionalRowsExpendedHeight;

@end

@implementation EventTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.mainRow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleExpend)]];

    NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
    NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
    UINib *eventSecondatyRowItemNib = [UINib nibWithNibName:@"EventTableViewSecondaryCell" bundle:resBundle];
    [self.additionalRows registerNib:eventSecondatyRowItemNib forCellReuseIdentifier:@"EventTableViewSecondaryCell"];
    [self.additionalRows setDataSource:self];
    self.additionalRows.allowsSelection = false;

    [self.expendCollapseImage setImage:[UIImage imageNamed:@"avo_debugger_collapse_arrow" inBundle:resBundle compatibleWithTraitCollection:nil]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) toggleExpend {
    BOOL expended = NO;
    if (self.additionalRowsHeight.constant == 0) {
        expended = YES;
        [self expend];
    } else {
        [self collapse];
    }
    
    [self.eventsListScreenViewController setExpendedStatus:expended forEvent:self.event];
}

- (BOOL) expended {
    return !self.additionalRows.hidden;
}

- (void) expend {
    if (![self expended]) {
        self.additionalRowsHeight.constant = self.additionalRowsExpendedHeight;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^ {
            self.additionalRows.hidden = false;
        });
       
        [self layoutIfNeeded];
        [self setNeedsUpdateConstraints];
        
        NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
        NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
        [self.expendCollapseImage setImage:[UIImage imageNamed:@"avo_debugger_collapse_arrow" inBundle:resBundle compatibleWithTraitCollection:nil]];
    }
}

- (void) collapse {
    if ([self expended]) {
        self.additionalRowsHeight.constant = 0;
        self.additionalRows.hidden = true;
        
        [self layoutIfNeeded];
        [self setNeedsUpdateConstraints];
        
        NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
        NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
        [self.expendCollapseImage setImage:[UIImage imageNamed:@"expend_arrow" inBundle:resBundle compatibleWithTraitCollection:nil]];
    }
}

- (void) showError:(BOOL) isError {
    NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
    NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
    if (isError) {
        [self.eventName setTextColor:[UIColor colorWithRed:0.851 green:0.271 blue:0.325 alpha:1]]; //@"error_color"
        [self.statusIcon setImage:[UIImage imageNamed:@"red_warning" inBundle:resBundle compatibleWithTraitCollection:nil]];
    } else {
        if (@available(iOS 13.0, *)) {
            [self.eventName setTextColor:[UIColor labelColor]];
        } else {
            [self.eventName setTextColor:[UIColor blackColor]];
        }
        [self.statusIcon setImage:[UIImage imageNamed:@"avo_debugger_tick" inBundle:resBundle compatibleWithTraitCollection:nil]];
    }
}

- (void)calculateExpendedAdditionalRowsHeight {
    NSInteger count = [self.event.eventProps count] + [self.event.userProps count];
    self.additionalRowsExpendedHeight = 40 * count + 8;
    
    for (DebuggerProp *prop in self.event.eventProps) {
        for (int i = 0; i < [self.event.messages count]; i++) {
            DebuggerMessage *messageData = [self.event.messages objectAtIndex:i];
            if (messageData.propertyId == prop.id) {
                self.additionalRowsExpendedHeight += 28;
                break;
            }
        }
    }
}

- (void) populateWithEvent: (DebuggerEventItem *)event {
    self.event = event;
    
    [self.eventName setText:[event name]];
    [self.timestamp setText:[Util timeString:event.timestamp]];
    
    [self calculateExpendedAdditionalRowsHeight];
    
    [self.additionalRows reloadData];
    
    if ([self expended]) {
        self.additionalRowsHeight.constant = self.additionalRowsExpendedHeight;
        self.additionalRows.hidden = false;

        [self setNeedsUpdateConstraints];
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    EventTableViewSecondaryCell * cell = [tableView dequeueReusableCellWithIdentifier:@"EventTableViewSecondaryCell" forIndexPath:indexPath];
    
    DebuggerProp *prop = nil;
    if (indexPath.row < [self.event.eventProps count]) {
        prop = [self.event.eventProps objectAtIndex:indexPath.row];
    } else if (indexPath.row < [self.event.eventProps count] + [self.event.userProps count]) {
       prop = [self.event.userProps objectAtIndex:(indexPath.row - [self.event.eventProps count])];
    }
    
    if (prop != nil) {
        [cell populateWithProp:prop];
    }
    
    BOOL hasError = NO;
    DebuggerMessage *messageData = nil;
    
    for (int i = 0; i < [self.event.messages count]; i++) {
        messageData = [self.event.messages objectAtIndex:i];
        if ([messageData.propertyId isEqualToString:prop.id]) {
            hasError = YES;
            break;
        }
    }
    
    if (hasError) {
        [cell showError:[self formatErrorMessage:messageData propertyName:prop.name]];
    } else {
        [cell hideError];
    }
    
    return cell;
}

- (NSAttributedString *) formatErrorMessage:(DebuggerMessage *)messageData propertyName:(NSString *)propName {
    if (messageData.allowedTypes == nil || [messageData.allowedTypes count] == 0
            || messageData.providedType == nil || messageData.providedType.length == 0) {
        return [[NSAttributedString alloc] initWithString:messageData.message];
    }
    
    const CGFloat fontSize = 11;
    NSDictionary *bold = @{
        NSFontAttributeName:[UIFont boldSystemFontOfSize:fontSize]
    };
    
    NSMutableAttributedString *attributedText =
      [[NSMutableAttributedString alloc] initWithString:messageData.message];
    [attributedText setAttributes:bold range:[messageData.message rangeOfString:propName]];
    
    for (NSString *allowedType in messageData.allowedTypes) {
        [attributedText setAttributes:bold range:[messageData.message rangeOfString:allowedType]];
    }
    
    [attributedText setAttributes:bold range:[messageData.message rangeOfString:messageData.providedType]];
    
    return attributedText;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [self.event.eventProps count] + [self.event.userProps count];
    return count;
}

@end
