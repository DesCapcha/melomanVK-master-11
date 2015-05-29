//
//  MusicManager.m
//  VKiller
//
//  Created by yury.mehov on 11/29/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import "MusicManager.h"
#import "MusicViewController.h"
#import "ViewController.h"
#import "CenterViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Reachability.h"


@implementation MusicManager


+(MusicManager*)sharedMusicManager
{
    
    static MusicManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        sharedMyManager.audioPlayer = [[VKMusicPlayer alloc] init];
        sharedMyManager.listPlayNames = [NSMutableArray array];
        sharedMyManager.listPlaySongs = [NSMutableArray array];
        sharedMyManager.listPlayDuration = [NSMutableArray array];
        sharedMyManager.listPlayIdAudio = [NSMutableArray array];
        sharedMyManager.listPlayIdUser = [NSMutableArray array];
        sharedMyManager.listPlayUrl = [NSMutableArray array];
        sharedMyManager.listPlayLyrics = [NSMutableArray array];
        sharedMyManager.imageCache = [[SDImageCache alloc] initWithNamespace:@"default"];
        sharedMyManager.statusMusic = ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"status"]).boolValue;
        sharedMyManager.Offgestures = ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"gesturesOFF"]).boolValue;
        sharedMyManager.bitrate = ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"bitrateOFF"]).boolValue;
        if(![[NSUserDefaults standardUserDefaults] objectForKey:@"cover"])
            sharedMyManager.coverShow = NO;
        else
            sharedMyManager.coverShow = ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"cover"]).boolValue;
    });
    return sharedMyManager;
}

-(NSString*)uniqueString
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

-(void)getDuration
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    NSNumber *number = [NSNumber numberWithInt:self.currentDuration];
    [nc postNotificationName:@"DURATION" object:self userInfo:@{@"duration":number}];
}


-(void)playMusic:(NSIndexPath*)index AndURL:(NSURL*)url
{
    [((CenterViewController*)([AppDelegate sharedDelegate].controller.centerController)).mainViewController.tableView reloadData];
    self.playIndexPlaylist = index;
    if(self.listPlayDuration.count){
        self.currentDuration = [self.listPlayDuration[index.row] intValue];
    }
    NSURL *urlStrong;
    if(!url)
        urlStrong = self.listPlayUrl[index.row];
    else urlStrong = url;
    [self.audioPlayer playMusicFromURL:urlStrong];
    NSArray *keys = [NSArray arrayWithObjects:
                     MPMediaItemPropertyTitle,
                     MPMediaItemPropertyArtist,
                     MPMediaItemPropertyPlaybackDuration,
                     MPNowPlayingInfoPropertyPlaybackRate,
                     nil];
    NSArray *values = [NSArray arrayWithObjects:
                       [[MusicManager sharedMusicManager] currentMusicName],
                       [[MusicManager sharedMusicManager] currentMusicArtist],
                       [NSNumber numberWithInt:[MusicManager sharedMusicManager].currentDuration],
                       [NSNumber numberWithInt:1],
                       nil];
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
    });
    [self getDuration];
    
}

-(NSString*)currentMusicName {
    if(self.playIndexPlaylist.row < self.listPlaySongs.count) {
        return self.listPlaySongs[self.playIndexPlaylist.row];
    }
    return @"";
}
-(NSString*)currentMusicArtist {
    return self.listPlayNames[self.playIndexPlaylist.row];
}

-(void)currentCoverWithCompletedBlock:(void (^)(UIImage *image))completedBlock {
    NSString *keyString = [[NSString stringWithFormat:@"%@_%@",self.currentMusicName,self.currentMusicArtist] stringByReplacingOccurrencesOfString:@" " withString:@""];
    self.operation = [self.imageCache queryDiskCacheForKey:keyString done:^(UIImage *image, SDImageCacheType cacheType){
        NSString *keyD = [keyString copy];
        if(image) {
            completedBlock(image);
            return;
        }
        //image = [self.audioPlayer currentCover];
        //         if(image) {
        //             [[SDImageCache sharedImageCache] storeImage:image forKey:keyD];
        //             completedBlock(image);
        //             return;
        //         }
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        
        NetworkStatus status = [reachability currentReachabilityStatus];
        
        if(status == NotReachable)
        {
            //No internet
        }
        else if (status == ReachableViaWiFi)
        {
            NSString *s =@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=";
            NSString *urlString = [NSString stringWithFormat:@"%@%@ %@",s,self.currentMusicName ,self.currentMusicArtist];
            urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *responseString = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]] encoding:NSUTF8StringEncoding];
            NSError *e = nil;
            NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error: &e];
            id res = [JSON objectForKey:@"responseData"];
            if(res != [NSNull null]){
                NSArray * array = [res objectForKey:@"results"];
                for(int i = 0; i < array.count && !image; i++) {
                    NSString *a = [[res objectForKey:@"results"][i] objectForKey:@"url"];
                    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:a]]];
                    if(image){
                        [[SDImageCache sharedImageCache] storeImage:image forKey:keyD];
                        completedBlock(image);
                        return;
                    }
                }
            }
            else {
                completedBlock(nil);
                return;
            }
        }
    }];
}

-(void)saveAllAlbumCoverFromWiFiWithCallback:(void(^)(double percent))callback{
    NSArray *arrayAllMusic = [[AppDelegate sharedDelegate] getAllMusic];
    __block NSUInteger countS = 0;
    @autoreleasepool {
        for (Music *track in arrayAllMusic) {
            NSString *keyString = [[NSString stringWithFormat:@"%@_%@",track.songName,track.artist] stringByReplacingOccurrencesOfString:@" " withString:@""];
            UIImage *image = [self.imageCache imageFromDiskCacheForKey:keyString];
            //self.operation = [self.imageCache queryDiskCacheForKey:keyString done:^(UIImage *image, SDImageCacheType cacheType){
            if(!image){
                NSString *s =@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=";
                NSString *urlString = [NSString stringWithFormat:@"%@%@ %@",s,track.songName ,track.artist];
                urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSString *responseString = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]] encoding:NSUTF8StringEncoding];
                NSError *e = nil;
                NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error: &e];
                id r = [JSON objectForKey:@"responseData"];
                if(r != [NSNull null]){
                    NSArray * array = [r objectForKey:@"results"];
                    for(int i = 0; i < array.count; i++) {
                        NSString *a = [[[JSON objectForKey:@"responseData"] objectForKey:@"results"][i] objectForKey:@"url"];
                        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:a]]];
                        if(image){
                            float percent = ((float)countS++)/arrayAllMusic.count;
                            callback(percent);
                            [[SDImageCache sharedImageCache] storeImage:image forKey:keyString];
                            break;
                        }
                    }
                }
                else {
                    callback(-1.);
                    return;
                }
            }
            else {
                callback(((float)countS++)/arrayAllMusic.count);
            }
            //}];
        }
    }
}


-(BOOL)getOnline
{
    if(self.stateOfMusic != home)
        return YES;
    return NO;
}

- (void)pauseMusic
{
    [AppDelegate sharedDelegate].musicViewController.playButton.tag = PLAY;
    [[AppDelegate sharedDelegate].musicViewController.playButton setImage:[UIImage imageNamed:@"playMusic1.png"] forState:UIControlStateNormal];
    [self.audioPlayer pause];
}

-(void)resumeMusic
{
    [AppDelegate sharedDelegate].musicViewController.playButton.tag = PAUSE;
    [[AppDelegate sharedDelegate].musicViewController.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    [self.audioPlayer play];
}

-(void)setVolume:(float)volume
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
        [self.audioPlayer setVolume:volume];
    });
}


- (void) skipToSeconds:(float)position
{
    Float64 duration = [self.audioPlayer duration];
    if(duration)
        position = duration*position;
    [self.audioPlayer seekToTime:CMTimeMake(position, 1)];
    MusicViewController *news = (MusicViewController*)[AppDelegate sharedDelegate].musicViewController;
    NSArray *keys = [NSArray arrayWithObjects:
                     MPMediaItemPropertyTitle,
                     MPMediaItemPropertyArtist,
                     MPMediaItemPropertyPlaybackDuration,
                     MPNowPlayingInfoPropertyPlaybackRate,
                     MPNowPlayingInfoPropertyElapsedPlaybackTime,
                     nil];
    NSArray *values = [NSArray arrayWithObjects:
                       news.songLbl.text,
                       news.nameLbl.text,
                       [NSNumber numberWithInt:[MusicManager sharedMusicManager].currentDuration],
                       [NSNumber numberWithInt:1],
                       [NSNumber numberWithFloat:position],
                       nil];
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
    });
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
