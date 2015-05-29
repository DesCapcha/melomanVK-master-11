//
//  MusicDownloader.h
//  VKiller
//
//  Created by yury.mehov on 1/15/14.
//  Copyright (c) 2014 yury.mehov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicDownloader : NSOperation


@property(strong,nonatomic,readonly) NSString* artist;
@property(strong,nonatomic,readonly) NSString* songName;
@property(strong,nonatomic,readonly) NSNumber* duration;
@property(strong,nonatomic,readonly) NSNumber* idAudio;
@property(strong,nonatomic,readonly) NSNumber* idUser;
@property(strong,nonatomic,readonly) NSString* bitrate;
@property(strong,nonatomic,readonly) NSNumber* lyricsId;


@property(strong,nonatomic) NSURL *url;


@property (nonatomic) NSMutableData *receivedData;
@property (nonatomic) NSUInteger totalBytes;
@property (nonatomic) NSUInteger receivedBytes;
@property (nonatomic) NSIndexPath *currentIndexPath;


-(instancetype)initWithArtist:(NSString*)artist songName:(NSString*)songName idAudio:(NSNumber*)isAudio idUser:(NSNumber*)isUser duration:(NSNumber*)duration bitrate:(NSString*)bitrate text:(NSNumber*)textID;



@end
