//
//  Album.h
//  VKiller
//
//  Created by iLego on 11.05.15.
//  Copyright (c) 2015 yury.mehov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Music;

@interface Album : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * avatarPath;
@property (nonatomic, retain) NSNumber * albID;
@property (nonatomic, retain) NSSet *tracks;
@end

@interface Album (CoreDataGeneratedAccessors)

- (void)addTracksObject:(Music *)value;
- (void)removeTracksObject:(Music *)value;
- (void)addTracks:(NSSet *)values;
- (void)removeTracks:(NSSet *)values;

@end
