//
//  MusicManager.h
//  VKiller
//
//  Created by yury.mehov on 11/29/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Music.h"
#import "VKMusicPlayer.h"
#import "SDWebImage/UIImageView+WebCache.h"


@interface MusicManager : NSObject<NSURLConnectionDataDelegate>

@property(strong,nonatomic) NSIndexPath *playIndexPlaylist;

@property(assign,nonatomic) NSInteger stateOfMusic;

@property(assign,nonatomic,readonly,getter = getOnline) BOOL isOnline;

@property(assign, nonatomic) BOOL statusMusic;
@property(assign, nonatomic) BOOL coverShow;
@property(assign, nonatomic) BOOL Offgestures;
@property(assign, nonatomic) BOOL bitrate;
@property(assign, nonatomic) BOOL equalizer;

@property (nonatomic, strong) id timeObserver;

@property (strong, nonatomic) VKMusicPlayer *audioPlayer;

@property (nonatomic, assign) int currentDuration;

+(MusicManager*)sharedMusicManager;

@property(nonatomic,strong) NSMutableArray *listPlayNames;
@property(strong,nonatomic) NSMutableArray *listPlaySongs;
@property(strong,nonatomic) NSMutableArray *listPlayDuration;
@property(strong,nonatomic) NSMutableArray *listPlayLyrics;
@property(strong,nonatomic) NSMutableArray *listPlayIdAudio;
@property(strong,nonatomic) NSMutableArray *listPlayIdUser;
@property(nonatomic,strong) NSMutableArray *listPlayUrl;

@property(nonatomic,strong) SDImageCache *imageCache;
@property(nonatomic,strong) NSOperation *operation;


-(NSString*)currentMusicName;
-(NSString*)currentMusicArtist;
-(void)currentCoverWithCompletedBlock:(void (^)(UIImage *image))completedBlock ;
-(void)saveAllAlbumCoverFromWiFiWithCallback:(void(^)(double percent))callback;


-(void)playMusic:(NSIndexPath*)index AndURL:(NSURL*)url;

- (void)pauseMusic;

-(void)resumeMusic;

-(void)setVolume:(float)volume;

- (void) skipToSeconds:(float)position;



@end
