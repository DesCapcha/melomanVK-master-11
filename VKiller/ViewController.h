//
//  ViewController.h
//  VKiller
//
//  Created by yury.mehov on 11/27/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"
#import "CDActivityIndicatorView.h"

@class CenterViewController;

@interface ViewController : PullRefreshTableViewController<VKRequestDelegate,UISearchBarDelegate, UIAlertViewDelegate>
{
    
    UISearchBar *searchBar;
    NSOperationQueue *operationQueue;
}
@property (weak, nonatomic) CenterViewController *centerViewControl;

@property NSInteger stateOfMusic;
@property(assign,nonatomic) NSInteger countFriends;
@property(strong,nonatomic) NSMutableArray *names;
@property(strong,nonatomic) NSMutableArray *songs;
@property(strong,nonatomic) NSMutableArray *duration;
@property(strong,nonatomic) NSMutableArray *idAudio;
@property(strong,nonatomic) NSMutableArray *idUser;
@property(strong,nonatomic) NSMutableArray *lyricsID;

@property(strong,nonatomic) NSMutableArray *s_names;
@property(strong,nonatomic) NSMutableArray *s_songs;
@property(strong,nonatomic) NSMutableArray *s_duration;
@property(strong,nonatomic) NSMutableArray *s_idAudio;
@property(strong,nonatomic) NSMutableArray *s_idUser;
@property(strong,nonatomic) NSMutableArray *s_lyricsID;
@property(strong,nonatomic) NSMutableArray *s_urls;

@property(strong,nonatomic) NSMutableSet *selectedIndex;

@property(strong,nonatomic) NSMutableDictionary *bitrate;
@property(strong,nonatomic) CDActivityIndicatorView * activityIndicatorView;

-(void)clickDownload:(UIButton*)button;
- (void)download:(UIButton*)button fromMusic:(BOOL)notFromMusic;

@property (nonatomic,strong) UILongPressGestureRecognizer *lpgr;


-(void)changeView:(int)state;

-(BOOL)shuffleAll;
-(void)offlineMode;
-(void)playlistMode;

@end

@interface NSMutableArray (Helpers)

- (NSMutableArray *) shuffled;

@end
