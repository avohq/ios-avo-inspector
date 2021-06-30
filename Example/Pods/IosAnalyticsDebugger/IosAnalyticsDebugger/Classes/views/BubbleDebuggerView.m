//
//  BubbleDebuggerView.m
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import "BubbleDebuggerView.h"
#import "DebuggerEventItem.h"
#import <UIKit/UINib.h>
#import "Util.h"

@interface BubbleDebuggerView ()

@property (weak, nonatomic) IBOutlet UIImageView *bubble;
@property (weak, nonatomic) IBOutlet UIImageView *counterBackground;
@property (weak, nonatomic) IBOutlet UILabel *counter;

@property int eventsCount;

@end

@implementation BubbleDebuggerView

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        [self loadViewFromNib];
    }
    
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self loadViewFromNib];
    }
    
    return self;
}

-(void)loadViewFromNib {
    NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
    NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
    UINib *nib = [UINib nibWithNibName:@"BubbleDebuggerXIB" bundle:resBundle];
    NSArray *views = [nib instantiateWithOwner:self options:nil];
    UIView *view = [views objectAtIndex:0];
    view.frame = self.bounds;
    [self addSubview:view];
    [self showEventCount:0];
    
    [self setError:NO];
}

- (void) showEvent:(DebuggerEventItem *)event {
    [self showEventCount: ++self.eventsCount];
    
    if ([Util eventHaveErrors:event]) {
        [self setError:YES];
    }
}

- (void) onClick {
    [self setError:NO];
    [self showEventCount:0];
}

- (void) setError:(BOOL) hasError {
    NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
    NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
    if (hasError) {
        UIColor * errorColor = [UIColor colorWithRed:0.851 green:0.271 blue:0.325 alpha:1]; //:@"error_color"
        UIImage * backgroundImage = [UIImage imageNamed:@"avo_bubble_error" inBundle:resBundle compatibleWithTraitCollection:nil];
        if (backgroundImage != nil) {
            [self.bubble setImage:backgroundImage];
        } else {
            [self.bubble.layer setBorderColor:[[UIColor grayColor] CGColor]];
            [self.bubble.layer setBackgroundColor:[errorColor CGColor]];
            [self.bubble.layer setBorderWidth:1.0];
            [self.bubble.layer setOpacity:0.5];
            [self.bubble.layer setCornerRadius:self.bubble.bounds.size.width / 2.0f];
            [self.bubble setClipsToBounds:false];
            [self.bubble.layer setShadowColor: [[UIColor grayColor] CGColor]];
            [self.bubble.layer setShadowOpacity: 1];
            [self.bubble.layer setShadowRadius: 10];
            [self.bubble.layer setShadowPath:[UIBezierPath bezierPathWithRoundedRect: self.bubble.bounds cornerRadius: 10].CGPath];
        }
        
        UIImage * badgeImage = [UIImage imageNamed:@"badge_white" inBundle:resBundle compatibleWithTraitCollection:nil];
        if (badgeImage != nil) {
            [self.counterBackground setImage:[UIImage imageNamed:@"badge_white" inBundle:resBundle compatibleWithTraitCollection:nil]];
        } else {
            [self.counterBackground.layer setBackgroundColor:[[UIColor whiteColor] CGColor]];
            [self.counterBackground.layer setCornerRadius:self.counterBackground.bounds.size.width / 2.0f];
        }
        
        [self.counter setTextColor:errorColor];
    } else {
        UIImage * backgroundImage = [UIImage imageNamed:@"avo_bubble" inBundle:resBundle compatibleWithTraitCollection:nil];
        if (backgroundImage != nil) {
            [self.bubble setImage:backgroundImage];
        } else {
            [self.bubble.layer setBorderColor:[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor]];
            [self.bubble.layer setBackgroundColor:[[UIColor whiteColor] CGColor]];
            [self.bubble.layer setBorderWidth:1.0];
            [self.bubble.layer setOpacity:0.5];
            [self.bubble.layer setCornerRadius:self.bubble.bounds.size.width / 2.0f];
            [self.bubble setClipsToBounds:false];
            [self.bubble.layer setShadowColor: [[UIColor grayColor] CGColor]];
            [self.bubble.layer setShadowOpacity: 1];
            [self.bubble.layer setShadowRadius: 10];
            [self.bubble.layer setShadowPath:[UIBezierPath bezierPathWithRoundedRect: self.bubble.bounds cornerRadius: 10].CGPath];
        }
        
        UIImage * badgeImage = [UIImage imageNamed:@"badge_green" inBundle:resBundle compatibleWithTraitCollection:nil];
        if (badgeImage != nil) {
            [self.counterBackground setImage:badgeImage];
        } else {
            [self.counterBackground.layer setBackgroundColor:[[UIColor colorWithRed:0.23 green: 0.73 blue: 0.61 alpha: 1.00] CGColor]];
            [self.counterBackground.layer setCornerRadius:self.counterBackground.bounds.size.width / 2.0f];
        }
        
        [self.counter setTextColor:[UIColor whiteColor]];
    }
}

- (void) showEventCount: (int) eventCount {
    self.eventsCount = eventCount;
    [self.counter setText:[@(self.eventsCount) stringValue]];
}

@end
