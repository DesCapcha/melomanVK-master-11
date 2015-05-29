//
//  SettingsViewController.m
//  VKiller
//
//  Created by yury.mehov on 07/08/14.
//  Copyright (c) 2014 yury.mehov. All rights reserved.
//

#import "SettingsViewController.h"
#import "MusicManager.h"
#import "RNBlurModalView.h"
#import "NKOColorPickerView.h"
#import "MusicViewController.h"

@interface SettingsViewController ()
@property (strong, nonatomic) IBOutlet UILabel *countOfMusics;
@property (strong, nonatomic) IBOutlet UISwitch *statusSwither;
@property (weak, nonatomic) IBOutlet UISwitch *coverSwitcher;
@property (weak, nonatomic) IBOutlet UISwitch *gestureSwitcher;
@property (weak, nonatomic) IBOutlet UIButton *alarmDeleteBtn;
@property (weak, nonatomic) IBOutlet UIButton *timerDeleteBtn;

@end

@implementation SettingsViewController
{
    RNBlurModalView *alertView;
    UIImagePickerController *imagePickerController;
    UIActionSheet *_actionSheet;
    UIImageView *view;
    BOOL dark_blur;
    BOOL light_blur;
    ClockViewController *clockViewC;
    BOOL foneIsChanged;
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.statusSwither.on = [MusicManager sharedMusicManager].statusMusic;
    self.coverSwitcher.on = [MusicManager sharedMusicManager].coverShow;
    self.gestureSwitcher.on = [MusicManager sharedMusicManager].Offgestures;
    self.bitrateSwitcher.on =[MusicManager sharedMusicManager].bitrate;
    
    self.alarmLbl.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"alarm"]?[[NSUserDefaults standardUserDefaults] objectForKey:@"alarm"]:@"";
    if(self.alarmLbl.text.length > 0) {
        self.alarmDeleteBtn.hidden = NO;
    }
    NSTimeInterval diff = [[AppDelegate sharedDelegate].dateForAutoSleep timeIntervalSinceDate:[NSDate date]];
    if(diff > 0){
        NSInteger ti = (NSInteger)diff;
        NSInteger seconds = ti % 60;
        NSInteger minutes = (ti / 60) % 60;
        NSInteger hours = (ti / 3600);
        self.dateSleepLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes,(long)seconds];
        self.timerDeleteBtn.hidden = NO;
    }
    NSUInteger count = [[AppDelegate sharedDelegate] getAllMusic].count;
    self.countOfMusics.text = [NSString stringWithFormat:@"%lu треков",(unsigned long)count];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self changedFone];
}

-(void)viewDidLayoutSubviews
{
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
        if(tempImg)
            view.image = [UIImage imageWithContentsOfFile:imagePath];
        else view.image = [UIImage imageNamed:@"back1.jpg"];
    }
    view.frame = self.view.frame;
    view.alpha = kALPHA;
    [self.view addSubview:view ];
    [self.view sendSubviewToBack:view ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)statusSwitch:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:sender.isOn] forKey:@"status"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [MusicManager sharedMusicManager].statusMusic = sender.isOn;
}
- (IBAction)coverSwitch:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:sender.isOn] forKey:@"cover"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [MusicManager sharedMusicManager].coverShow = sender.isOn;
}
- (IBAction)gestureSwitch {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.gestureSwitcher.isOn] forKey:@"gesturesOFF"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [MusicManager sharedMusicManager].Offgestures = self.gestureSwitcher.isOn;
}
- (IBAction)bitrateSwitch {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.bitrateSwitcher.isOn] forKey:@"bitrateOFF"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [MusicManager sharedMusicManager].bitrate = self.bitrateSwitcher.isOn;
}
- (IBAction)postVK {
    
    VKRequestManager *rm = [[VKRequestManager alloc]
                            initWithDelegate:self
                            user:[VKUser currentUser]];
    rm.offlineMode = [AppDelegate sharedDelegate].offlineMode;
    [rm wallPost:@{@"owner_id":[NSString stringWithFormat:@"%lu",(unsigned long)[VKUser currentUser].accessToken.userID ],
                   @"message":@"Слушаю музыку на своём iPhone в плеере для ВК с будильником, таймером и визуализатором. \nПрисоединяйся!",
                   @"attachments":@"photo5716094_356239806,http://ios-vk.tk"}];
}

-(void)VKRequest:(VKRequest *)request response:(id)response
{
    alertView = [[RNBlurModalView alloc] initWithParentView:self.view title:@"Спасибо!"
                                                    message:@"Надпись успешно размещена на Вашей стене"];
    [alertView show];
}


- (IBAction)dissmissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)setFone {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        _actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Отмена"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"Без эффекта", @"Светлый блюр", @"Тёмный блюр", nil];
        [_actionSheet showInView:self.view];
        
    }
    else{
        alertView = [[RNBlurModalView alloc] initWithParentView:self.view title:@"Ошибка"
                                                        message:@"Нет доступа к библиотеке"];
        [alertView show];
    }
    
}

- (IBAction)setColorText {
    
    NKOColorPickerDidChangeColorBlock colorDidChangeBlock = ^(UIColor *color){
        [[UILabel appearance] setTextColor:color];
        [[UIButton appearance] setTitleColor:color forState:UIControlStateNormal];
        NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
        [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"Color"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        foneIsChanged = YES;
    };
    
    
    //URBAlertView *alertColor = [[URBAlertView alloc] initWithTitle:@"" message:@"\n\n\n\n\n\n\n\n\n\n\n\n" cancelButtonTitle:@"OK" otherButtonTitles: nil];
    NKOColorPickerView *colorPickerView = [[NKOColorPickerView alloc] initWithFrame:CGRectMake(0, 0, 200, 300) color:[UILabel appearance].textColor andDidChangeColorBlock:colorDidChangeBlock];
    //alertColor.contentView = colorPickerView;
    //alertColor.contentView.frame = alertColor.frame;
    colorPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    //[alertColor addSubview:colorPickerView];
    //[alertColor show];
    UIViewController *cont = [[UIViewController alloc] init];
    cont.view = colorPickerView;
    RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self view:colorPickerView];
    modal.defaultHideBlock = ^{
        UIAlertView *all = [[UIAlertView alloc] initWithTitle:@"" message:@"Чтобы изменение вступили в силу, пожалуйста, перезапустите приложение" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [all show];
    };
    [modal show];
}

- (IBAction)clearColors {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"fone.jpg"];
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:POST_CHANGED_FONE object:nil];
    [[UILabel appearance] setTextColor:[UIColor whiteColor]];
    [[UIButton appearance] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self changedFone];
    
    UIAlertView *all = [[UIAlertView alloc] initWithTitle:@"" message:@"Чтобы изменение вступили в силу, пожалуйста, перезапустите приложение" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [all show];
}

- (IBAction)showClockAlarm
{
    clockViewC = [[ClockViewController alloc] init];
    UIView *views = [clockViewC view];
    views.frame = CGRectMake(40, 40, self.view.frame.size.width-80, self.view.frame.size.height-80);
    RNBlurModalView *modal = [[RNBlurModalView alloc] initWithParentView:self.view view:views];
    modal.defaultHideBlock = ^{
        NSDate *date = [NSDate date];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: date];
        NSString* hour =[NSString stringWithFormat:@"%d",(int)clockViewC.timerControl1.minutesOrSeconds];
        if(hour.length == 1)
            hour = [NSString stringWithFormat:@"0%@",hour];
        NSString* minute =[NSString stringWithFormat:@"%d",(int)clockViewC.timerControl2.minutesOrSeconds];
        if(minute.length == 1)
            minute = [NSString stringWithFormat:@"0%@",minute];
        self.alarmLbl.text = [NSString stringWithFormat:@"%@ч:%@м",hour,minute];
        [[NSUserDefaults standardUserDefaults] setObject:self.alarmLbl.text forKey:@"alarm"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [components setHour: clockViewC.timerControl1.minutesOrSeconds];
        [components setMinute: clockViewC.timerControl2.minutesOrSeconds];
        [AppDelegate sharedDelegate].preventer = [[MMPDeepSleepPreventer alloc] init];
        NSDate *newDate = [gregorian dateFromComponents: components];
        NSTimeInterval interval = [newDate timeIntervalSinceNow];
        
        if(interval < 0)
            interval = 24*60*60+interval-60;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppDelegate sharedDelegate] selector:@selector(methodRunAfterBackground) object: nil];
        [[AppDelegate sharedDelegate] performSelector:@selector(methodRunAfterBackground) withObject:nil afterDelay:interval];
        self.alarmDeleteBtn.hidden = NO;
    };
    [modal show];
}
- (IBAction)showDateSleep {
    clockViewC = [[ClockViewController alloc] init];
    UIView *views = [clockViewC view];
    views.frame = CGRectMake(40, 40, self.view.frame.size.width-80, self.view.frame.size.height-80);
    RNBlurModalView *modal = [[RNBlurModalView alloc] initWithParentView:self.view view:views];
    modal.defaultHideBlock = ^{
        if(clockViewC.timerControl1.minutesOrSeconds == 0 && clockViewC.timerControl2.minutesOrSeconds == 0)
            return;
        NSDate *date = [NSDate date];
        NSString* hour =[NSString stringWithFormat:@"%d",(int)clockViewC.timerControl1.minutesOrSeconds];
        if(hour.length == 1)
            hour = [NSString stringWithFormat:@"0%@",hour];
        NSString* minute =[NSString stringWithFormat:@"%d",(int)clockViewC.timerControl2.minutesOrSeconds];
        if(minute.length == 1)
            minute = [NSString stringWithFormat:@"0%@",minute];
        self.dateSleepLabel.text = [NSString stringWithFormat:@"%@ч:%@м",hour,minute];
        NSTimeInterval seconds = clockViewC.timerControl1.minutesOrSeconds * 60 * 60 + clockViewC.timerControl2.minutesOrSeconds * 60;
        [AppDelegate sharedDelegate].dateForAutoSleep = [date dateByAddingTimeInterval:seconds];
        self.timerDeleteBtn.hidden = NO;
    };
    [modal show];
    clockViewC.timerControl1.minutesOrSeconds = 0;
    clockViewC.timerControl2.minutesOrSeconds = 15;
}

- (IBAction)alarm:(UIButton*)btn{
    NSString *text;
    if(btn.tag ==1)
        text =@"В назначенное Вами время заиграет любая композиция из загруженных в приложении. При этом само приложение может и не быть активно, а экран - залочен.\n\n Единственное условие - не убивать плеер из трея!";
    else
        text = @"Воспроизведение музыки закончится через установленное Вами время";
    RNBlurModalView *title = [[RNBlurModalView alloc] initWithParentView:self.view title:btn.tag==1?@"Будильник":@"Таймер" message:text];
    [title show];
}

- (IBAction)alarmDeleteAction {
    [NSObject cancelPreviousPerformRequestsWithTarget:[AppDelegate sharedDelegate] selector:@selector(methodRunAfterBackground) object: nil];
    self.alarmLbl.text = @"";
    self.alarmDeleteBtn.hidden = YES;
    [[AppDelegate sharedDelegate].preventer stopPreventSleep];
    [AppDelegate sharedDelegate].preventer = nil;
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"alarm"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)dateSleepDelete {
    self.dateSleepLabel.text = @"";
    self.timerDeleteBtn.hidden = YES;
    [AppDelegate sharedDelegate].dateForAutoSleep = nil;
}

//-(void)timePicker:(KPTimePicker*)timePicker selectedDate:(NSDate *)date
//{
//    NSDate* now = [NSDate date] ;
//    self.alarmLbl.text = @"10:08";
//    NSDateComponents* tomorrowComponents = [NSDateComponents new] ;
//    tomorrowComponents.day = 0 ;
//    NSCalendar* calendar = [NSCalendar currentCalendar] ;
//    NSDate* tomorrow = [calendar dateByAddingComponents:tomorrowComponents toDate:now options:0] ;
//
//    NSDateComponents* tomorrowAt8AMComponents = [calendar components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:tomorrow] ;
//    tomorrowAt8AMComponents.hour = 2 ;
//    tomorrowAt8AMComponents.minute = 55;
//    NSDate* tomorrowAt8AM = [calendar dateFromComponents:tomorrowAt8AMComponents] ;
//    NSTimeInterval interval = [tomorrowAt8AM timeIntervalSinceNow];
//    [[AppDelegate sharedDelegate] performSelector:@selector(methodRunAfterBackground) withObject:nil afterDelay:interval];
//}

//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
//}

-(BOOL)prefersStatusBarHidden   // iOS8 definitely needs this one. checked.
{
    return YES;
}

-(UIViewController *)childViewControllerForStatusBarHidden
{
    return nil;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CGSize newSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"fone.jpg"];
    
    //extracting image from the picker and saving it
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]){
        if(dark_blur)
            newImage = [newImage applyDarkEffect];
        if(light_blur)
            newImage = [newImage applyLightEffect];
        NSData *webData = UIImageJPEGRepresentation(newImage,1);
        [webData writeToFile:imagePath atomically:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:POST_CHANGED_FONE object:nil];
        [self changedFone];
    }
    
    
}


- (void)takePhoto
{
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}


- (void)choosePhotoFromLibrary
{
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - UIImagePickerController Delegate




- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)logoutAction:(id)sender {
    
    [[VKConnector sharedInstance] clearCookies];
    [[AppDelegate sharedDelegate] startConnection];
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 3) return;
    light_blur = (buttonIndex == 1);
    dark_blur = (buttonIndex == 2);
    [self choosePhotoFromLibrary];
    _actionSheet = nil;
}

@end
