//
//  AppDelegate.h
//  VKiller
//
//  Created by yury.mehov on 11/27/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "IIViewDeckController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "UIImage+ImageEffects.h"
#import "MMPDeepSleepPreventer.h"
#import "MusicViewController.h"

#define POST_CHANGED_FONE @"kChangedFone"
#define kALPHA 1
#define RIGHT_SIZE 15
#define LEFT_SIZE 40


@interface UINavigationBar (myNave)
- (CGSize)changeHeight:(CGSize)size;
@end

typedef enum  {
    myMusic,
    dashboard,
    search,
    home,
    recommend,
    friends,
    album,
    status,
    group,
    news,
    wall,
    groupWall,
    playlist
}State;

static NSString * const kStatusBarTappedNotification = @"statusBarTappedNotification";

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSMutableArray *urls;

@property (assign, nonatomic) BOOL offlineMode;

@property (strong,nonatomic) IIViewDeckController *controller;

@property (strong,nonatomic) MusicViewController *musicViewController;

@property (strong,nonatomic) MMPDeepSleepPreventer *preventer;

@property (strong,nonatomic) NSDate *dateForAutoSleep;

@property (strong,nonatomic) UINavigationController* navController;

+ (AppDelegate *)sharedDelegate;


@property (readonly, strong, nonatomic) NSManagedObjectContext *defaultManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *smanagedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *spersistentStoreCoordinator;

- (void)saveContextForBGTask:(NSManagedObjectContext *)bgTaskContext;
- (NSManagedObjectContext *)getContextForBGTask ;
- (NSURL *)applicationDocumentsDirectory;


-(void)renewToken;

-(void)startConnection;

-(void)methodRunAfterBackground;

-(NSArray*)getAllMusic;
-(NSArray*)getAllAlbum;
-(void)removeFromAlbumTrackWithIdAudio:(NSNumber *)idAudio IdUser:(NSNumber *)idUser;
-(Album *)albumByName:(NSString *)name;
-(Music *)musicByIdAudio:(NSNumber*)idAudio andIdUser:(NSNumber*)isUser;
-(void)musicByIdAudio:(NSNumber*)idAudio andIdUser:(NSNumber*)isUser RenameWithNewName:(NSString*)newName AndNewSong:(NSString*)newSong;
-(void)deleteAllMusic;
-(void)deleteAlbumWithName:(NSString *)name;
-(void)deleteMusicByIdAudio:(NSString*)idAudio idUser:(NSString*)idUser;

@end
