//
//  VKMusicPlayer.h
//  VKiller
//
//  Created by iLego on 12.02.15.
//  Copyright (c) 2015 yury.mehov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VKMusicPlayer : NSObject <AVAudioPlayerDelegate>
{
    AVAudioPlayer *audioPlayerLocal;
    AVPlayer *audioPlayerInternet;
}
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) id currentPlayer;


-(void)playMusicFromURL:(NSURL*)url;
-(UIImage*)currentCover;

-(BOOL)isPlaying;

-(void)play;
-(void)pause;

-(void)playPause;

-(void)setVolume:(float)volume;
-(void)seekToTime:(CMTime)time;
-(float)duration;

@end
