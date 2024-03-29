//
//  AVOViewController.m
//  AvoInspector
//
//  Created by Alexey Verein on 01/28/2020.
//  Copyright (c) 2020 Alexey Verein. All rights reserved.
//

#import "AVOViewController.h"
#import "AVOAppDelegate.h"
#import <Analytics/SEGAnalyticsConfiguration.h>
#import <Analytics/SEGAnalytics.h>
#import <Analytics/SEGMiddleware.h>

@interface AVOViewController ()

@property (weak, nonatomic) IBOutlet UITextField *eventNameInput;

@property (weak, nonatomic) IBOutlet UITextField *param0Key;
@property (weak, nonatomic) IBOutlet UITextField *param0Value;

@property (weak, nonatomic) IBOutlet UITextField *param1Key;
@property (weak, nonatomic) IBOutlet UITextField *param1Value;

@property (weak, nonatomic) IBOutlet UITextField *param2Key;
@property (weak, nonatomic) IBOutlet UITextField *param2Value;

@property (weak, nonatomic) IBOutlet UITextField *param3Value;
@property (weak, nonatomic) IBOutlet UITextField *param3Key;

@property (weak, nonatomic) IBOutlet UITextField *param4Value;
@property (weak, nonatomic) IBOutlet UITextField *param4Key;

@property (weak, nonatomic) IBOutlet UITextField *param5Value;
@property (weak, nonatomic) IBOutlet UITextField *param5Key;

@property (weak, nonatomic) IBOutlet UITextField *param6Value;
@property (weak, nonatomic) IBOutlet UITextField *param6Key;

@property (weak, nonatomic) IBOutlet UITextField *param7Value;
@property (weak, nonatomic) IBOutlet UITextField *param7Key;

@property (weak, nonatomic) IBOutlet UITextField *param8Value;
@property (weak, nonatomic) IBOutlet UITextField *param8Key;

@property (weak, nonatomic) IBOutlet UITextField *param9Key;
@property (weak, nonatomic) IBOutlet UITextField *param9Value;

@property (weak, nonatomic) IBOutlet UITextField *param10Key;
@property (weak, nonatomic) IBOutlet UITextField *param10Value;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)sendEventButton:(id)sender;

@end

@implementation AVOViewController

AvoInspector * avoInspector;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.cancelsTouchesInView = NO;
    
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height*3)];
    
    avoInspector = [AVOAppDelegate getAvoSot];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
    });
    
    SEGAnalyticsConfiguration * config = [SEGAnalyticsConfiguration configurationWithWriteKey: @"YOUR_WRITEKEY_HERE"];
    config.trackApplicationLifecycleEvents = true;
    config.trackDeepLinks = true;
    config.recordScreenViews = true;
   
    SEGBlockMiddleware * avoMiddleware = [[SEGBlockMiddleware alloc] initWithBlock:^(SEGContext * _Nonnull context, SEGMiddlewareNext  _Nonnull next) {
        SEGPayload * payload = [context payload];
        if ([payload isKindOfClass:[SEGTrackPayload class]]) {
            SEGTrackPayload * trackPayload = (SEGTrackPayload *) payload;
            [avoInspector trackSchemaFromEvent:[trackPayload event] eventParams:[trackPayload properties]];
        }
        next(context);
    }];
    
    config.middlewares = @[avoMiddleware];
    
    [SEGAnalytics setupWithConfiguration:config];
    
    [[SEGAnalytics sharedAnalytics] track:@"Item Purchased" properties:@{ @"item": @"Sword of Heracles", @"revenue": @2.95 }];
    
    [self.eventNameInput becomeFirstResponder];
}

- (void)parseKey:(NSString *) key value:(NSString *)value to:(NSMutableDictionary *)testParams {
    if (![key isEqualToString:@""] && ![value isEqualToString:@""]) {
        if ([value isEqualToString:@"nested"]) {
            [testParams setObject:@{@"nested0" : @"some string", @"nested1" : @-1, @"nested2" : @[NSNull.null], @"nested3": @{@"nestedNested0": @"str", @"nestedNested1": @2.3}} forKey:key];
        } else if ([value isEqualToString:@"list"]) {
            [testParams setObject:@[@"some string", @-1, @[NSNull.null], @{@"nestedNested0": @"str", @"nestedNested1": @2.3}] forKey:key];
        } else {
            [testParams setObject:[self parseValue:value] forKey:key];
        }
    }
}

-(id) parseValue:(NSString *)value {
    if (![value isEqualToString:@""]) {
        BOOL isNumber = [[[NSScanner alloc] initWithString:value] scanDouble:nil];
        
        if (isNumber) {
            if (![value containsString:@"."]) {
               return @([value intValue]);
            } else if ([value hasSuffix:@"f"]) {
                return @([value floatValue]);
            } else {
                return @([value doubleValue]);
            }
        } else if ([[value lowercaseString] isEqualToString:@"yes"] || [[value lowercaseString] isEqualToString:@"true"]) {
            return @YES;
        } else if ([[value lowercaseString] isEqualToString:@"no"] || [[value lowercaseString] isEqualToString:@"false"]) {
            return @NO;
        } else if ([[value lowercaseString] isEqualToString:@"null"] || [[value lowercaseString] isEqualToString:@"nil"]) {
            return NSNull.null;
        } else if ([value hasPrefix:@"["] && [value hasSuffix:@"]"]) {
            NSMutableArray *result = [NSMutableArray new];
            
            NSString *arrayContentString = [value substringWithRange:NSMakeRange(1, value.length - 2)];
            NSArray *arrayValues = [arrayContentString componentsSeparatedByString:@","];
            
            for (id arrayValue in arrayValues) {
                NSString *trimmedArrayValue = [arrayValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                [result addObject:[self parseValue:trimmedArrayValue]];
            }
            
            return result;
        } else {
            return value;
        }
    } else {
        return value;
    }
}

- (IBAction)sendEventButton:(id)sender {
    
    NSString * eventName = self.eventNameInput.text;
    
    NSMutableDictionary * testParams = [NSMutableDictionary new];
     
    [self parseKey:self.param0Key.text value:self.param0Value.text to:testParams];
    [self parseKey:self.param1Key.text value:self.param1Value.text to:testParams];
    [self parseKey:self.param2Key.text value:self.param2Value.text to:testParams];
    
     [self parseKey:self.param3Key.text value:self.param3Value.text to:testParams];
     [self parseKey:self.param4Key.text value:self.param4Value.text to:testParams];
     [self parseKey:self.param5Key.text value:self.param5Value.text to:testParams];
    
    [self parseKey:self.param6Key.text value:self.param6Value.text to:testParams];
    [self parseKey:self.param7Key.text value:self.param7Value.text to:testParams];
    [self parseKey:self.param8Key.text value:self.param8Value.text to:testParams];
    
    [self parseKey:self.param9Key.text value:self.param9Value.text to:testParams];
    [self parseKey:self.param10Key.text value:self.param10Value.text to:testParams];
    
    [avoInspector trackSchemaFromEvent:eventName eventParams:(NSDictionary *)testParams];
}

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

@end
