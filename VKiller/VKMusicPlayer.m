//
//  VKMusicPlayer.m
//  VKiller
//
//  Created by iLego on 12.02.15.
//  Copyright (c) 2015 yury.mehov. All rights reserved.
//

#import "VKMusicPlayer.h"

@implementation VKMusicPlayer

-(instancetype)init {
    self = [super init];
    if(self) {
        audioPlayerInternet = [[AVPlayer alloc] init];
    }
    return self;
}

- (void)updateTimeLeft {
    if(self.currentPlayer == audioPlayerLocal){
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithDouble:audioPlayerLocal.currentTime] forKey:@"time"];
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"TIME" object:self userInfo:userInfo];
    }
}

-(BOOL)isPlaying {
    return (audioPlayerLocal.playing || audioPlayerInternet.rate != 0);
}

-(void)playMusicMainThread:(NSURL *)url {
    [audioPlayerLocal stop];
    audioPlayerLocal = nil;
    [audioPlayerInternet pause];
    if(url.isFileURL){
        NSError *error;
        audioPlayerLocal = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        audioPlayerLocal.volume = [[AVAudioSession sharedInstance] outputVolume];
        audioPlayerLocal.delegate = self;
        [audioPlayerLocal prepareToPlay];
        [audioPlayerLocal play];
        audioPlayerLocal.meteringEnabled = YES;
        //[audioPlayerInternet removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
        self.timeObserver = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                             target:self
                                                           selector:@selector(updateTimeLeft)
                                                           userInfo:nil
                                                            repeats:YES];
        self.currentPlayer = audioPlayerLocal;
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [audioPlayerInternet replaceCurrentItemWithPlayerItem:playerItem];
        [audioPlayerInternet play];
        audioPlayerInternet.volume = [[AVAudioSession sharedInstance] outputVolume];
        self.currentPlayer = audioPlayerInternet;
        __weak typeof(self) weakSelf = self;
        void (^observerBlock)(CMTime time) = ^(CMTime time) {
            int timeString = (float)time.value / (float)time.timescale;
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                [userInfo setObject:[NSNumber numberWithInt:timeString] forKey:@"time"];
                NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                [nc postNotificationName:@"TIME" object:weakSelf userInfo:userInfo];
            } else {
                NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                [userInfo setObject:[NSNumber numberWithInt:timeString] forKey:@"time"];
                NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                [nc postNotificationName:@"TIME" object:weakSelf userInfo:userInfo];
            }
        };
        [self.timeObserver invalidate];
        self.timeObserver = nil;
        self.timeObserver = [audioPlayerInternet addPeriodicTimeObserverForInterval:CMTimeMake(100, 1000)
                                                                              queue:dispatch_get_main_queue()
                                                                         usingBlock:observerBlock];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FINISHED" object:nil];
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FINISHED" object:nil];
}


-(void)playMusicFromURL:(NSURL*)url {
    if([NSThread isMainThread])
        [self playMusicMainThread:url];
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self playMusicMainThread:url];
        });
    }
}

-(UIImage*)currentCover {
    if(self.currentPlayer == audioPlayerInternet) {
        UIImage *img;
        NSArray *metadata = audioPlayerInternet.currentItem.asset.commonMetadata;
        for(AVMetadataItem *item in metadata){
            if([item.commonKey isEqualToString:@"artwork"]){
                NSData *data;
                if([item.value isKindOfClass:[NSDictionary class]]) {
                    data = [((NSDictionary*)item.value) objectForKey:@"data"];
                }
                else
                    data = (NSData*)item.value;
                img = [UIImage imageWithData:data];
                if(img) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
                        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:img];
                        NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
                        [playingInfo setValue:albumArt forKey:MPMediaItemPropertyArtwork];
                        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:playingInfo];
                    });
                }
                return img;
            }
        }
        return img;
    }
    else {
        AVURLAsset *asset = [AVURLAsset assetWithURL:audioPlayerLocal.url];
        UIImage *img;
        NSArray *metadata = asset.commonMetadata;
        for(AVMetadataItem *item in metadata){
            if([item.commonKey isEqualToString:@"artwork"]){
                NSData *data;
                if([item.value isKindOfClass:[NSDictionary class]]) {
                    data = [((NSDictionary*)item.value) objectForKey:@"data"];
                }
                else
                    data = (NSData*)item.value;
                img = [UIImage imageWithData:data];
                if(img) {
                    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
                    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:img];
                    NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
                    [playingInfo setValue:albumArt forKey:MPMediaItemPropertyArtwork];
                    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:playingInfo];
                }
                return img;
            }
        }
        return img;
    }
}

-(void)play{
    float current = 0;
    if(self.currentPlayer == audioPlayerLocal){
        current = audioPlayerLocal.currentTime;
    }
    else if(self.currentPlayer == audioPlayerInternet) {
        current = CMTimeGetSeconds(audioPlayerInternet.currentItem.currentTime);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
        [playingInfo setObject:[NSNumber numberWithFloat:current] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [playingInfo setObject:[NSNumber numberWithDouble:1.0f] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        center.nowPlayingInfo = playingInfo;
    });
    if(self.currentPlayer == audioPlayerLocal) {
        [audioPlayerLocal prepareToPlay];
        [audioPlayerLocal play];
    }
    else [audioPlayerInternet play];
}

-(void)pause{
    float current = 0;
    if(self.currentPlayer == audioPlayerLocal){
        current = audioPlayerLocal.currentTime;
    }
    else if(self.currentPlayer == audioPlayerInternet) {
        current = CMTimeGetSeconds(audioPlayerInternet.currentItem.currentTime);
    }
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
    [playingInfo setObject:[NSNumber numberWithFloat:current] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [playingInfo setObject:[NSNumber numberWithDouble:0.0f] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    center.nowPlayingInfo = playingInfo;
    if(self.currentPlayer == audioPlayerLocal) {
        [audioPlayerLocal pause];
    }
    else [audioPlayerInternet pause];
}

-(void)playPause {
    if(self.isPlaying) {
        [self pause];
    }
    else {
        [self play];
    }
}

-(void)setVolume:(float)volume{
    if(self.currentPlayer == audioPlayerLocal) {
        [audioPlayerLocal setVolume:volume];
    }
    else [audioPlayerInternet setVolume:volume];
}

-(void)seekToTime:(CMTime)time{
    if(self.currentPlayer == audioPlayerLocal) {
        [audioPlayerLocal setCurrentTime:time.value];
        [audioPlayerLocal play];
    }
    else if(time.value != 0) {
        [audioPlayerInternet.currentItem seekToTime:time];
    }
    else {
        [audioPlayerInternet seekToTime: time
                        toleranceBefore: kCMTimeZero
                         toleranceAfter: kCMTimeZero
                      completionHandler: ^(BOOL finished) {
                          [audioPlayerInternet play];
                      }];
    }
}

-(float)duration {
    if(self.currentPlayer == audioPlayerInternet)
        return CMTimeGetSeconds(audioPlayerInternet.currentItem.asset.duration);
    return audioPlayerLocal.duration;
}


@end
