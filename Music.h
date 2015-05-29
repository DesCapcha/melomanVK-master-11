//
//  Music.h
//  VKiller
//
//  Created by iLego on 11.05.15.
//  Copyright (c) 2015 yury.mehov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album;

@interface Music : NSManagedObject

@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * bitrate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * idAudio;
@property (nonatomic, retain) NSNumber * idUser;
@property (nonatomic, retain) NSString * songName;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Album *album;

@end
