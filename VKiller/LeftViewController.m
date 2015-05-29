//
//  LeftViewController.m
//  VKiller
//
//  Created by yury.mehov on 12/2/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import "LeftViewController.h"
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CDActivityIndicatorView.h"
#import "SettingsViewController.h"
#import "CenterViewController.h"
#import "NGAParallaxMotion.h"

@interface LeftViewController ()
{
    ViewController *centerViewController;
    VKRequestManager *rm;
    UIWebView *webView;
    UIImageView *view;
    UIAlertView *alertView;
    NSMutableArray *menuArray;
    
    int durationTime;
}
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UILabel *musicViewName;
@property (weak, nonatomic) IBOutlet UILabel *musicViewSong;
@property (weak, nonatomic) IBOutlet UILabel *musicViewDuration;
@property (weak, nonatomic) IBOutlet UILabel *musicProgress;

@end

@implementation LeftViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        menuArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"menu"] mutableCopy ];
        if(!menuArray) {
            menuArray = [@[@"Моя музыка",@"Популярное",@"Рекомендации",
                       @"Музыка друзей",@"Музыка групп",@"Музыка новостей",@"Музыка стены",@"Cтена групп",@"Сейчас играет",@"Альбомы",@"Загруженное",@"Плейлисты"] mutableCopy];
        }
    }
    return self;
}

- (void)     VKRequest:(VKRequest *)request
connectionErrorOccured:(NSError *)error {
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
    UIImage *inputImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:filePath]]];
    
    self.ava.layer.masksToBounds = YES;
    self.ava.layer.cornerRadius = self.ava.frame.size.height/2;
    self.ava.image = inputImage;
    [self changedFone];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Set AudioSession
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    centerViewController = ((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).mainViewController;
    
    rm = [[VKRequestManager alloc]
          initWithDelegate:self
          user:[VKUser currentUser]];
    rm.offlineMode = YES;
    [rm info];
    [self musicHome];
    
    
//    webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://vk.com/public34752121"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:1];
//    webView.hidden = YES;
//    webView.delegate = self;
//    [self.view addSubview:webView];
//    [webView loadRequest:request];
    [self changedFone];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedFone) name:POST_CHANGED_FONE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDuration:) name:@"DURATION" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTime:) name:@"TIME" object:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UISwipeGestureRecognizer *swipeGestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    [swipeGestureRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.musicView addGestureRecognizer: swipeGestureRight];
    
    UISwipeGestureRecognizer *swipeGestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    [swipeGestureLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.musicView addGestureRecognizer: swipeGestureLeft];
    
    self.menuTableView.frame = CGRectMake(0, self.menuTableView.frame.origin.y, self.menuTableView.frame.size.width, self.menuTableView.frame.size.height + self.musicView.frame.size.height);
}

- (void) didSwipe:(UISwipeGestureRecognizer *)recognizer{
    if([recognizer direction] == UISwipeGestureRecognizerDirectionLeft){
        [[AppDelegate sharedDelegate].musicViewController nextSong:NO];
    }else{
        [[AppDelegate sharedDelegate].musicViewController prevSong];
    }
}

-(void)updateTime:(NSNotification*)note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *num = [note.userInfo objectForKey:@"time"];
        if(durationTime > 0){
            float buf = ((float)num.intValue/(float)durationTime);
            self.musicProgress.frame = CGRectMake(0, 0, self.musicProgress.superview.frame.size.width*buf, 3);
        }
    });
}


-(void)updateDuration:(NSNotification*)note
{
    if(self.musicView.alpha == 0) {
    [UIView animateWithDuration:1 animations:^{
        self.musicViewDuration.superview.alpha = 1;
        self.musicViewDuration.alpha = 1;
        self.musicViewName.alpha = 1;
        self.musicViewSong.alpha = 1;
        self.menuTableView.frame = CGRectMake(0, self.menuTableView.frame.origin.y, self.menuTableView.frame.size.width, self.menuTableView.frame.size.height - self.musicView.frame.size.height);
    }];
    }
    NSNumber* duration = [note.userInfo objectForKey:@"duration"];
    NSString *artist = [[MusicManager sharedMusicManager] currentMusicArtist];
    NSString *title = [[MusicManager sharedMusicManager] currentMusicName];
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
        self.musicViewDuration.text = [NSString stringWithFormat:@"%d:%@",min,secondsString];
    if(artist )
        self.musicViewName.text = title;
    if(title)
        self.musicViewSong.text = artist;
    self.playBtn.tag = PAUSE;
    [self.playBtn setImage:[UIImage imageNamed:@"left_audio_hlstop_2x.png"] forState:UIControlStateNormal];
    
}
- (IBAction)playResumeAction {
    if(self.playBtn.tag == PAUSE)
    {
        self.playBtn.tag = PLAY;
        [self.playBtn setImage:[UIImage imageNamed:@"left_audio_hl@2x.png"] forState:UIControlStateNormal];
        [[MusicManager sharedMusicManager] pauseMusic];
    }
    else if(self.playBtn.tag == PLAY)
    {
        self.playBtn.tag = PAUSE;
        [self.playBtn setImage:[UIImage imageNamed:@"left_audio_hlstop_2x.png"] forState:UIControlStateNormal];
        [[MusicManager sharedMusicManager] resumeMusic];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    BOOL isPLaying = [[MusicManager sharedMusicManager].audioPlayer isPlaying];
    self.playBtn.tag = isPLaying? PAUSE:PLAY;
    if(isPLaying ) {
        [self.playBtn setImage:[UIImage imageNamed:@"left_audio_hlstop_2x.png"] forState:UIControlStateNormal];
    }
    else {
        [self.playBtn setImage:[UIImage imageNamed:@"left_audio_hl@2x.png"] forState:UIControlStateNormal];
    }
    view.frame = self.view.frame;
    
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    view.frame = self.view.frame;
}

-(void)changedFone
{
    if(view){
        [view removeFromSuperview];
        view = nil;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"fone.jpg"];
    if(imagePath){
        UIImage *tempImg = [UIImage imageWithContentsOfFile:imagePath];
        view = [[UIImageView alloc] initWithImage:tempImg];
        if(tempImg){
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            view.image = image;
        }
        else view.image = [self.ava.image applyDarkEffect];//[UIImage imageNamed:@"back1.jpg"];
    }
    view.frame = self.view.frame;
    view.alpha = kALPHA;
    [self.view addSubview:view ];
    [self.view sendSubviewToBack:view ];
}

- (void)webViewDidFinishLoad:(UIWebView *)webViews
{
    NSString *loadUsernameJS = [NSString stringWithFormat:@"document.getElementsByClassName('button wide_button')[0].click();"];
    //NSString *likePost = [NSString stringWithFormat:@"document.getElementsByClassName('item_like _i')[0].click();"];
    
    [webView stringByEvaluatingJavaScriptFromString: loadUsernameJS];
    //[webView stringByEvaluatingJavaScriptFromString: likePost];
}

- (void)VKRequest:(VKRequest *)request
         response:(id)response
{
    if([request.signature isEqualToString:@"friendsGet:"])
    {
        centerViewController.names = [NSMutableArray array];
        centerViewController.songs = [NSMutableArray array];
        centerViewController.idUser = [NSMutableArray array];
        centerViewController.idAudio = [NSMutableArray array];
        centerViewController.duration = [NSMutableArray array];
        [AppDelegate sharedDelegate].urls = [NSMutableArray array];
        NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        VKRequestManager *manager;
        VKRequest *req ;
        for(NSDictionary* idUser in idFriends){
            manager = [[VKRequestManager alloc] initWithDelegate:centerViewController user:[VKUser currentUser]];
            manager.startAllRequestsImmediately = NO;
            req.delegate = centerViewController;
            req = [[VKRequest alloc] init];
            req = [manager statusGet:@{@"uid":[idUser objectForKey:@"uid"]}];
            [req start];
            
        }
    }
    else{
        NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        NSString *url;
        NSString *name;
        NSString *lastName;
        for(NSDictionary* idUser in idFriends){
            url = [idUser objectForKey:@"photo_100"];
            name =[idUser objectForKey:@"first_name"];
            lastName = [idUser objectForKey:@"last_name"];
        }
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
        UIImage *inputImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
        if(!inputImage) {
            
             inputImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath]];
        }
        else {
            [UIImagePNGRepresentation(inputImage) writeToFile:filePath atomically:YES];
        }
        
        self.ava.layer.masksToBounds = YES;
        self.ava.layer.cornerRadius = self.ava.frame.size.height/2;
        self.ava.image = inputImage;
        
        
        NSString *nameText = [NSString stringWithFormat:@"%@ %@",name,lastName];
        self.nameLbl.text = nameText;
        [[NSNotificationCenter defaultCenter] postNotificationName:POST_CHANGED_FONE object:nil];
    }
}

-(void)showAnimation
{
    centerViewController.activityIndicatorView = [[CDActivityIndicatorView alloc] initWithImage:[UIImage imageNamed:@"activity.png"]];
    centerViewController.activityIndicatorView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    centerViewController.activityIndicatorView.layer.cornerRadius = 20;
    centerViewController.activityIndicatorView.center = self.view.center;
    
    [self.view.superview addSubview:centerViewController.activityIndicatorView];
    
    [centerViewController.activityIndicatorView startAnimating];
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSString *stringToMove = menuArray[sourceIndexPath.row];
    [menuArray removeObjectAtIndex:sourceIndexPath.row];
    [menuArray insertObject:stringToMove atIndex:destinationIndexPath.row];
    
    [[NSUserDefaults standardUserDefaults] setObject:menuArray forKey:@"menu"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] init];
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"Color"];
        
        if(colorData){
            UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
            cell.textLabel.textColor = color;
        }
        else{
            cell.textLabel.textColor = [UIColor whiteColor];
        }
        UIView *bgView = [[UIView alloc] init];
        [bgView setBackgroundColor:[[UIColor grayColor] colorWithAlphaComponent:0.2]];
        cell.selectedBackgroundView = bgView;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:18];
    }
    NSString *textOfLabel = menuArray[indexPath.row];
    cell.textLabel.text = textOfLabel;
    
    if([textOfLabel isEqualToString:@"Моя музыка"]) {
        cell.imageView.image = [UIImage imageNamed:@"ic_play.png"];
    }
    else if([textOfLabel isEqualToString:@"Популярное"]) {
        cell.imageView.image = [UIImage imageNamed:@"ic_love.png"];
    }
  
    else if([textOfLabel isEqualToString:@"Рекомендации"]) {
        cell.imageView.image = [UIImage imageNamed:@"iconstar.png"];
    }
    else if([textOfLabel isEqualToString:@"Музыка друзей"]) {
        cell.imageView.image = [UIImage imageNamed:@"iconfrend.png"];
    }
    else if([textOfLabel isEqualToString:@"Музыка новостей"]) {
        cell.imageView.image = [UIImage imageNamed:@"iconnews.png"];
    }
    else if([textOfLabel isEqualToString:@"Музыка стены"]) {
        cell.imageView.image = [UIImage imageNamed:@"7"];
    }
    else if([textOfLabel isEqualToString:@"Музыка групп"]) {
        cell.imageView.image = [UIImage imageNamed:@"icongro.png"];
    }
    else if([textOfLabel isEqualToString:@"Cтена групп"]) {
        cell.imageView.image = [UIImage imageNamed:@"9"];
    }
    else if([textOfLabel isEqualToString:@"Сейчас играет"]) {
        cell.imageView.image = [UIImage imageNamed:@"iconmic.png"];
    }
    else if([textOfLabel isEqualToString:@"Альбомы"]) {
        cell.imageView.image = [UIImage imageNamed:@"iconal.png"];
    }
    else if([textOfLabel isEqualToString:@"Загруженное"]) {
        cell.imageView.image = [UIImage imageNamed:@"icondownmenu.png"];
    }
    else if([textOfLabel isEqualToString:@"Плейлисты"]) {
        cell.imageView.image = [UIImage imageNamed:@"iconlist.png"];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if([cell.textLabel.text isEqualToString:@"Моя музыка"]) {
        [self myMusic];
    }
    if([cell.textLabel.text isEqualToString:@"Популярное"]) {
        [self musicDashboard];
    }
    if([cell.textLabel.text isEqualToString:@"Поиск"]) {
        [self musicSearch];
    }
    if([cell.textLabel.text isEqualToString:@"Рекомендации"]) {
        [self reccomended];
    }
    if([cell.textLabel.text isEqualToString:@"Музыка друзей"]) {
        [self musicFriends];
    }
    if([cell.textLabel.text isEqualToString:@"Музыка новостей"]) {
        [self musicNews];
    }
    if([cell.textLabel.text isEqualToString:@"Музыка стены"]) {
        [self musicWall];
    }
    if([cell.textLabel.text isEqualToString:@"Музыка групп"]) {
        [self musicGroups];
    }
    if([cell.textLabel.text isEqualToString:@"Cтена групп"]) {
        [self musicGroupsWall];
    }
    if([cell.textLabel.text isEqualToString:@"Сейчас играет"]) {
        [self addToFriend];
    }
    if([cell.textLabel.text isEqualToString:@"Альбомы"]) {
        [self musicAlbum];
    }
    if([cell.textLabel.text isEqualToString:@"Загруженное"]) {
        [self musicHome];
    }
    if([cell.textLabel.text isEqualToString:@"Плейлисты"]) {
        [self album];
    }
    
    if([cell.textLabel.text isEqualToString:@"Плейлисты"]){
        ((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).shuffleBtn.tag = 123;
        [((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).shuffleBtn setImage:[UIImage imageNamed:@"audioplayer_add.png"] forState:UIControlStateNormal];
    }
    else {
        ((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).shuffleBtn.tag = 1;
        [((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).shuffleBtn setImage:[UIImage imageNamed:@"random.png"] forState:UIControlStateNormal];
    }
    
    ((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).titleLabel.text = menuArray[indexPath.row];
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return menuArray.count;
}


-(void)musicNews {
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    if(centerViewController.stateOfMusic == news)
        return;
    [self showAnimation];
    [centerViewController changeView:news];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    [rm newsfeedGet:@{@"filters":@"post"}];
}

-(void)musicWall {
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    if(centerViewController.stateOfMusic == wall)
        return;
    [self showAnimation];
    [centerViewController changeView:wall];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    [rm wallGet:@{@"count":@"100"}];
}

- (IBAction)myMusic {
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    if(centerViewController.stateOfMusic == myMusic)
        return;
    [self showAnimation];
    [centerViewController changeView:myMusic];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    rm.startAllRequestsImmediately = NO;
    VKRequest *s = [rm audioGet:@{@"need_user":@"0",@"count":@1500}];
    s.cacheLiveTime = VKCacheLiveTimeNever;
    [s start];
    rm.startAllRequestsImmediately = YES;
}

- (IBAction)musicDashboard {
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    if(centerViewController.stateOfMusic == dashboard)
        return;
    [self showAnimation];
    [centerViewController changeView:dashboard];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    [rm audioGetPopular:@{@"count":@"300"}];
}

- (IBAction)musicSearch {
    if(centerViewController.stateOfMusic == search)
        return;
    
    [centerViewController changeView:search];
}
- (IBAction)reccomended {
    if(![MusicManager sharedMusicManager].playIndexPlaylist || [MusicManager sharedMusicManager].listPlayIdAudio.count <= [MusicManager sharedMusicManager].playIndexPlaylist.row)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Выберите трек и попробуйте снова" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    if(centerViewController.stateOfMusic == recommend)
        return;
    [self showAnimation];
    [centerViewController changeView:recommend];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
    NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
    NSString *target = [NSString stringWithFormat:@"%@_%@",idU,idA];
    [rm audioGetRecommendations:@{@"target_audio":target,@"shuffle":@"1"}];
    
}
- (IBAction)musicFriends {
    [centerViewController changeView:friends];
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    [self showAnimation];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    [rm friendsGet:@{@"fields":@"nickname,photo_50",@"order":@"hints"}];
}

- (IBAction)musicGroups {
    [centerViewController changeView:group];
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    [self showAnimation];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    [rm groupsGet:@{@"count":@"1000",@"extended":@"1"}];
}

-(void)musicGroupsWall {
    [centerViewController changeView:groupWall];
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    [self showAnimation];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    [rm groupsGet:@{@"count":@"1000",@"extended":@"1"}];
}

-(void)album {
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    [centerViewController changeView:playlist];
    ((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).shuffleBtn.tag = 123;
    [((CenterViewController*)[AppDelegate sharedDelegate].controller.centerController).shuffleBtn setImage:[UIImage imageNamed:@"audioplayer_add.png"] forState:UIControlStateNormal];
    [centerViewController playlistMode];
}

- (IBAction)musicAlbum {
    [centerViewController changeView:album];
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    [self showAnimation];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    [rm audioGetAlbums:@{@"count":@"100"}];
}

- (IBAction)addToFriend {
    [centerViewController changeView:status];
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    [self showAnimation];
    rm = [[VKRequestManager alloc]
          initWithDelegate:centerViewController
          user:[VKUser currentUser]];
    //[rm friendsGet:@{@"fields":@"uid"}];
    rm.startAllRequestsImmediately = NO;
    VKRequest *s = [rm audioGetBroadcastList:@{@"active":@"1"}];
    s.cacheLiveTime = VKCacheLiveTimeNever;
    [s start];
    rm.startAllRequestsImmediately = YES;
    
}

- (IBAction)musicHome {
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    if(centerViewController.stateOfMusic == home)
        return;
    [centerViewController changeView:home];
    [centerViewController offlineMode];
}

- (IBAction)logout {
    if(self.settingsBtn.tag == 2) {
        self.settingsBtn.tag = 1;
        [self.settingsBtn setImage:nil forState:UIControlStateNormal];
        [self.menuTableView setEditing:NO animated:YES];
        return;
    }
    alertView = [[UIAlertView alloc] initWithTitle:self.nameLbl.text
                                           message:@"Выберите действие" delegate:self
                                 cancelButtonTitle:@"Отмена"
                                 otherButtonTitles: @"Выйти",nil];
    alertView.tag = 1;
    [alertView addButtonWithTitle:@"Очистить всю музыку"];
    [alertView addButtonWithTitle:@"Изменить порядок меню"];
    [alertView addButtonWithTitle:@"Настройки"];
    [alertView show];
}

-     (void)alertView:(UIAlertView *)_alertView
 clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(_alertView.tag == 1){
        switch (buttonIndex){
            case 1:
                [self logoutAction];
                break;
            case 2:
                alertView = [[UIAlertView alloc] initWithTitle:self.nameLbl.text
                                                       message:@"Уверены?" delegate:self
                                             cancelButtonTitle:@"Да"
                                             otherButtonTitles: @"Нет",nil];
                alertView.tag = 2;
                [alertView show];
                break;
            case 3:
                [self.menuTableView setEditing:YES animated:YES];
                [self.settingsBtn setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
                self.settingsBtn.tag = 2;
                break;
            case 4:
                [self showSettings];
                break;
            case 0:
                break;
        }
    }
    else{
        if(buttonIndex == [_alertView cancelButtonIndex]){
            [[AppDelegate sharedDelegate] deleteAllMusic];
            if(centerViewController.stateOfMusic == home)
                [centerViewController offlineMode];
        }
    }
}

-(void)logoutAction
{
    [[VKConnector sharedInstance] clearCookies];
    [[AppDelegate sharedDelegate] startConnection];
}

-(void)showSettings
{
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    settingsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:settingsViewController animated:YES completion:nil];
}

-(void)showHelper
{
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)showMusicViewModal {
    
    MusicViewController *news = (MusicViewController*)[AppDelegate sharedDelegate].musicViewController;
    if(!news) {
        news =  [[MusicViewController alloc] init];
    }
    [[AppDelegate sharedDelegate].navController pushViewController:news animated:YES];
}

@end
