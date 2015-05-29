//
//  SettingsViewController.h
//  VKiller
//
//  Created by yury.mehov on 07/08/14.
//  Copyright (c) 2014 yury.mehov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClockViewController.h"

@interface SettingsViewController : UIViewController<VKRequestDelegate,UIActionSheetDelegate, UIImagePickerControllerDelegate>
- (IBAction)dissmissView;
- (IBAction)setFone;
- (IBAction)setColorText;
- (IBAction)clearColors;
- (IBAction)alarm:(UIButton*)btn;
- (IBAction)alarmDeleteAction;
- (IBAction)dateSleepDelete;

@property (strong, nonatomic) IBOutlet UIButton *alarmDel;
@property (weak, nonatomic) IBOutlet UILabel *alarmLbl;
@property (strong, nonatomic) IBOutlet UILabel *dateSleepLabel;
@property (strong, nonatomic) IBOutlet UISwitch *bitrateSwitcher;
@end
