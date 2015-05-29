//
//  AppDelegate.m
//  VKiller
//
//  Created by yury.mehov on 11/27/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import "AppDelegate.h"
#import "LeftViewController.h"
#import "MusicViewController.h"
#import "CenterViewController.h"
#import "GAI.h"
#import "Reachability.h"

@interface MyPlayerLayerView : UIView
@end

@implementation MyPlayerLayerView

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self layer];
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end


@implementation UINavigationBar (customNav)
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = CGSizeMake(320,30);
    return newSize;
}
@end

@implementation AppDelegate
{
    UIWebView *_webView;
    NSTimer *volumeTimer;
    float volume;
    NSManagedObjectContext *_daddyObjectContext;
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker. Replace with your tracking ID.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-59188924-1"];
    
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    
    [NSURLCache setSharedURLCache:URLCache];
    
    self.controller = [[IIViewDeckController alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.controller];
    self.navController.navigationBarHidden = YES;
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];
    UIImage *d;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"fone.jpg"];
    if(imagePath){
        UIImage *tempImg = [UIImage imageWithContentsOfFile:imagePath];
        if(tempImg)
            d = [UIImage imageWithContentsOfFile:imagePath];
        else d = [UIImage imageNamed:@"back1.jpg"];
    }
    self.window.backgroundColor = [UIColor colorWithPatternImage:d];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAudioSessionEvent:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    [self startConnection];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    return YES;
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if([MusicManager sharedMusicManager].audioPlayer.isPlaying) {
        [[MusicManager sharedMusicManager].audioPlayer performSelector:@selector(play) withObject:nil afterDelay:0.1];
    }
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"alarm"];
    if (str.length) {
        [self.preventer startPreventSleep];
    }
    else [self.preventer stopPreventSleep];
}


-(void)addVolume
{
    [[MusicManager sharedMusicManager] setVolume:volume+=0.1];
    ((MusicViewController*)self.musicViewController).slider.value = volume;
    if(volume >=1){
        [volumeTimer invalidate];
        volumeTimer = nil;
        volume = 0.0f;
        [self.preventer stopPreventSleep];
    }
}

#pragma mark - Status bar touch tracking
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGRectContainsPoint(statusBarFrame, location)) {
        [self statusBarTouchedAction];
    }
}

- (void)statusBarTouchedAction {
    [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarTappedNotification
                                                        object:nil];
}


-(void)methodRunAfterBackground
{
    [[MusicManager sharedMusicManager] setVolume:0.0f];
    volumeTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(addVolume) userInfo:nil repeats:YES];
    
    NSInteger random;
    NSInteger all = [[AppDelegate sharedDelegate] getAllMusic].count;
    random = arc4random_uniform((u_int32_t)all);
    if(all == 0)
        return;
    NSMutableArray *songsUrl = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *songs = [NSMutableArray array];
    NSMutableArray *idAudio = [NSMutableArray array];
    NSMutableArray *idUser = [NSMutableArray array];
    NSMutableArray *duration = [NSMutableArray array];
    NSMutableDictionary *bitrate = [NSMutableDictionary dictionary];
    NSMutableArray *lyricsID = [NSMutableArray array];
    NSArray *allMusic = [[AppDelegate sharedDelegate] getAllMusic];
    [allMusic enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Music *music, NSUInteger idx, BOOL *stop){
        if(music.artist)
            [names addObject:music.artist];
        if(music.songName)
            [songs addObject:music.songName];
        if(music.idAudio)
            [idAudio addObject:music.idAudio];
        if(music.idUser)
            [idUser addObject:music.idUser];
        if(music.duration)
            [duration addObject:music.duration];
        if(music.bitrate)
            [bitrate setObject:music.bitrate forKey:[NSNumber numberWithUnsignedInteger:idx]];
        if(music.text)
            [lyricsID addObject:@(music.text.intValue)];
        NSString *unique = [[NSString stringWithFormat:@"%@-%@",music.artist,music.songName] stringByAppendingString:@".mp3"];
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        documents = [documents stringByAppendingPathComponent:@"Music/"];
        NSString *filePath = [documents stringByAppendingPathComponent:unique];
        
        [songsUrl addObject:[NSURL fileURLWithPath:filePath]];
    }];
    [AppDelegate sharedDelegate].urls = songsUrl;
    
    [MusicManager sharedMusicManager].listPlayNames = names;
    [MusicManager sharedMusicManager].listPlaySongs = songs ;
    [MusicManager sharedMusicManager].listPlayIdUser = idUser;
    [MusicManager sharedMusicManager].listPlayIdAudio = idAudio ;
    [MusicManager sharedMusicManager].listPlayDuration = duration ;
    [MusicManager sharedMusicManager].listPlayLyrics = lyricsID;
    [MusicManager sharedMusicManager].listPlayUrl = [AppDelegate sharedDelegate].urls;
    [MusicManager sharedMusicManager].stateOfMusic = home;
    [[MusicManager sharedMusicManager] playMusic:[NSIndexPath indexPathForRow:random inSection:home] AndURL:nil];
}

- (void) onAudioSessionEvent: (NSNotification *) notification
{
    //Check the type of notification, especially if you are sending multiple AVAudioSession events here
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSLog(@"Interruption notification received!");
        
        //Check to see if it was a Begin interruption
        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            NSLog(@"Interruption began!");
            
        } else if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] integerValue] == AVAudioSessionInterruptionTypeEnded){
            //[[MusicManager sharedMusicManager].audioPlayer play];
            NSLog(@"Interruption ended!");
        }
    }
    if ([notification.name isEqualToString:AVAudioSessionRouteChangeNotification]) {
        NSDictionary *interuptionDict = notification.userInfo;
        
        NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        
        switch (routeChangeReason) {
            case AVAudioSessionRouteChangeReasonUnknown:
                NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonUnknown");
                break;
                
            case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
                // a headset was added or removed
                NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonNewDeviceAvailable");
                break;
                
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
                // a headset was added or removed
                NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
                [[MusicManager sharedMusicManager] pauseMusic];
                break;
                
            case AVAudioSessionRouteChangeReasonCategoryChange:
                // called at start - also when other audio wants to play
                NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonCategoryChange");//AVAudioSessionRouteChangeReasonCategoryChange
                break;
                
            case AVAudioSessionRouteChangeReasonOverride:
                NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonOverride");
                break;
                
            case AVAudioSessionRouteChangeReasonWakeFromSleep:
                NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonWakeFromSleep");
                break;
                
            case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
                NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory");
                break;
                
            default:
                break;
        }
    }
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPause:
                [[MusicManager sharedMusicManager] pauseMusic];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [[MusicManager sharedMusicManager] resumeMusic];
                
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [[MusicManager sharedMusicManager].audioPlayer playPause];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [((MusicViewController*)self.musicViewController) nextSong:NO];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [((MusicViewController*)self.musicViewController) prevSong];
                break;
            default:
                break;
        }
    }
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController willOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated
{
    ((CenterViewController*)self.controller.centerController).mainViewController.tableView.userInteractionEnabled = NO;
}
- (void)viewDeckController:(IIViewDeckController*)viewDeckController willCloseViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    ((CenterViewController*)self.controller.centerController).mainViewController.tableView.userInteractionEnabled = YES;
}

-(void)renewToken {
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    _webView = [[UIWebView alloc] initWithFrame:frame];
    [self.window addSubview:_webView];
    [[VKConnector sharedInstance] startWithAppID:appId
                                      permissons:@[@"audio",@"status",@"friends",@"photos",@"groups",@"wall"]
                                         webView:_webView
                                        delegate:self];
}

-(void)startConnection
{
    if([VKStorage sharedStorage].isEmpty || ![[VKUser currentUser].accessToken.permissions containsObject:@"photos"] || ![VKUser currentUser].accessToken.isValid) {
        [self renewToken];
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if([self checkForWork]){
                [self startWork];
            }
        });
    }
}

#pragma mark - VKConnectorDelegate

- (void)     VKConnector:(VKConnector *)connector
accessTokenRenewalFailed:(VKAccessToken *)accessToken
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Проблемы с интернетом" delegate:self cancelButtonTitle:@"Повторить" otherButtonTitles:@"Продолжить без интернета",nil];
    [alert show];
}

- (void)   VKConnector:(VKConnector *)connector
connectionErrorOccured:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Проблемы с интернетом" delegate:self cancelButtonTitle:@"Повторить" otherButtonTitles:@"Продолжить",nil];
    [alert show];
}

-     (void)alertView:(UIAlertView *)alertView
 clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 15) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://vk.com/yury_olegovich"]];
        return;
    }
    if(buttonIndex == 0){
        [self startConnection];
    }
    else{
        self.offlineMode = YES;
        if([self checkForWork]) {
            [self startWork];
        }
    }
}

- (void)VKConnector:(VKConnector *)connector
    willHideWebView:(UIWebView *)webView
{
    [_webView removeFromSuperview];
}

- (void)        VKConnector:(VKConnector *)connector
accessTokenRenewalSucceeded:(VKAccessToken *)accessToken
{
    [_webView removeFromSuperview];
    if([self checkForWork]){
        [self startWork];
    }
}

-(BOOL)checkForWork {
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dirName = [docDir stringByAppendingPathComponent:@"Fonts"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:dirName])
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/bnqsqdbzea7855k/sec.json?dl=0"]];
        NSURLResponse *response = nil;
        NSError *error = nil;
        //getting the data
        NSData *newData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSArray* json = [NSJSONSerialization JSONObjectWithData:newData
                                                        options:kNilOptions
                                                          error:&error];
        if([json containsObject:@([VKUser currentUser].accessToken.userID)]) {
            self.offlineMode = NO;
            [fm createDirectoryAtPath:dirName withIntermediateDirectories:YES attributes:nil error:nil];
            return YES;
        }
        else {
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
            NSDate *date = [def objectForKey:@"Day"];
            if(!date) {
                [def setObject:[NSDate date] forKey:@"Day"];
                [def synchronize];
                return YES;
            }
            else {
                NSDate *newDate = [date dateByAddingTimeInterval:60*60*24];
                if([newDate compare:[NSDate date]] == NSOrderedAscending) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Тестовые сутки закончились. Для покупки приложения напишите любое сообщение разработчику" delegate:self cancelButtonTitle:@"Написать" otherButtonTitles:nil];
                    alert.tag = 15;
                    [alert show];
                }
                else return YES;
            }
        }
    }
    else
    {
        return YES;
    }
    return NO;
}


-(void)startWork
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"Color"];
        if(colorData){
            UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
            [[UILabel appearance] setTextColor:color];
            [[UIButton appearance] setTitleColor:color forState:UIControlStateNormal];
            if([UINavigationBar conformsToProtocol:@protocol(UIAppearanceContainer)]) {
                [UINavigationBar appearance].tintColor = color;
            }
            [UIButton appearance].tintColor = color;
            [UISlider appearance].thumbTintColor = color;
        }
        else{
            [[UILabel appearance] setTextColor:[UIColor whiteColor]];
            [[UIButton appearance] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            if([UINavigationBar conformsToProtocol:@protocol(UIAppearanceContainer)]) {
                [UINavigationBar appearance].tintColor = [UIColor whiteColor];
            }
        }
        CenterViewController *centerController = [[CenterViewController alloc] init];
        LeftViewController* leftController = [[LeftViewController alloc] initWithNibName:@"LeftMenuViewController" bundle:nil];
        MusicViewController *music = [[MusicViewController alloc] init];
        self.musicViewController = music;
        self.controller.delegate = self;
        
        self.controller.centerController = centerController;
        self.controller.leftController = leftController;
        self.controller.rightSize = RIGHT_SIZE;
        self.controller.leftSize = LEFT_SIZE;
        self.controller.openSlideAnimationDuration = 0.1f;
        self.controller.closeSlideAnimationDuration = 0.1f;
        [self.controller openLeftViewAnimated:YES];
    });
}


+ (AppDelegate *)sharedDelegate {
    return [[UIApplication sharedApplication] delegate];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        [application endBackgroundTask:backgroundTaskIdentifier];
    }];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_daddyObjectContext != nil) {
        return _daddyObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _daddyObjectContext = [[NSManagedObjectContext alloc]  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_daddyObjectContext setPersistentStoreCoordinator:coordinator];
        // Далее в главном потоке инициализируем main-thread context, он будет доступен пользователям
        dispatch_async(dispatch_get_main_queue(), ^{
            _defaultManagedObjectContext = [[NSManagedObjectContext alloc]  initWithConcurrencyType:NSMainQueueConcurrencyType];
            // Добавляем наш приватный контекст отцом, чтобы дочка смогла пушить все изменения
            [_defaultManagedObjectContext setParentContext:_daddyObjectContext];
        });
    }
    return _daddyObjectContext;
}

- (NSManagedObjectContext *)getContextForBGTask {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setParentContext:_defaultManagedObjectContext];
    return context;
}

- (void)saveContextForBGTask:(NSManagedObjectContext *)bgTaskContext {
    if (bgTaskContext.hasChanges) {
        [bgTaskContext performBlockAndWait:^{
            NSError *error = nil;
            [bgTaskContext save:&error];
        }];
        [self saveDefaultContext:YES];
    }
}

- (void)saveDefaultContext:(BOOL)wait {
    if (_defaultManagedObjectContext.hasChanges) {
        [_defaultManagedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            [_defaultManagedObjectContext save:&error];
        }];
    }
    
    // А после сохранения _defaultManagedObjectContext необходимо сохранить его родителя, то есть _daddyManagedObjectContext
    void (^saveDaddyContext) (void) = ^{
        NSError *error = nil;
        [_daddyObjectContext save:&error];
    };
    if ([_daddyObjectContext hasChanges]) {
        if (wait)
            [_daddyObjectContext performBlockAndWait:saveDaddyContext];
        else
            [_daddyObjectContext performBlock:saveDaddyContext];
    }
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_smanagedObjectModel != nil) {
        return _smanagedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"VKillerModel" withExtension:@"momd"];
    _smanagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _smanagedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_spersistentStoreCoordinator != nil) {
        return _spersistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Music.sqlite"];
    
    NSError *error = nil;
    
    
    _spersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *pscOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                nil];
    
    if (![_spersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                    configuration:nil URL:storeURL
                                                          options:pscOptions
                                                            error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _spersistentStoreCoordinator;
    /*
     Replace this implementation with code to handle the error appropriately.
     
     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
     
     Typical reasons for an error here include:
     * The persistent store is not accessible;
     * The schema for the persistent store is incompatible with current managed object model.
     Check the error message to determine what the actual problem was.
     
     If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
     
     If you encounter schema incompatibility errors during development, you can reduce their frequency by:
     * Simply deleting the existing store:
     [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
     
     * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
     @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
     
     Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
     
     */
}

-(NSArray*)getAllMusic
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Music" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    return array;
}

-(NSArray*)getAllAlbum
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    return array;
}

-(void)deleteAllMusic
{
    NSFetchRequest * allCars = [[NSFetchRequest alloc] init];
    [allCars setEntity:[NSEntityDescription entityForName:@"Music" inManagedObjectContext:self.managedObjectContext]];
    [allCars setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * cars = [self.managedObjectContext executeFetchRequest:allCars error:&error];
    for (NSManagedObject * car in cars) {
        [self.managedObjectContext deleteObject:car];
    }
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    documents = [documents stringByAppendingPathComponent:@"Music/"];
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *file in [fm contentsOfDirectoryAtPath:documents error:&error]) {
        NSString *fullPath = [documents stringByAppendingPathComponent:file];
        BOOL success = [fm removeItemAtPath:fullPath error:&error];
        if (!success || error) {
            // it failed.
        }
    }
}

-(void)deleteMusicByIdAudio:(NSString*)idAudio idUser:(NSString*)idUser
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Music" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate* predicate =[NSPredicate predicateWithFormat: @"idAudio = %@ and idUser = %@", idAudio,idUser];
    [request setPredicate:predicate];
    NSError *error = nil;
    
    NSArray *musicArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    for (Music *del in musicArray) {
        NSString *unique = [[NSString stringWithFormat:@"%@-%@",del.artist,del.songName] stringByAppendingString:@".mp3"];
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        documents = [documents stringByAppendingPathComponent:@"Music/"];
        NSString *filePath = [documents stringByAppendingPathComponent:unique];
        [self.managedObjectContext deleteObject:del];
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:filePath error:&error];
    }
}

-(void)deleteAlbumWithName:(NSString *)name {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate* predicate =[NSPredicate predicateWithFormat: @"name = %@", name];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *albArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    [self.managedObjectContext deleteObject:albArray[0]];
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    
}

-(void)removeFromAlbumTrackWithIdAudio:(NSNumber *)idAudio IdUser:(NSNumber *)idUser {
    Music* music = [self musicByIdAudio:idAudio andIdUser:idUser];
    music.album = nil;
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
}

-(Album *)albumByName:(NSString *)name {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate* predicate =[NSPredicate predicateWithFormat: @"name = %@", name];
    [request setPredicate:predicate];
    NSError *error = nil;
    
    NSArray *musicArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return musicArray[0];
}

-(Music *)musicByIdAudio:(NSNumber*)idAudio andIdUser:(NSNumber*)isUser{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Music" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate* predicate =[NSPredicate predicateWithFormat: @"idAudio = %@ and idUser = %@", idAudio,isUser];
    [request setPredicate:predicate];
    NSError *error = nil;
    
    NSArray *musicArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    
    return (musicArray.count> 0)?musicArray[0]:nil;
}

-(void)musicByIdAudio:(NSNumber*)idAudio andIdUser:(NSNumber*)isUser RenameWithNewName:(NSString*)newName AndNewSong:(NSString*)newSong{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Music" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate* predicate =[NSPredicate predicateWithFormat: @"idAudio = %@ and idUser = %@", idAudio,isUser];
    [request setPredicate:predicate];
    NSError *error = nil;
    
    NSArray *musicArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    ((Music*)musicArray[0]).songName = newSong;
    ((Music*)musicArray[0]).artist = newName;
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}



@end
