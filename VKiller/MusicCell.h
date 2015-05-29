//
//  MusicCell.h
//  VKiller
//
//  Created by yury.mehov on 11/29/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDActivityIndicatorView.h"
#import "CRTableViewCell.h"

@interface MusicCell : UITableViewCell {
    NSInteger offset;
}
@property (strong, nonatomic) IBOutlet UILabel *nameLbl;
@property (strong, nonatomic) IBOutlet UILabel *songLbl;
@property (strong, nonatomic) IBOutlet UIButton *downloadBtn;
@property (strong, nonatomic) IBOutlet CDActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UILabel *currentPlay;
@property (strong, nonatomic) IBOutlet UILabel *bitrateLbl;
@property (weak, nonatomic) IBOutlet UILabel *durationLbl;

@property (strong, nonatomic) UIImageView *btn;

@end
