//
//  EventTableViewSecondaryCell.m
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import "EventTableViewSecondaryCell.h"

@interface EventTableViewSecondaryCell()

@property (weak, nonatomic) IBOutlet UILabel *propName;
@property (weak, nonatomic) IBOutlet UILabel *propValue;
@property (weak, nonatomic) IBOutlet UILabel *message;

@end

@implementation EventTableViewSecondaryCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) populateWithProp: (DebuggerProp *) prop {
    
    [self.propName setText:prop.name];
    [self.propValue setText:[prop.value description]];
    
}

- (void) showError: (NSAttributedString *) errorMessage {
    [self.propName setTextColor:[UIColor colorWithRed:0.851 green:0.271 blue:0.325 alpha:1]]; // @"error_color"
    [self.propValue setTextColor:[UIColor colorWithRed:0.851 green:0.271 blue:0.325 alpha:1]]; // @"error_color"
    
    [self.message setAttributedText:errorMessage];
}

@end
