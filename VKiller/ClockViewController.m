//
//  ClockViewController.m
//  VKiller
//
//  Created by iLego on 18.11.14.
//  Copyright (c) 2014 yury.mehov. All rights reserved.
//

#import "ClockViewController.h"

@interface ClockViewController ()
@end

@implementation ClockViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView {
    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComps = [gregorianCal components: (NSHourCalendarUnit | NSMinuteCalendarUnit)
                                                  fromDate: [NSDate date]];
    UIView *contentView = [[UIView alloc] init];
    
    _timerControl1 = [[DDHTimerControl alloc] init];
    _timerControl1.translatesAutoresizingMaskIntoConstraints = NO;
    _timerControl1.color = [UIColor whiteColor];
    _timerControl1.highlightColor = [UIColor blackColor];
    _timerControl1.minutesOrSeconds =dateComps.hour;
    _timerControl1.maxValue = 24;
    _timerControl1.titleLabel.text = @"час";
    [contentView addSubview:_timerControl1];
    
    [_timerControl1 addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    
    _timerControl2 = [DDHTimerControl timerControlWithType:DDHTimerTypeEqualElements];
    _timerControl2.translatesAutoresizingMaskIntoConstraints = NO;
    _timerControl2.color = [UIColor whiteColor];
    _timerControl2.minutesOrSeconds =dateComps.minute+1;
    _timerControl2.highlightColor = [UIColor blackColor];
    _timerControl2.titleLabel.text = @"мин";
    [contentView addSubview:_timerControl2];
    
    
    
    self.view = contentView;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_timerControl1 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_timerControl1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_timerControl1 attribute:NSLayoutAttributeHeight multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_timerControl2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_timerControl2 attribute:NSLayoutAttributeHeight multiplier:1.0f constant:0.0f]];
    
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_timerControl1, _timerControl2);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-80-[_timerControl1(200)]-30-[_timerControl2(100)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewsDictionary]];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)random:(UIButton*)sender {
    NSUInteger randomInteger = arc4random_uniform(60);
    
    self.timerControl1.minutesOrSeconds = randomInteger;
}


- (void)valueChanged:(DDHTimerControl*)sender {
}
@end