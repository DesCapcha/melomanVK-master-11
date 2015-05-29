//
//  MusicViewController.m
//  VKiller
//
//  Created by yury.mehov on 12/2/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import "MusicViewController.h"
#import "RBVolumeButtons.h"
#import "MusicManager.h"
#import "MusicManager.h"
#import "RNBlurModalView.h"
#import "CenterViewController.h"
#import "PlaylistTableViewController.h"
#import "UIImage+Color.h"
#import "Album.h"
#import "NGAParallaxMotion.h"

#define STEP_VOLUME 0.1
@interface MusicViewController ()<NSURLConnectionDelegate>
{
    int durationTime;
    int currentTime;
    BOOL isTouch;
    IBOutlet UIButton *randomBtn;
    IBOutlet UIButton *repeatBtn;
    UIImageView *viewImage;
    
    UIDocumentInteractionController * _documentInteractionController;
    
    PlaylistTableViewController *playlist;
    
    NSOperationQueue *serialQueue;
    UIImage *tempImg;
    UIImage *defaultCover;
    UIImage *blurImage;
    
}

@property (strong, nonatomic) VisualizerView *visualizer;
//@property (strong, nonatomic) UIImageView *nextCoverImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *coverProgress;

@end

@implementation MusicViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


+ (UIImage *)filledImageFrom:(UIImage *)source withColor:(UIColor *)color{
    
    // begin a new image context, to draw our colored image onto with the right scale
    UIGraphicsBeginImageContextWithOptions(source.size, NO, [UIScreen mainScreen].scale);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [color setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, source.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, source.size.width, source.size.height);
    CGContextDrawImage(context, rect, source.CGImage);
    
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
}

CGPoint startLocation;

- (void)panGesture:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        startLocation = [sender locationInView:self.view];
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint stopLocation = [sender locationInView:self.view];
        CGFloat dx = stopLocation.x - startLocation.x;
        CGFloat dy = stopLocation.y - startLocation.y;
        if(fabs(dx) < 50.) {
            float vokl = [[AVAudioSession sharedInstance] outputVolume];
            [[MusicManager sharedMusicManager] setVolume:vokl - dy/200];
        }
        else if (dx > 50) {
            if([MusicManager sharedMusicManager].Offgestures) return;
            [[AppDelegate sharedDelegate].musicViewController prevSong];
        }
        else if (dx < -50) {
            if([MusicManager sharedMusicManager].Offgestures) return;
            [[AppDelegate sharedDelegate].musicViewController nextSong:NO];
        }
        NSLog(@"Distance: %f %f", dx,dy);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = @"";
    
    
    
    
    UIPanGestureRecognizer *swipeGestureVolume = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.coverImage addGestureRecognizer: swipeGestureVolume];
    
    self.nameLbl.text = [[MusicManager sharedMusicManager] currentMusicName];
    self.songLbl.text = [[MusicManager sharedMusicManager] currentMusicArtist];
    self.nameLbl.font = [UIFont fontWithName:@"AppleSDGothicNeo-UltraLight" size:21];
    //[self.nameLbl scroll];
    durationTime = [MusicManager sharedMusicManager].currentDuration;
    int min = durationTime/60;
    int sec = durationTime%60;
    NSString *secondsString;
    if(sec < 10)
        secondsString = [NSString stringWithFormat:@"0%d",sec];
    else
    {
        secondsString = [NSString stringWithFormat:@"%d",sec];
    }
    if(durationTime != 0)
        self.durationLbl.text = [NSString stringWithFormat:@"%d:%@",min,secondsString];
    [self.sliderTime addTarget:self action:@selector(touchStart) forControlEvents:UIControlEventTouchDown];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedFone) name:POST_CHANGED_FONE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDuration:) name:@"DURATION" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTime:) name:@"TIME" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemIsFinished) name:@"FINISHED" object:nil];
    
    
    RBVolumeButtons *buttonStealer = [[RBVolumeButtons alloc] init];
    buttonStealer.upBlock = ^{
        self.slider.value = self.slider.value + STEP_VOLUME;
    };
    buttonStealer.downBlock = ^{
        self.slider.value = self.slider.value - STEP_VOLUME;
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeChanged:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];
    CGRect frame = CGRectMake(-200, -200, 10, 0);
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:frame];
    volumeView.alpha = 0.1f;
    [volumeView sizeToFit];
    [self.view addSubview:volumeView];
    
    
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"Color"];
    if(colorData){
        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        self.playButton.layer.borderColor = color.CGColor;
        self.slider.layer.borderColor = color.CGColor;
        self.sliderTime.layer.borderColor = color.CGColor;
        self.sliderTime.thumbTintColor = color;
        self.sliderTime.maximumTrackTintColor = color;
        self.slider.maximumTrackTintColor = color;
        self.slider.minimumTrackTintColor = [color colorWithAlphaComponent:0.4];
        self.sliderTime.minimumTrackTintColor = [color colorWithAlphaComponent:0.4];
        [self.view viewWithTag:76].layer.borderColor = color.CGColor;
        [self.view viewWithTag:76].layer.borderColor = color.CGColor;
        
        UIImage *imageN = [[self class] filledImageFrom:[UIImage imageNamed:@"thumb.png"] withColor:color];
        [[UISlider appearance] setThumbImage:imageN
                                    forState:UIControlStateNormal];
        [[UISlider appearance] setThumbImage:imageN
                                    forState:UIControlStateHighlighted];
    }
    else {
        self.playButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"thumb.png"]
                                    forState:UIControlStateNormal];
        [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"thumb.png"]
                                    forState:UIControlStateHighlighted];
    }
    
    self.textTrackScroll.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    self.visualizer.backgroundColor = [UIColor clearColor];
    
    UIBarButtonItem *list = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"7_audioplayer_playlist.png"] style:UIBarButtonItemStylePlain target:self action:@selector(listAction:)];
    UIBarButtonItem *rand = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"paper.png"] style:UIBarButtonItemStylePlain target:self action:@selector(actionMusic)];
    self.navigationItem.rightBarButtonItems = @[list,rand];
    
    [self.navigationController.navigationBar addSubview:self.countLbl];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    self.lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
    self.lpgr.minimumPressDuration = 1.0f;
    self.lpgr.allowableMovement = 100.0f;
    
    
    [self.coverImage addGestureRecognizer:self.lpgr];
    
    serialQueue = [[NSOperationQueue alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"fone.jpg"];
    if(imagePath){
        tempImg = [UIImage imageWithContentsOfFile:imagePath];
    }
    
    // Do any additional setup after loading the view from its nib.
}


-(void)viewDidLayoutSubviews {
    if(!self.visualizer){
        CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.nameLbl.frame.origin.y);
        
        self.visualizer = [[VisualizerView alloc] initWithFrame:rect];
        [self.visualizer setAudioPlayer:[MusicManager sharedMusicManager].audioPlayer.currentPlayer];
        _visualizer.alpha = 0.4;
    }
    [_visualizer removeFromSuperview];
    if(![MusicManager sharedMusicManager].isOnline && ![MusicManager sharedMusicManager].coverShow){
        if(viewImage)
            [self.view insertSubview:self.visualizer aboveSubview:viewImage];
        else {
            [self.view addSubview:self.visualizer];
            [self.view sendSubviewToBack:self.visualizer];
        }
    }
    if(!viewImage)
        [self changedFone];
}


-(void)viewWillAppear:(BOOL)animated {
    
    [_visualizer removeFromSuperview];
    if([MusicManager sharedMusicManager].coverShow || [MusicManager sharedMusicManager].isOnline) {
        defaultCover = [UIImage imageNamed:@"makro-muzyka-miksher.jpg"];
        self.coverImage.image = defaultCover;
    }
    else {
        self.coverImage.image = nil;
        if(viewImage)
            [self.view insertSubview:self.visualizer aboveSubview:viewImage];
        else {
            [self.view addSubview:self.visualizer];
            [self.view sendSubviewToBack:self.visualizer];
        }
    }
    self.slider.value = [AVAudioSession sharedInstance].outputVolume;
    BOOL isPLaying = [[MusicManager sharedMusicManager].audioPlayer isPlaying];
    self.playButton.tag = isPLaying? PAUSE:PLAY;
    if(isPLaying) {
        self.playButton.tag = PAUSE;
        [self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    }
    else {
        self.playButton.tag = PLAY;
        [self.playButton setImage:[UIImage imageNamed:@"playMusic1.png"] forState:UIControlStateNormal];
    }
    if([MusicManager sharedMusicManager].coverShow || [MusicManager sharedMusicManager].isOnline) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[MusicManager sharedMusicManager] currentCoverWithCompletedBlock:^(UIImage *imageBlock){
                blurImage = [imageBlock applyDarkEffect];
                if(imageBlock)
                    dispatch_async(dispatch_get_main_queue(), ^{self.coverImage.image = imageBlock;viewImage.image = blurImage;});
            }];
        });
    }
    else {
        blurImage = nil;
        [self changedFone];
    }
    [self changedFone];
    BOOL isContains = ([[AppDelegate sharedDelegate] musicByIdAudio:[[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row] andIdUser:[[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row]] != nil);
    if((!isContains && [MusicManager sharedMusicManager].stateOfMusic == home) || (isContains && [MusicManager sharedMusicManager].stateOfMusic != home))
    {
        [self.downLbl setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
        self.downLbl.tag = OK;
    }
    else if([MusicManager sharedMusicManager].isOnline){
    }
    else{
        self.downLbl.tag = OK;
    }
    if([MusicManager sharedMusicManager].stateOfMusic != myMusic && [MusicManager sharedMusicManager].stateOfMusic != home) {
        randomBtn.userInteractionEnabled = YES;
        [randomBtn setImage:[UIImage imageNamed:@"audioplayer_add.png"] forState:UIControlStateNormal];
        randomBtn.tag = 12;
    }
    else {
        [randomBtn setImage:[UIImage imageNamed:@"minus.png"] forState:UIControlStateNormal];
        randomBtn.tag = REMOVE;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillAppear:animated];
    [playlist.tableView reloadData];
    
    self.countLbl.text = [NSString stringWithFormat:@"%ld из %lu",(long)[MusicManager sharedMusicManager].playIndexPlaylist.row+1,(unsigned long)[MusicManager sharedMusicManager].listPlayNames.count];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}

- (void) volumeChanged:(NSNotification *)notify
{
    NSNumber *volume = [notify.userInfo objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"];
    self.slider.value = volume.floatValue;
    
}

-(void)touchStart
{
    isTouch = YES;
}


-(void)updateDuration:(NSNotification*)note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.visualizer setAudioPlayer:[MusicManager sharedMusicManager].audioPlayer.currentPlayer];
        NSNumber* duration = [note.userInfo objectForKey:@"duration"];
        NSString *artist = [[MusicManager sharedMusicManager] currentMusicArtist];
        NSString *title = [[MusicManager sharedMusicManager] currentMusicName];
        self.musicTimeLbl.text = @"0:00";
        self.sliderTime.value = 0;
        if(duration != 0)
            durationTime = duration.intValue;
        int min = duration.intValue/60;
        int sec = duration.intValue%60;
        NSString *secondsString;
        if(sec < 10)
            secondsString = [NSString stringWithFormat:@"0%d",sec];
        else
        {
            secondsString = [NSString stringWithFormat:@"%d",sec];
        }
        if(duration != 0)
            self.durationLbl.text = [NSString stringWithFormat:@"%d:%@",min,secondsString];
        
        [UIView animateWithDuration:.3f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
            [self.nameLbl setAlpha:.0f];
            [self.songLbl setAlpha:.0f];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.3f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.nameLbl setAlpha:1.0f];
                [self.songLbl setAlpha:1.0f];
            } completion:^(BOOL ok){
            }];
            if(title) {
                self.nameLbl.text = title;
            }
            if(artist)
                self.songLbl.text = artist;
            [self.nameLbl scroll];
        }];
        BOOL isContains = ([[AppDelegate sharedDelegate] musicByIdAudio:[[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row] andIdUser:[[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row]] != nil);
        if((!isContains && [MusicManager sharedMusicManager].stateOfMusic == home) || (isContains && [MusicManager sharedMusicManager].stateOfMusic != home))
        {
            [self.downLbl setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
            self.downLbl.tag = OK;
        }
        else if([MusicManager sharedMusicManager].isOnline){
            [self.downLbl setImage:[UIImage imageNamed:@"action2.png"] forState:UIControlStateNormal];
            self.downLbl.tag = DOWNLOAD;
        }
        else{
            
            self.downLbl.tag = OK;
        }
        if([MusicManager sharedMusicManager].stateOfMusic != myMusic && [MusicManager sharedMusicManager].stateOfMusic != home) {
            [randomBtn setImage:[UIImage imageNamed:@"audioplayer_add.png"] forState:UIControlStateNormal];
            randomBtn.tag = 12;
        }
        else {
            [randomBtn setImage:[UIImage imageNamed:@"minus.png"] forState:UIControlStateNormal];
            randomBtn.tag = REMOVE;
        }
        
        self.playButton.tag = PAUSE;
        [self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        
        NSNumber *idA;
        if([MusicManager sharedMusicManager].listPlayLyrics.count > [MusicManager sharedMusicManager].playIndexPlaylist.row)
            idA = [[MusicManager sharedMusicManager].listPlayLyrics objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
        if(idA.integerValue > 0 && self.textTrackScroll.alpha == 1){
            self.textTrackScroll.text = @"\n\n\n\n\n\n Текст трека не найден";
            [self showTextOfTrack:idA];
        }
    });
    if([MusicManager sharedMusicManager].coverShow || [MusicManager sharedMusicManager].isOnline){
        [[MusicManager sharedMusicManager] currentCoverWithCompletedBlock:^(UIImage *imageBlock){
            if(imageBlock) {
                blurImage = [imageBlock applyDarkEffect];
                dispatch_async(dispatch_get_main_queue(), ^{self.coverImage.image = imageBlock;viewImage.image = blurImage;});
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.coverImage.image = defaultCover;
                    viewImage.image = tempImg;
                });
            }
        }];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(tempImg)
                viewImage.image = tempImg;
            else viewImage.image = nil;
        });
    }
    
}



- (IBAction)downAction:(UIButton *)sender {
    if(sender.tag == REMOVE) {
        
        if([MusicManager sharedMusicManager].listPlayIdAudio.count == 0)
            return;
        UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Удаление" message:@"Вы уверены, что хотите удалить трек?" delegate:self cancelButtonTitle:@"Удалить" otherButtonTitles:@"Нет", nil];
        deleteAlert.tag = 74;
        [deleteAlert show];
    }
    else if(sender.tag == ADD)
    {
        if([MusicManager sharedMusicManager].listPlayIdAudio.count != 0){
            VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                         initWithDelegate:self
                                         user:[VKUser currentUser]];
            NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
            NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
            [rmLocal audioAdd:@{@"audio_id":idA,@"owner_id":idU}];
            [randomBtn setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
            randomBtn.tag = OK;
        }
    }
    else if (sender.tag == DOWNLOAD) {
        UIButton *b = [[UIButton alloc] init];
        [b setTitle:@"+" forState:UIControlStateNormal];
        b.tag = [MusicManager sharedMusicManager].playIndexPlaylist.row;
        [((CenterViewController *)[AppDelegate sharedDelegate].controller.centerController).mainViewController download:b fromMusic:NO];
        [self.downLbl setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
        self.downLbl.tag = OK;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Трек поставлен на загрузку" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alert show];
        [self performSelector:@selector(dismissAlertView:) withObject:alert afterDelay:0.6];
    }
}

-(void)updateTime:(NSNotification*)note
{
    if(isTouch)
        return;
    NSNumber* time = [note.userInfo objectForKey:@"time"];
    currentTime = time.intValue;
    if(currentTime == 0 || durationTime == 0)
        return;
    int min = time.intValue/60;
    int sec = time.intValue%60;
    NSString *secondsString;
    if(sec < 10)
        secondsString = [NSString stringWithFormat:@"0%d",sec];
    else
    {
        secondsString = [NSString stringWithFormat:@"%d",sec];
    }
    self.musicTimeLbl.text = [NSString stringWithFormat:@"%d:%@",min,secondsString];
    self.sliderTime.value = (float)currentTime/(float)durationTime;
    //    if((durationTime - currentTime) == 1 && durationTime != 0)
    //    {
    //        if(repeatBtn.alpha == 1)
    //            [[MusicManager sharedMusicManager].audioPlayer seekToTime:kCMTimeZero];
    //        else
    //            [self nextSong:NO];
    //    }
}


-(void)itemIsFinished {
    if(repeatBtn.alpha == 1)
        [[MusicManager sharedMusicManager].audioPlayer seekToTime:kCMTimeZero];
    else
        [self nextSong:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)listAction:(UIButton*)sender {
    BOOL isShowing = playlist?YES:NO;
    NSInteger height = self.coverImage.frame.origin.y + self.coverImage.frame.size.height-54;
    if(isShowing) {
        [UIView animateWithDuration:0.5f animations:^{
            playlist.tableView.alpha = 0.1;
            playlist.tableView.frame = CGRectMake(0, -height, self.view.bounds.size.width, height);
        } completion:^(BOOL ok){
            playlist = nil;
            [[self.view viewWithTag:34] removeFromSuperview];
            return;
        }];
    }
    else {
        playlist = [[PlaylistTableViewController alloc] init];
        UITableView *table = playlist.tableView;
        table.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        table.tag = 34;
        table.alpha = 0.1;
        table.frame = CGRectMake(0, -height, self.view.bounds.size.width, height);
        [self.view addSubview:table];
        if([MusicManager sharedMusicManager].listPlayNames.count >[MusicManager sharedMusicManager].playIndexPlaylist.row ) {
            [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[MusicManager sharedMusicManager].playIndexPlaylist.row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
        [UIView animateWithDuration:0.5f animations:^{
            table.frame = CGRectMake(0, 54, self.view.bounds.size.width, height);
            table.alpha = 1;
        }];
    }
}

- (IBAction)textAction {
    [UIView animateWithDuration:0.3 animations:^{
        self.textTrackScroll.alpha = 1 -self.textTrackScroll.alpha;
    }];
    NSNumber *idA;
    if([MusicManager sharedMusicManager].listPlayLyrics.count > [MusicManager sharedMusicManager].playIndexPlaylist.row)
        idA = [[MusicManager sharedMusicManager].listPlayLyrics objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
    self.textTrackScroll.text = @"\n\n\n\n\n\n Текст трека не найден";
    if(idA.integerValue > 0)
        [self showTextOfTrack:idA];
}

- (IBAction)clickPlayResume
{
    if(self.playButton.tag == PAUSE)
    {
        self.playButton.tag = PLAY;
        [self.playButton setImage:[UIImage imageNamed:@"playMusic1.png"] forState:UIControlStateNormal];
        [[MusicManager sharedMusicManager] pauseMusic];
    }
    else if(self.playButton.tag == PLAY)
    {
        self.playButton.tag = PAUSE;
        [self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        [[MusicManager sharedMusicManager] resumeMusic];
    }
}

- (void)VKRequest:(VKRequest *)request
         response:(id)response
{
    NSLog(@"%@",request);
    if([request.signature isEqualToString:@"statusGet:"])
    {
        NSDictionary *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        if([idFriends isKindOfClass:[NSDictionary class]] && [idFriends objectForKey:@"audio"]){
            NSDictionary *audio = [idFriends objectForKey:@"audio"];
            self.nameLbl.text = [audio objectForKey:@"artist"];
            self.songLbl.text = [audio objectForKey:@"title"];
            self.url = [NSURL URLWithString:[audio objectForKey:@"url"]];
            [MusicManager sharedMusicManager].currentDuration = ((NSNumber*)[audio objectForKey:@"duration"]).intValue;
            
            [[MusicManager sharedMusicManager] playMusic:nil AndURL:self.url];
            if([MusicManager sharedMusicManager].statusMusic){
                VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                             initWithDelegate:self
                                             user:[VKUser currentUser]];
                NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSString *target = [NSString stringWithFormat:@"%@_%@",idU,idA];
                [rmLocal audioSetBroadcast:@{@"audio":target}];
            }
            return;
        }
    }
    else if ([request.signature isEqualToString:@"audioGetLyrics:"]) {
        NSDictionary *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        self.textTrackScroll.text = [idFriends objectForKey:@"text"];
    }
    else if ([request.signature isEqualToString:@"audioAdd:"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Трек успешно добавлен в ваши аудиозаписи ВК" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alert show];
        [self performSelector:@selector(dismissAlertView:) withObject:alert afterDelay:1];
        
    }
    else if ([request.signature isEqualToString:@"photosGetWallUploadServer:"]) {
        UIImage *yourImage= [self captureScreen];
        NSData *imageData = UIImagePNGRepresentation(yourImage);
        NSDictionary *postDictionary = [self sendPOSTRequest:[[response objectForKey:@"response"] objectForKey:@"upload_url"] withImageData:imageData];
        NSString *hash = [postDictionary objectForKey:@"hash"];
        NSString *photo = [postDictionary objectForKey:@"photo"];
        NSString *server = [postDictionary objectForKey:@"server"];
        VKRequestManager *rm = [[VKRequestManager alloc]
                                initWithDelegate:self
                                user:[VKUser currentUser]];
        rm.offlineMode = [AppDelegate sharedDelegate].offlineMode;
        [rm photosSaveWallPhoto:@{@"user_id":[NSString stringWithFormat:@"%lu",(unsigned long)[VKUser currentUser].accessToken.userID ] ,@"photo":photo,@"hash":hash,@"server":server}];
    }
    else if ([request.signature isEqualToString:@"photosSaveWallPhoto:"]) {
        NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
        NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
        NSDictionary *photoDict = [[response objectForKey:@"response"] lastObject];
        NSString *photoId = [photoDict objectForKey:@"id"];
        NSString *target = [NSString stringWithFormat:@"audio%@_%@,%@",idU,idA,photoId];
        VKRequestManager *rm = [[VKRequestManager alloc]
                                initWithDelegate:self
                                user:[VKUser currentUser]];
        rm.offlineMode = [AppDelegate sharedDelegate].offlineMode;
        [rm wallPost:@{@"owner_id":[NSString stringWithFormat:@"%lu",(unsigned long)[VKUser currentUser].accessToken.userID ],
                       @"message":@"#iOS_плеер",
                       @"attachments":target}];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Надпись размещена!" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alert show];
        [self performSelector:@selector(dismissAlertView:) withObject:alert afterDelay:0.6];
    }
    return;
}

- (NSDictionary *)sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:reqURl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:60.0];
    [request setHTTPMethod:@"POST"];
    
    [request addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];
    
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    NSString *stringBoundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@",uuidString];
    NSString *endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data;  boundary=%@", stringBoundary];
    
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"%@",endItemBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if(responseData)
    {
        NSError* error;
        NSDictionary* dict = [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:kNilOptions
                              error:&error];
        
        NSString *errorMsg = [[dict objectForKey:@"error"] objectForKey:@"error_msg"];
        
        NSLog(@"Server response: %@ \nError: %@", dict, errorMsg);
        
        return dict;
    }
    return nil;
}


- (UIImage *) captureScreen {
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (NULL != &UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
    {
        // -renderInContext: renders in the coordinate space of the layer,
        // so we must first apply the layer's geometry to the graphics context
        CGContextSaveGState(context);
        // Center the context around the window's anchor point
        CGContextTranslateCTM(context, [window center].x, [window center].y);
        // Apply the window's transform about the anchor point
        CGContextConcatCTM(context, [window transform]);
        // Offset by the portion of the bounds left of and above the anchor point
        CGContextTranslateCTM(context,
                              -[window bounds].size.width * [[window layer] anchorPoint].x,
                              -[window bounds].size.height * [[window layer] anchorPoint].y);
        
        // Render the layer hierarchy to the current context
        [[window layer] renderInContext:context];
        
        // Restore the context
        CGContextRestoreGState(context);
    }
    
    // Retrieve the screenshot image
    UIImage *imageForEmail = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imageForEmail;
}

-(void)dismissAlertView:(UIAlertView *)alertView{
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (IBAction)nextSong:(BOOL)user {
    [serialQueue addOperationWithBlock:^{
        if([[AppDelegate sharedDelegate].dateForAutoSleep compare:[NSDate date]] == NSOrderedAscending)
        {
            [AppDelegate sharedDelegate].dateForAutoSleep = nil;
            return;
        }
        currentTime = 0;
        if([MusicManager sharedMusicManager].listPlayUrl.count){
            NSInteger currentIndex  = [MusicManager sharedMusicManager].playIndexPlaylist.row+1;
            if(currentIndex >= [MusicManager sharedMusicManager].listPlayNames.count)
                currentIndex = 0;
            [[MusicManager sharedMusicManager] playMusic:[NSIndexPath indexPathForRow:currentIndex inSection:[MusicManager sharedMusicManager].playIndexPlaylist.section] AndURL:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.countLbl.text = [NSString stringWithFormat:@"%ld из %lu",[MusicManager sharedMusicManager].playIndexPlaylist.row+1,(unsigned long)[MusicManager sharedMusicManager].listPlayNames.count];
                UITableView *table = (UITableView*)[self.view viewWithTag:34];
                if(table){
                    [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[MusicManager sharedMusicManager].playIndexPlaylist.row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    [table reloadData];
                }
            });
            
        }
        
        if([MusicManager sharedMusicManager].stateOfMusic == status)
        {
            VKRequestManager *rm = [[VKRequestManager alloc]
                                    initWithDelegate:self
                                    user:[VKUser currentUser]];
            rm.startAllRequestsImmediately = NO;
            NSNumber* uid = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
            VKRequest *s = [rm statusGet:@{@"uid":uid}];
            s.cacheLiveTime = VKCacheLiveTimeNever;
            [s start];
            rm.startAllRequestsImmediately = YES;
            return;
        }
        if([MusicManager sharedMusicManager].statusMusic){
            VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                         initWithDelegate:self
                                         user:[VKUser currentUser]];
            rmLocal.offlineMode = [AppDelegate sharedDelegate].offlineMode;
            if([MusicManager sharedMusicManager].listPlayIdAudio.count != 0){
                NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSString *target = [NSString stringWithFormat:@"%@_%@",idU,idA];
                [rmLocal audioSetBroadcast:@{@"audio":target}];
            }
        }
    }];
    
}


- (IBAction)prevSong {
    currentTime = 0;
    [serialQueue cancelAllOperations];
    [serialQueue addOperationWithBlock:^{
        if([MusicManager sharedMusicManager].listPlayUrl.count){
            NSInteger row = [MusicManager sharedMusicManager].playIndexPlaylist.row-1;
            NSIndexPath* lastSong = [NSIndexPath indexPathForRow:row<0?[MusicManager sharedMusicManager].listPlayUrl.count-1:row inSection:[MusicManager sharedMusicManager].playIndexPlaylist.section];
            [[MusicManager sharedMusicManager] playMusic:lastSong AndURL:nil];
            UITableView *table = (UITableView*)[self.view viewWithTag:34];
            dispatch_async(dispatch_get_main_queue(), ^{
                [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[MusicManager sharedMusicManager].playIndexPlaylist.row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                [table reloadData];
            });
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.countLbl.text = [NSString stringWithFormat:@"%ld из %lu",(long)[MusicManager sharedMusicManager].playIndexPlaylist.row+1,(unsigned long)[MusicManager sharedMusicManager].listPlayNames.count];
        });
        if([MusicManager sharedMusicManager].statusMusic){
            VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                         initWithDelegate:self
                                         user:[VKUser currentUser]];
            rmLocal.offlineMode = [AppDelegate sharedDelegate].offlineMode;
            if([MusicManager sharedMusicManager].listPlayIdAudio.count != 0){
                NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSString *target = [NSString stringWithFormat:@"%@_%@",idU,idA];
                [rmLocal audioSetBroadcast:@{@"audio":target}];
            }
        }
    }];
}

-(void)changedFone
{
    [serialQueue addOperationWithBlock:^{
        if(!viewImage) {
            viewImage = [[UIImageView alloc] init];
            viewImage.frame = self.view.frame;
            viewImage.alpha = kALPHA;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view addSubview:viewImage ];
                [self.view sendSubviewToBack:viewImage ];
            });
        }
        if(tempImg){
            dispatch_async(dispatch_get_main_queue(), ^{
                viewImage.image = tempImg;
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                viewImage.image = blurImage;
            });
        }
        viewImage.parallaxIntensity = 20;
    }];
}

- (IBAction)sliderValueChanged:(UISlider*)sender {
    if(sender.tag == VOLUME){
        [[MusicManager sharedMusicManager] setVolume:self.slider.value];
    }
    else
    {
        float position = durationTime*sender.value;
        int min = position/60;
        int sec = (int)position%60;
        NSString *secondsString;
        if(sec < 10)
            secondsString = [NSString stringWithFormat:@"0%d",sec];
        else
        {
            secondsString = [NSString stringWithFormat:@"%d",sec];
        }
        self.musicTimeLbl.text = [NSString stringWithFormat:@"%d:%@",min,secondsString];
    }
}

- (IBAction)sliderTime:(UISlider *)sender {
    [[MusicManager sharedMusicManager] skipToSeconds:sender.value];
    NSUInteger duration = 1;
    if([MusicManager sharedMusicManager].isOnline)
        duration = 2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isTouch = NO;
    });
}

- (IBAction)repeatAction:(UIButton*)sender{
    if(sender == randomBtn) {
        if(sender.tag == REMOVE) {
            if([MusicManager sharedMusicManager].stateOfMusic == home ) {
                if([MusicManager sharedMusicManager].listPlayIdAudio.count == 0)
                    return;
                if([MusicManager sharedMusicManager].listPlayIdAudio.count == 0)
                    return;
                UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Удаление" message:@"Вы уверены, что хотите удалить трек?" delegate:self cancelButtonTitle:@"Удалить" otherButtonTitles:@"Нет", nil];
                deleteAlert.tag = 74;
                [deleteAlert show];
            }
            else {
                VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                             initWithDelegate:self
                                             user:[VKUser currentUser]];
                NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                [rmLocal audioDelete:@{@"audio_id":idA,@"owner_id":idU}];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Трек успешно удален" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [alert show];
                [self performSelector:@selector(dismissAlertView:) withObject:alert afterDelay:0.6];
                [randomBtn setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
                randomBtn.tag = OK;
            }
            return;
        }
        if([MusicManager sharedMusicManager].listPlayIdAudio.count != 0 && sender.tag != OK){
            VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                         initWithDelegate:self
                                         user:[VKUser currentUser]];
            NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
            NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
            [rmLocal audioAdd:@{@"audio_id":idA,@"owner_id":idU}];
            [randomBtn setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
            randomBtn.tag = OK;
        }
    }
    else {
        float alpha = (sender.alpha==1.0f)?0.4f:1.0f ;
        sender.alpha = alpha;
    }
}

- (IBAction)actionMusic{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Выберите действие" delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:@"Отправить на стену",@"Скопировать ссылку",@"Открыть в",@"Переименовать",@"Найти обложки для всех треков",@"Удалить все обложки", nil];
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self postVK];
            break;
        case 1:
            [self copyPast];
            break;
        case 2:
            [self share];
            break;
        case 3:
            [self rename];
            break;
        case 5:
            [[SDImageCache sharedImageCache] clearDisk];
            [[SDImageCache sharedImageCache] clearMemory];
            break;
        case 4:
            self.coverProgress.hidden = NO;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[MusicManager sharedMusicManager] saveAllAlbumCoverFromWiFiWithCallback:^(double percent){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(percent == -1.) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Превышен лимит запросов" message:@"Для продолжения поиска Вам нужно перезапустить приложение и выбрать поиск обложек снова" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alert show];
                            self.coverProgress.hidden = YES;
                        }
                        else if(percent >= 0.98) {
                            self.coverProgress.hidden = YES;
                        }
                        self.coverProgress.progress = percent;
                    });
                }];
            });
            break;
    }
}

- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)sender{
    if ([sender isEqual:self.lpgr] && ![MusicManager sharedMusicManager].isOnline) {
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Плейлист для перемещения" delegate:self cancelButtonTitle:@"Отмена" otherButtonTitles:nil];
            alert.tag = 1244;
            for(Album *al in [[AppDelegate sharedDelegate] getAllAlbum]) {
                [alert addButtonWithTitle:al.name];
            }
            [alert show];
        }
    }
}

-(void)rename {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Переименование" message:@"Введите новые данные для трека" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [av setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    
    // Alert style customization
    [[av textFieldAtIndex:1] setSecureTextEntry:NO];
    [[av textFieldAtIndex:0] setPlaceholder:@"Исполнитель"];
    [[av textFieldAtIndex:1] setPlaceholder:@"Название трека"];
    [av show];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 1244) {
        if(buttonIndex != [alertView cancelButtonIndex]) {
            NSString *nameAlbum = [alertView buttonTitleAtIndex:buttonIndex];
            Album * al = [[AppDelegate sharedDelegate] albumByName:nameAlbum];
            NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
            NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
            Music * music = [[AppDelegate sharedDelegate] musicByIdAudio:idA andIdUser:idU];
            music.album = al;
            [al addTracksObject:music];
            [[AppDelegate sharedDelegate].defaultManagedObjectContext save:nil];
        }
        return;
    }
    if(alertView.tag == 123 && buttonIndex == [alertView cancelButtonIndex]) {
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].defaultManagedObjectContext;
        Album *album = [NSEntityDescription
                        insertNewObjectForEntityForName:@"Album"
                        inManagedObjectContext:context];
        album.name = [alertView textFieldAtIndex:0].text;
        [context save:nil];
        return;
    }
    if(alertView.tag == 74) {
        if(buttonIndex == [alertView cancelButtonIndex]) {
            NSInteger idx = [MusicManager sharedMusicManager].playIndexPlaylist.row;
            [[AppDelegate sharedDelegate] deleteMusicByIdAudio:[[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:idx] idUser:[[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:idx]];
            [[MusicManager sharedMusicManager].listPlayIdAudio removeObjectAtIndex:idx];
            [[MusicManager sharedMusicManager].listPlayIdUser removeObjectAtIndex:idx];
            [[MusicManager sharedMusicManager].listPlayDuration removeObjectAtIndex:idx];
            [[MusicManager sharedMusicManager].listPlayLyrics removeObjectAtIndex:idx];
            [[MusicManager sharedMusicManager].listPlayNames removeObjectAtIndex:idx];
            [[MusicManager sharedMusicManager].listPlaySongs removeObjectAtIndex:idx];
            [[MusicManager sharedMusicManager].listPlayUrl removeObjectAtIndex:idx];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Трек успешно удален" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [alert show];
            [self performSelector:@selector(dismissAlertView:) withObject:alert afterDelay:0.6];
            [self nextSong:YES];
        }
        return;
    }
    
    if(buttonIndex == [alertView cancelButtonIndex]) return;
    NSString *newName =  [alertView textFieldAtIndex:0].text;
    NSString *newSong = [alertView textFieldAtIndex:1].text;
    NSInteger row = [MusicManager sharedMusicManager].playIndexPlaylist.row;
    NSString *unique = [[NSString stringWithFormat:@"%@-%@",[MusicManager sharedMusicManager].listPlayNames[row],[MusicManager sharedMusicManager].listPlaySongs[row]] stringByAppendingString:@".mp3"];
    unique = [unique stringByReplacingOccurrencesOfString:@"/" withString:@" "];
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    documents = [documents stringByAppendingPathComponent:@"Music/"];
    NSString *filePath = [documents stringByAppendingPathComponent:unique];
    
    NSString *uniqueNew = [[NSString stringWithFormat:@"%@-%@",newName,newSong] stringByAppendingString:@".mp3"];
    uniqueNew = [uniqueNew stringByReplacingOccurrencesOfString:@"/" withString:@" "];
    NSString *newPath = [documents stringByAppendingPathComponent:uniqueNew];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newPath error:&error];
    
    self.nameLbl.text = newName;
    self.songLbl.text = newSong;
    [MusicManager sharedMusicManager].listPlayNames[row] = newName;
    [MusicManager sharedMusicManager].listPlaySongs[row] = newSong;
    [[AppDelegate sharedDelegate] musicByIdAudio:[MusicManager sharedMusicManager].listPlayIdAudio[row] andIdUser:[MusicManager sharedMusicManager].listPlayIdUser[row] RenameWithNewName:newName AndNewSong:newSong];
}


-(void)copyPast {
    NSString *copyStringverse = ((NSURL*)[MusicManager sharedMusicManager].listPlayUrl[[MusicManager sharedMusicManager].playIndexPlaylist.row]).description;
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:copyStringverse];
}

-(void)postVK {
    VKRequestManager *rm = [[VKRequestManager alloc]
                            initWithDelegate:self
                            user:[VKUser currentUser]];
    rm.offlineMode = [AppDelegate sharedDelegate].offlineMode;
    [rm photosGetWallUploadServer:nil];
}

-(void)share {
    if([MusicManager sharedMusicManager].isOnline) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Действие недоступно для онлайн-прослушивания" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSURL *fileURL = [MusicManager sharedMusicManager].listPlayUrl[[MusicManager sharedMusicManager].playIndexPlaylist.row];
    _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    
    [_documentInteractionController presentOpenInMenuFromRect:CGRectMake(0, 0, 0, 0) inView:self.view animated: YES];
}

-(void)shuffle {
    NSInteger row = [MusicManager sharedMusicManager].playIndexPlaylist.row;
    NSMutableArray *tmpArray1 = [NSMutableArray arrayWithObject:[MusicManager sharedMusicManager].listPlayNames[row]];
    NSMutableArray *tmpArray2 = [NSMutableArray arrayWithObject:[MusicManager sharedMusicManager].listPlaySongs[row]];
    NSMutableArray *tmpArray3 = [NSMutableArray arrayWithObject:[MusicManager sharedMusicManager].listPlayIdAudio[row]];
    NSMutableArray *tmpArray4 = [NSMutableArray arrayWithObject:[MusicManager sharedMusicManager].listPlayIdUser[row]];
    NSMutableArray *tmpArray5 = [NSMutableArray arrayWithObject:[MusicManager sharedMusicManager].listPlayDuration[row]];
    NSMutableArray *tmpArray6 = [NSMutableArray arrayWithObject:[MusicManager sharedMusicManager].listPlayLyrics[row]];
    NSMutableArray *tmpArray7 = [NSMutableArray arrayWithObject:[MusicManager sharedMusicManager].listPlayUrl[row]];
    for (NSInteger i = 1; i < [MusicManager sharedMusicManager].listPlayNames.count; i++) {
        NSUInteger randomPos = arc4random()%([tmpArray1 count])+1;
        id obj1 = [MusicManager sharedMusicManager].listPlayNames[i];
        [tmpArray1 insertObject:obj1?obj1:@"" atIndex:randomPos];
        id obj2 = [MusicManager sharedMusicManager].listPlaySongs[i];
        [tmpArray2 insertObject:obj2?obj2:@"" atIndex:randomPos];
        id obj3 = [MusicManager sharedMusicManager].listPlayIdAudio[i];
        [tmpArray3 insertObject:obj3?obj3:@"" atIndex:randomPos];
        id obj4 = [MusicManager sharedMusicManager].listPlayIdUser[i];
        [tmpArray4 insertObject:obj4?obj4:@"" atIndex:randomPos];
        
        id obj5 = [MusicManager sharedMusicManager].listPlayDuration[i];
        [tmpArray5 insertObject:obj5?obj5:@"" atIndex:randomPos];
        
        id obj6 = [MusicManager sharedMusicManager].listPlayLyrics[i];
        [tmpArray6 insertObject:obj6?obj6:@"" atIndex:randomPos];
        id obj7 = [MusicManager sharedMusicManager].listPlayUrl[i];
        [tmpArray7 insertObject:obj7?obj7:@"" atIndex:randomPos];
    }
    [MusicManager sharedMusicManager].listPlayNames = tmpArray1;
    [MusicManager sharedMusicManager].listPlaySongs = tmpArray2;
    [MusicManager sharedMusicManager].listPlayIdAudio = tmpArray3;
    [MusicManager sharedMusicManager].listPlayIdUser = tmpArray4;
    [MusicManager sharedMusicManager].listPlayDuration = tmpArray5;
    [MusicManager sharedMusicManager].listPlayLyrics = tmpArray6;
    [MusicManager sharedMusicManager].listPlayUrl = tmpArray7;
    [MusicManager sharedMusicManager].playIndexPlaylist = nil;
    [AppDelegate sharedDelegate].musicViewController.countLbl.text = [NSString stringWithFormat:@"1 из %lu",(unsigned long)[MusicManager sharedMusicManager].listPlayNames.count];
    UITableView *table = (UITableView*)[self.view viewWithTag:34];
    [table reloadData];
}

-(void)showTextOfTrack:(NSNumber*)idTrack {
    VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                 initWithDelegate:self
                                 user:[VKUser currentUser]];
    rmLocal.offlineMode = [AppDelegate sharedDelegate].offlineMode;
    if([MusicManager sharedMusicManager].listPlayIdAudio.count != 0){
        
        [rmLocal audioGetLyrics:@{@"lyrics_id":idTrack}];
    }
}

- (IBAction)deallocSelf {
    [[AppDelegate sharedDelegate].navController popViewControllerAnimated:YES];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
