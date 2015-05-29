//
//  LeftViewController.h
//  VKiller
//
//  Created by yury.mehov on 12/2/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "VkontakteSDK.h"


@interface LeftViewController : UIViewController<VKRequestDelegate,VKConnectorDelegate,UIWebViewDelegate,UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *menuTableView;
@property (weak, nonatomic) IBOutlet UIView *musicView;

@property (strong, nonatomic) IBOutlet UIImageView *ava;
@property (strong, nonatomic) IBOutlet UILabel *nameLbl;
@property (weak, nonatomic) IBOutlet UIButton *settingsBtn;

-(void)logoutAction;
@end
