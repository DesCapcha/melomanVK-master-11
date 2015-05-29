//
//  CenterViewController.h
//  VKiller
//
//  Created by iLego on 10.02.15.
//  Copyright (c) 2015 yury.mehov. All rights reserved.
//

#import "ViewController.h"


@interface CenterViewController : UIViewController

@property (nonatomic, strong) ViewController *mainViewController;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *shuffleBtn;

- (IBAction)showMusicViewModal;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;

@end
