//
//  MusicViewController.h
//  VKiller
//
//  Created by yury.mehov on 12/2/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicManager.h"
#import "VisualizerView.h"
#import "AutoScrollLabel.h"

enum StatusPlayer{
    PAUSE = 1,
    PLAY = 2
};

enum StatusDownBtn{
    ADD = 1,
    REMOVE = 2,
    OK = 3,
    DOWNLOAD = 4
};

enum SliderTag{
    VOLUME = 1,
    TIME = 2
};

@interface MusicViewController : UIViewController<VKRequestDelegate, UIAlertViewDelegate,UIActionSheetDelegate>

@property (strong, nonatomic) IBOutlet AutoScrollLabel *nameLbl;
@property (strong, nonatomic) IBOutlet UILabel *songLbl;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UILabel *durationLbl;
@property (strong, nonatomic) IBOutlet UILabel *musicTimeLbl;
@property (strong, nonatomic) IBOutlet UIButton *downLbl;
@property (strong, nonatomic) IBOutlet UITextView *textTrackScroll;
@property (weak, nonatomic) IBOutlet UILabel *countLbl;
@property (weak, nonatomic) IBOutlet UIButton *listBtn;

@property (nonatomic,strong) UILongPressGestureRecognizer *lpgr;
@property (nonatomic,strong) UITapGestureRecognizer *tapGesture;

@property (strong,nonatomic) NSURL* url;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UISlider *sliderTime;
- (IBAction)textAction;

- (IBAction)clickPlayResume;
- (IBAction)nextSong:(BOOL)user;
- (IBAction)prevSong;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)sliderTime:(UISlider *)sender;
- (IBAction)repeatAction:(UIButton*)sender;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (strong, nonatomic) IBOutlet UILabel *bitrateLbl;
@end
