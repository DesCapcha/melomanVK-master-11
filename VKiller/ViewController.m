//
//  ViewController.m
//  VKiller
//
//  Created by yury.mehov on 11/27/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import "ViewController.h"
#import "MusicViewController.h"
#import "MusicCell.h"
#import "FriendsCell.h"
#import "MusicDownloader.h"
#import "PlaylistCell.h"
#import "CenterViewController.h"
#import "Album.h"


@interface ViewController ()
{
    
    NSMutableSet *waitingIndex;
    UIButton *tempButton;
    VKRequestManager *rm;
    NSCache *cacheImage;
    BOOL firstTime;
    NSMutableArray *lastFiveDownloader;
    int max;
    BOOL isFour;
}

@end

@implementation ViewController
{
    NSString *tokenId;
}

- (void)statusBarTappedAction:(NSNotification*)notification {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    //handle StatusBar tap here.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    if([ [ UIScreen mainScreen ] bounds ].size.height < 500)
        isFour = YES;
    operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 3;
    lastFiveDownloader = [NSMutableArray arrayWithCapacity:5];
    [MusicManager sharedMusicManager].stateOfMusic = home;
    
    waitingIndex = [NSMutableSet set];
    self.selectedIndex = [NSMutableSet set];
    self.tableView.allowsSelectionDuringEditing = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCell:) name:PERCENT_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downoadSucsess:) name:LOADING_COMPLETED_NOTIFICATION object:nil];
    //    UIImageView *view;
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"fone.jpg"];
    //    if(imagePath)
    //        view = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]];
    //    else self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:@"foneBlack.jpg"]];
    //    view.backgroundColor = [UIColor blackColor];
    //    self.tableView.backgroundView = view;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.title = @"Обновление";
    cacheImage = [[NSCache alloc] init];
    
    rm = [[VKRequestManager alloc]
          initWithDelegate:self
          user:[VKUser currentUser]];
    rm.offlineMode = [AppDelegate sharedDelegate].offlineMode;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarTappedAction:)
                                                 name:kStatusBarTappedNotification
                                               object:nil];
    self.tableView.scrollsToTop = YES;
    self.tableView.separatorColor = [UIColor grayColor];
    
    self.lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
    self.lpgr.minimumPressDuration = 1.0f;
    self.lpgr.allowableMovement = 100.0f;
    
    [self.view addGestureRecognizer:self.lpgr];
}

- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)sender
{
    if(self.duration.count){
        if ([sender isEqual:self.lpgr]) {
            if (sender.state == UIGestureRecognizerStateBegan)
            {
                [self.tableView setEditing:YES animated:YES];
                [((CenterViewController*)self.view.superview.nextResponder).editBtn setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
                ((CenterViewController*)self.view.superview.nextResponder).editBtn.tag = 1;
            }
        }
    }
}


- (void)refresh {
    [self performSelector:@selector(refreshView) withObject:nil afterDelay:2.0];
}

- (void)     VKRequest:(VKRequest *)request
connectionErrorOccured:(NSError *)error
{
    [self.activityIndicatorView stopAnimating];
}

-(void) VKRequest:(VKRequest *)request responseErrorOccured:(id)error {
    NSNumber *err = [error objectForKey:@"error_code"];
    if(err.integerValue == 5) {
        [self.activityIndicatorView stopAnimating];
        [[AppDelegate sharedDelegate] renewToken];
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Данные не были получены" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [self.activityIndicatorView stopAnimating];
}

- (void)refreshView {
    if(self.stateOfMusic == playlist) {
        [self playlistMode];
        [self stopLoading];
        return;
    }
    if(self.s_names.count){
        self.s_names = [NSMutableArray array];
        self.s_songs = [NSMutableArray array];
        self.s_duration = [NSMutableArray array];
        self.s_idAudio = [NSMutableArray array];
        self.s_idUser = [NSMutableArray array];
        self.s_lyricsID = [NSMutableArray array];
        self.s_urls = [NSMutableArray array];
    }
    searchBar.text = @"";
    if(self.stateOfMusic == 0) {
        rm.startAllRequestsImmediately = NO;
        VKRequest *s = [rm audioGet:@{@"need_user":@"0",@"count":@1500}];
        s.cacheLiveTime = VKCacheLiveTimeNever;
        [s start];
        rm.startAllRequestsImmediately = YES;
    }
    else if(self.stateOfMusic == 1)
        [rm audioGetPopular:@{@"count":@"300"}];
    else if(self.stateOfMusic == 3)
        [self offlineMode];
    else if(self.stateOfMusic == 4)
    {
        NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
        NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
        NSString *target = [NSString stringWithFormat:@"%@_%@",idU,idA];
        [rm audioGetRecommendations:@{@"target_audio":target,@"shuffle":@"1"}];
    }
    else if(self.stateOfMusic == friends)
    {
        if(self.duration.count == 0)
            [rm friendsGet:@{@"fields":@"nickname,photo_50",@"order":@"hints"}];
    }
    else if (self.stateOfMusic == group) {
        if(self.duration.count == 0)
            [rm groupsGet:@{@"count":@"1000",@"extended":@"1"}];
    }
    else if(self.stateOfMusic == album)
    {
        if(self.duration.count == 0)
            [rm audioGetAlbums:@{@"count":@"100"}];
    }
    else if (self.stateOfMusic == status)
    {
        VKRequest *s = [rm audioGetBroadcastList:@{@"active":@"1"}];
        s.cacheLiveTime = VKCacheLiveTimeNever;
        [s start];
        rm.startAllRequestsImmediately = YES;
    }
    [self stopLoading];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.stateOfMusic == playlist) {
        return UITableViewCellEditingStyleDelete;
    }
    else {
        return UITableViewCellEditingStyleNone;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    
    if(self.s_names.count){
        id obj = [self.s_names objectAtIndex:sourceIndexPath.row];
        [self.s_names removeObjectAtIndex:sourceIndexPath.row];
        [self.s_names insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.s_songs objectAtIndex:sourceIndexPath.row];
        [self.s_songs removeObjectAtIndex:sourceIndexPath.row];
        [self.s_songs insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.s_idAudio objectAtIndex:sourceIndexPath.row];
        [self.s_idAudio removeObjectAtIndex:sourceIndexPath.row];
        [self.s_idAudio insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.s_idUser objectAtIndex:sourceIndexPath.row];
        [self.s_idUser removeObjectAtIndex:sourceIndexPath.row];
        [self.s_idUser insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.s_duration objectAtIndex:sourceIndexPath.row];
        [self.s_duration removeObjectAtIndex:sourceIndexPath.row];
        [self.s_duration insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.s_lyricsID objectAtIndex:sourceIndexPath.row];
        [self.s_lyricsID removeObjectAtIndex:sourceIndexPath.row];
        [self.s_lyricsID insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.s_urls objectAtIndex:sourceIndexPath.row];
        [self.s_urls removeObjectAtIndex:sourceIndexPath.row];
        [self.s_urls insertObject:obj atIndex:destinationIndexPath.row];
    }
    else {
        id obj = [self.names objectAtIndex:sourceIndexPath.row];
        [self.names removeObjectAtIndex:sourceIndexPath.row];
        [self.names insertObject:obj atIndex:destinationIndexPath.row];
        
        if(self.songs.count > sourceIndexPath.row) {
        obj = [self.songs objectAtIndex:sourceIndexPath.row];
        [self.songs removeObjectAtIndex:sourceIndexPath.row];
        [self.songs insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.idAudio objectAtIndex:sourceIndexPath.row];
        [self.idAudio removeObjectAtIndex:sourceIndexPath.row];
        [self.idAudio insertObject:obj atIndex:destinationIndexPath.row];
        
        obj = [self.idUser objectAtIndex:sourceIndexPath.row];
        [self.idUser removeObjectAtIndex:sourceIndexPath.row];
        [self.idUser insertObject:obj atIndex:destinationIndexPath.row];
        if(self.duration.count){
            obj = [self.duration objectAtIndex:sourceIndexPath.row];
            [self.duration removeObjectAtIndex:sourceIndexPath.row];
            [self.duration insertObject:obj atIndex:destinationIndexPath.row];
        }
        if(self.lyricsID.count) {
            obj = [self.lyricsID objectAtIndex:sourceIndexPath.row];
            [self.lyricsID removeObjectAtIndex:sourceIndexPath.row];
            [self.lyricsID insertObject:obj atIndex:destinationIndexPath.row];
        }
        }
        if([AppDelegate sharedDelegate].urls.count){
            obj = [[AppDelegate sharedDelegate].urls objectAtIndex:sourceIndexPath.row];
            [[AppDelegate sharedDelegate].urls removeObjectAtIndex:sourceIndexPath.row];
            [[AppDelegate sharedDelegate].urls insertObject:obj atIndex:destinationIndexPath.row];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self refreshView];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //    if(self.stateOfMusic == home )
    //        return YES;
    //    else return NO;
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if(self.stateOfMusic == home ) {
            [[AppDelegate sharedDelegate] deleteMusicByIdAudio:[self.idAudio objectAtIndex:indexPath.row] idUser:[self.idUser objectAtIndex:indexPath.row]];
            
            [self offlineMode];
        }
        else {
            if(self.duration.count != 0) {
                [[AppDelegate sharedDelegate] removeFromAlbumTrackWithIdAudio:[self.idAudio objectAtIndex:indexPath.row] IdUser:[self.idUser objectAtIndex:indexPath.row]];
                
            }
            else {
                [[AppDelegate sharedDelegate] deleteAlbumWithName:[self.names objectAtIndex:indexPath.row]];
                [self playlistMode];
            }
        }
        [self.tableView reloadData];
    }
    if(editingStyle == UITableViewCellEditingStyleInsert) {
        
    }
}

-(void)updateCell:(NSNotification*)notification
{
    NSDictionary* userInfo = notification.userInfo;
    int messageTotal = [[userInfo objectForKey:@"percent"] intValue];
    NSIndexPath *curIndexPath = [userInfo objectForKey:@"currentIndexPath"];
    if(curIndexPath.section == self.stateOfMusic){
        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cel = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:curIndexPath.row inSection:0]];
            if([cel isKindOfClass:[MusicCell class]]) {
                MusicCell* cell = (MusicCell*)cel;
                cell.downloadBtn.hidden = NO;
                [cell.downloadBtn setImage:nil forState:UIControlStateNormal];
                [cell.activity stopAnimating];
                [cell.downloadBtn setTitle:[NSString stringWithFormat:@"%d%%",messageTotal] forState:UIControlStateNormal];
                if(messageTotal >= 100)
                    cell.downloadBtn.hidden = YES;
            }
        });
    }
}

-(void)downoadSucsess:(NSNotification*)notification
{
    NSDictionary* userInfo = notification.object;
    NSIndexPath *curIndexPath = [userInfo objectForKey:@"currentIndexPath"];
    BOOL isOK =((NSNumber*)[userInfo objectForKey:@"isOK"]).boolValue;
    MusicCell* cell = (MusicCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:curIndexPath.row inSection:0]];
    if(cell && curIndexPath.section == self.stateOfMusic){
        dispatch_async(dispatch_get_main_queue(), ^{
            if(isOK)
                cell.downloadBtn.hidden = YES;
        });
    }
    if(self.stateOfMusic == home)
        [self offlineMode];
    [waitingIndex removeObject:curIndexPath];
}

-(void)searchMode
{
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [searchBar setSearchBarStyle:UISearchBarStyleProminent];
    searchBar.barStyle = UIBarStyleDefault;
    searchBar.barTintColor = [UIColor clearColor];
    searchBar.backgroundImage = [UIImage new];
    searchBar.delegate = self;
    
    self.tableView.tableHeaderView = searchBar;
    //[self.view addSubview:searchBar];
    
    
    [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBars
{
    if(self.stateOfMusic == search) {
        
        [rm audioSearch:@{@"q":searchBar.text,
                          @"count":@300}];
        rm.delegate = self;
    }
    if(self.stateOfMusic == home || self.stateOfMusic == myMusic) {
        self.s_names = [NSMutableArray array];
        self.s_songs = [NSMutableArray array];
        self.s_duration = [NSMutableArray array];
        self.s_idAudio = [NSMutableArray array];
        self.s_idUser = [NSMutableArray array];
        self.s_lyricsID = [NSMutableArray array];
        self.s_urls = [NSMutableArray array];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for(int i = 0; i < self.names.count; i++) {
                if([((NSString*)self.names[i]).lowercaseString rangeOfString:searchBar.text.lowercaseString].location != NSNotFound ||
                   [((NSString*)self.songs[i]).lowercaseString rangeOfString:searchBar.text.lowercaseString].location != NSNotFound) {
                    [self.s_names addObject:self.names[i]];
                    [self.s_songs addObject:self.songs[i]];
                    [self.s_duration addObject:self.duration[i]];
                    [self.s_idAudio addObject:self.idAudio[i]];
                    [self.s_idUser addObject:self.idUser[i]];
                    [self.s_lyricsID addObject:self.lyricsID[i]];
                    [self.s_urls addObject:[AppDelegate sharedDelegate].urls[i]];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    }
    [searchBar resignFirstResponder];
    
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] == 0) {
        self.s_names = [NSMutableArray array];
        self.s_songs = [NSMutableArray array];
        self.s_duration = [NSMutableArray array];
        self.s_idAudio = [NSMutableArray array];
        self.s_idUser = [NSMutableArray array];
        self.s_lyricsID = [NSMutableArray array];
        self.s_urls = [NSMutableArray array];
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:self->searchBar afterDelay:0];
    }
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar
{
    [self->searchBar resignFirstResponder];
    [self.tableView reloadData];
}

-(void)changeView:(int)stateL
{
    if(self.s_names.count){
        self.s_names = [NSMutableArray array];
        self.s_songs = [NSMutableArray array];
        self.s_duration = [NSMutableArray array];
        self.s_idAudio = [NSMutableArray array];
        self.s_idUser = [NSMutableArray array];
        self.s_lyricsID = [NSMutableArray array];
        self.s_urls = [NSMutableArray array];
    }
    self.stateOfMusic = stateL;
    switch (stateL) {
        case myMusic:
            [self searchMode];
            break;
        case 1:
            self.tableView.tableHeaderView = nil;
            break;
        case 2:
            [self searchMode];
            self.names = nil;
            [self.tableView reloadData];
            break;
        case home:
            [self searchMode];
            break;
        default:
            self.tableView.tableHeaderView = nil;
            break;
    }
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}


- (void)VKRequest:(VKRequest *)request
         response:(id)response
{
    if([request.signature isEqualToString:@"audioSetBroadcast:"]){
        return;
    }
    else if([request.signature isEqualToString:@"audioGetBroadcastList:"])
    {
        self.names = [NSMutableArray array];
        self.songs = [NSMutableArray array];
        self.idUser = [NSMutableArray array];
        self.idAudio = [NSMutableArray array];
        self.duration = [NSMutableArray array];
        self.lyricsID = [NSMutableArray array];
        self.bitrate = [NSMutableDictionary dictionary];
        [AppDelegate sharedDelegate].urls = [NSMutableArray array];
        NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        self.countFriends = idFriends.count;
        for(NSDictionary* idUser in idFriends)
        {
            if([idUser isKindOfClass:[NSDictionary class]])
            {
                if([idUser isKindOfClass:[NSNumber class]]){
                    self.countFriends--;
                    continue;
                }
                NSDictionary *audio =[idUser objectForKey:@"status_audio"];
                NSString *name =[idUser objectForKey:@"first_name"];
                name = [NSString stringWithFormat:@"%@.%@",[name substringToIndex:1],[idUser objectForKey:@"last_name"]];
                [self.names addObject:name];
                NSString *songs = [NSString stringWithFormat:@"%@\n%@",[audio objectForKey:@"artist"],[audio objectForKey:@"title"]];
                [self.songs addObject:songs];
                if([audio objectForKey:@"lyrics_id"]) {
                    [self.lyricsID addObject:[audio objectForKey:@"lyrics_id"]];
                }
                [self.idUser addObject:[audio objectForKey:@"owner_id"]];
                [self.idAudio addObject:[audio objectForKey:@"aid"]];
                [self.duration addObject:[audio objectForKey:@"duration"]];
                [[AppDelegate sharedDelegate].urls addObject:[NSURL URLWithString:[audio objectForKey:@"url"]]];
            }
            
            //[[AppDelegate sharedDelegate].urls addObject:[NSURL URLWithString:[idUser objectForKey:@"url"]]];
        }
        
    }
    else if ([request.signature isEqualToString:@"newsfeedGet:"]){
        self.names = [NSMutableArray array];
        self.songs = [NSMutableArray array];
        self.idUser = [NSMutableArray array];
        self.idAudio = [NSMutableArray array];
        self.duration = [NSMutableArray array];
        self.lyricsID = [NSMutableArray array];
        self.bitrate = [NSMutableDictionary dictionary];
        [AppDelegate sharedDelegate].urls = [NSMutableArray array];
        NSDictionary *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        self.countFriends = idFriends.count;
        id a = [idFriends objectForKey:@"items"];
        for(NSDictionary* idUser in a)
        {
            if([idUser isKindOfClass:[NSNumber class]]){
                self.countFriends--;
                continue;
            }
            for(NSDictionary *attach in [idUser objectForKey:@"attachments"]) {
                if([[attach objectForKey:@"type"] isEqualToString:@"audio"]) {
                    NSDictionary* audio = [attach objectForKey:@"audio"];
                    [self.names addObject:[audio objectForKey:@"artist"]];
                    [self.songs addObject:[audio objectForKey:@"title"]];
                    [self.idUser addObject:[audio objectForKey:@"owner_id"]];
                    [self.lyricsID addObject:[audio objectForKey:@"lyrics_id"]?[audio objectForKey:@"lyrics_id"]:@""];
                    [self.idAudio addObject:[audio objectForKey:@"aid"]];
                    [self.duration addObject:[audio objectForKey:@"duration"]];
                    
                    [[AppDelegate sharedDelegate].urls addObject:[NSURL URLWithString:[audio objectForKey:@"url"]]];
                }
            }
        }
    }
    else if ([request.signature isEqualToString:@"wallGet:"]) {
        NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        self.countFriends = idFriends.count;
        NSMutableArray *audios = [NSMutableArray array];
        for(NSDictionary* idUser in idFriends)
        {
            if([idUser isKindOfClass:[NSNumber class]]){
                self.countFriends--;
                continue;
            }
            NSDictionary *media = [idUser objectForKey:@"media"];
            if([[media objectForKey:@"type"] isEqualToString:@"audio"]) {
                NSString *owner = [media objectForKey:@"owner_id"];
                NSString *item = [media objectForKey:@"item_id"];
                [audios addObject:[NSString stringWithFormat:@"%@_%@",owner,item]];
            }
            //[[AppDelegate sharedDelegate].urls addObject:[NSURL URLWithString:[idUser objectForKey:@"url"]]];
        }
        rm = [[VKRequestManager alloc]
              initWithDelegate:self
              user:[VKUser currentUser]];
        NSString *str =[audios componentsJoinedByString:@","];
        
        [rm audioGetByID:@{@"audios":str}];
        return;
    }
    else if([request.signature isEqualToString:@"audioGetAlbums:"])
    {
        self.names = [NSMutableArray array];
        self.songs = [NSMutableArray array];
        self.idUser = [NSMutableArray array];
        self.idAudio = [NSMutableArray array];
        self.duration = [NSMutableArray array];
        self.lyricsID = [NSMutableArray array];
        self.bitrate = [NSMutableDictionary dictionary];
        [AppDelegate sharedDelegate].urls = [NSMutableArray array];
        NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
        self.countFriends = idFriends.count;
        for(NSDictionary* idUser in idFriends)
        {
            if([idUser isKindOfClass:[NSNumber class]]){
                self.countFriends--;
                continue;
            }
            [self.names addObject:[idUser objectForKey:@"title"]];
            [self.idUser addObject:[idUser objectForKey:@"album_id"]];
            
            //[[AppDelegate sharedDelegate].urls addObject:[NSURL URLWithString:[idUser objectForKey:@"url"]]];
        }
    }
    else
        if([request.signature isEqualToString:@"friendsGet:"])
        {
            self.names = [NSMutableArray array];
            self.songs = [NSMutableArray array];
            self.idUser = [NSMutableArray array];
            self.idAudio = [NSMutableArray array];
            self.duration = [NSMutableArray array];
            self.lyricsID = [NSMutableArray array];
            [AppDelegate sharedDelegate].urls = [NSMutableArray array];
            NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
            self.countFriends = idFriends.count;
            for(NSDictionary* idUser in idFriends)
            {
                if([idUser isKindOfClass:[NSNumber class]]){
                    self.countFriends--;
                    continue;
                }
                [self.names addObject:[idUser objectForKey:@"first_name"]];
                [self.songs addObject:[idUser objectForKey:@"last_name"]];
                [self.idUser addObject:[idUser objectForKey:@"user_id"]];
                [self.idAudio addObject:[idUser objectForKey:@"photo_50"]];
            }
        }
        else if([request.signature isEqualToString:@"groupsGet:"]) {
            self.names = [NSMutableArray array];
            self.songs = [NSMutableArray array];
            self.idUser = [NSMutableArray array];
            self.idAudio = [NSMutableArray array];
            self.duration = [NSMutableArray array];
            self.lyricsID = [NSMutableArray array];
            [AppDelegate sharedDelegate].urls = [NSMutableArray array];
            NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
            self.countFriends = idFriends.count;
            for(NSDictionary* idUser in idFriends)
            {
                if([idUser isKindOfClass:[NSNumber class]]){
                    self.countFriends--;
                    continue;
                }
                [self.names addObject:[idUser objectForKey:@"name"]];
                [self.idUser addObject:[idUser objectForKey:@"gid"]];
                [self.idAudio addObject:[idUser objectForKey:@"photo"]];
            }
        }
        else{
            self.names = [NSMutableArray array];
            self.songs = [NSMutableArray array];
            self.idUser = [NSMutableArray array];
            self.idAudio = [NSMutableArray array];
            self.duration = [NSMutableArray array];
            self.bitrate = [NSMutableDictionary dictionary];
            self.lyricsID = [NSMutableArray array];
            [AppDelegate sharedDelegate].urls = [NSMutableArray array];
            NSArray *idFriends = [(NSDictionary*)response objectForKey:@"response"];
            self.countFriends = idFriends.count;
            for(NSDictionary* idUser in idFriends)
            {
                if([idUser isKindOfClass:[NSNumber class]]){
                    self.countFriends--;
                    continue;
                }
                [self.names addObject:[idUser objectForKey:@"artist"]];
                [self.songs addObject:[idUser objectForKey:@"title"]];
                [self.idUser addObject:[idUser objectForKey:@"owner_id"]];
                [self.lyricsID addObject:[idUser objectForKey:@"lyrics_id"]?[idUser objectForKey:@"lyrics_id"]:@""];
                [self.idAudio addObject:[idUser objectForKey:@"aid"]];
                [self.duration addObject:[idUser objectForKey:@"duration"]];
                
                [[AppDelegate sharedDelegate].urls addObject:[NSURL URLWithString:[idUser objectForKey:@"url"]]];
            }
        }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
        [self.tableView reloadData];
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        if(self.duration.count == 0) {
            ((CenterViewController*)self.view.superview.nextResponder).editBtn.hidden = YES;
        }
        else ((CenterViewController*)self.view.superview.nextResponder).editBtn.hidden = NO;
    });
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.s_names.count?self.s_names.count: self.names.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(isFour) {
        if([cell isKindOfClass:[MusicCell class]]) {
            (( MusicCell *)cell).nameLbl.font = [UIFont fontWithName:@"AppleSDGothicNeo-UltraLight" size:16];
            (( MusicCell *)cell).songLbl.font = [UIFont fontWithName:@"AppleSDGothicNeo-UltraLight" size:16];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.duration.count != 0 && self.names.count > indexPath.row){
        MusicCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MusicCell"];
        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MusicCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.backgroundColor = [UIColor clearColor];
            
        }
        int row = (int)indexPath.row;
        NSString *name;
        NSString *song;
        NSNumber *idAudio;
        NSNumber *idUser;
        if(self.s_names.count){
            name = [self.s_names objectAtIndex:row];
            song = [self.s_songs objectAtIndex:row];
            idAudio = [self.s_idAudio objectAtIndex:row];
            idUser = [self.s_idUser objectAtIndex:row];
        }
        else{
            name = [self.names objectAtIndex:row];
            song = [self.songs objectAtIndex:row];
            idAudio = [self.idAudio objectAtIndex:row];
            idUser = [self.idUser objectAtIndex:row];
        }
        if(![self.selectedIndex containsObject:@(indexPath.row)]) {
            cell.btn.image = [UIImage imageNamed:@"audioplayer_add"];
        }
        else {
            cell.btn.image = [UIImage imageNamed:@"photo_panel_ok.png"];
        }
        cell.nameLbl.text = name;
        cell.songLbl.text = song;
        cell.tag = indexPath.row;
        cell.bitrateLbl.text = @"";
        if(self.duration.count > row) {
            NSNumber *duration = [self.duration objectAtIndex:row];
            int min = duration.intValue/60;
            int sec = duration.intValue%60;
            NSString *secondsString;
            if(sec < 10)
                secondsString = [NSString stringWithFormat:@"0%d",sec];
            else
            {
                secondsString = [NSString stringWithFormat:@"%d",sec];
            }
            if(duration != 0)
                cell.durationLbl.text = [NSString stringWithFormat:@"%d:%@",min,secondsString];
        }
        else cell.durationLbl.text = @"";
        if([MusicManager sharedMusicManager].bitrate){
            __block NSString* bitrate = [self.bitrate objectForKey:[NSNumber numberWithInt:row]];
            if(!bitrate){
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                dispatch_async(queue, ^(void) {
                    NSURL *url = [[AppDelegate sharedDelegate].urls objectAtIndex:row];
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:1];
                    [request setHTTPMethod:@"HEAD"];
                    NSURLResponse *response;
                    [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:nil];
                    NSNumber *duration  =(self.duration.count > row)?[self.duration objectAtIndex:row]:@0;
                    int kbyte = (int)([response expectedContentLength]/128);
                    if(duration.intValue != 0){
                        
                        __block int bitrateInt = kbyte/([duration integerValue]);
                        if (bitrateInt) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (cell.tag == indexPath.row) {
                                    if(bitrateInt < 112)
                                        bitrateInt = 112;
                                    else if (bitrateInt < 128)
                                        bitrateInt = 128;
                                    else if (bitrateInt < 160)
                                        bitrateInt = 160;
                                    else if (bitrateInt < 192)
                                        bitrateInt = 192;
                                    else if (bitrateInt < 256)
                                        bitrateInt = 256;
                                    else if (bitrateInt < 320)
                                        bitrateInt = 320;
                                    bitrate = [NSString stringWithFormat:@"%d\nkbps",bitrateInt];
                                    cell.bitrateLbl.text = bitrate;
                                    [self.bitrate setObject:bitrate forKey:[NSNumber numberWithInt:row]];
                                    //[cell setNeedsLayout];
                                }});}
                        else {
                            //[cell setNeedsLayout];
                        }}});}
            else {
                if(bitrate.length > 0 && [bitrate rangeOfString:@"null"].location == NSNotFound)
                    cell.bitrateLbl.text = bitrate;
            }
        }
        else {
            cell.bitrateLbl.text = @"";
        }
        
        BOOL isDownloaded;
        isDownloaded = ([[AppDelegate sharedDelegate] musicByIdAudio:idAudio andIdUser:idUser] != nil);
        if([[MusicManager sharedMusicManager].playIndexPlaylist isEqual:[NSIndexPath indexPathForRow:indexPath.row inSection:self.stateOfMusic]])
        {
            cell.currentPlay.hidden = NO;
        }
        else
        {
            cell.currentPlay.hidden = YES;
        }
        if(self.stateOfMusic == home)
        {
            cell.downloadBtn.hidden = NO;
            [cell.downloadBtn setImage:nil forState:UIControlStateNormal];
            [cell.downloadBtn setTitle:@"-" forState:UIControlStateNormal];
            cell.downloadBtn.tag = row;
        }
        else{
            if(isDownloaded == NO &&![waitingIndex containsObject:[NSIndexPath indexPathForRow:indexPath.row inSection:self.stateOfMusic]])
            {
                cell.downloadBtn.hidden = NO;
                [cell.downloadBtn setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
                [cell.downloadBtn setTitle:@"+" forState:UIControlStateNormal];
                cell.downloadBtn.tag = row;
            }
            else{
                if([waitingIndex containsObject:[NSIndexPath indexPathForRow:indexPath.row inSection:self.stateOfMusic]])
                {
                    [cell.activity startAnimating];
                    [cell.downloadBtn setImage:nil forState:UIControlStateNormal];
                    [cell.downloadBtn setTitle:@"  " forState:UIControlStateNormal];
                }
                else
                    cell.downloadBtn.hidden = YES;
            }
        }
        if(tableView.editing) {
            cell.nameLbl.frame = CGRectMake(35, 0, 200, CGRectGetHeight(cell.nameLbl.frame));
            cell.songLbl.frame = CGRectMake(35, 25, 180, CGRectGetHeight(cell.nameLbl.frame));
        }
        else {
            cell.nameLbl.frame = CGRectMake(15, 0, 240, CGRectGetHeight(cell.nameLbl.frame));
            cell.songLbl.frame = CGRectMake(15, 25, 240, CGRectGetHeight(cell.nameLbl.frame));
        }
        return cell;
    }
    else{
        if(self.idAudio.count == 0)
        {
            PlaylistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistCell"];
            if (cell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"PlaylistCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                
            }
            int row = (int)indexPath.row;
            NSString *name;
            NSString *song;
            if(self.songs.count)
                song = [self.songs objectAtIndex:row];
            else song = @"";
            if(self.names.count > row)
                name = [self.names objectAtIndex:row];
            else {
                name = @"Нет данных для отображения";
                cell.userInteractionEnabled = NO;
            }
            cell.nameLbl.text = [NSString stringWithFormat:@"%@ %@",name,song];
            
            cell.tag = indexPath.row;
            return cell;
        }
        else{
            FriendsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendsCell"];
            if (cell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"FriendsCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                
            }
            int row = (int)indexPath.row;
            NSString *name;
            if(self.names.count > row)
                name = [self.names objectAtIndex:row];
            NSString *song;
            if(self.songs.count > row)
                song = [self.songs objectAtIndex:row];
            else song = @"";
            cell.nameLbl.text = [NSString stringWithFormat:@"%@ %@",name,song];
            
            cell.tag = indexPath.row;
            if(self.idAudio.count == 0)
            {
                cell.avaImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"11.png"]];
                return cell;
            }
            if(self.idAudio.count < row) return cell;
            UIImage *image = [cacheImage objectForKey: [self.idAudio objectAtIndex:row]];
            if(!image){
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                dispatch_async(queue, ^(void) {
                    
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self.idAudio objectAtIndex:row]]];
                    
                    UIImage* image = [[UIImage alloc] initWithData:imageData];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (cell.tag == indexPath.row) {
                                
                                //                                UIImage *inputImage = image;
                                //
                                //                                CGColorSpaceRef colorSapce = CGColorSpaceCreateDeviceGray();
                                //                                CGContextRef context = CGBitmapContextCreate(nil, inputImage.size.width, inputImage.size.height, 8, inputImage.size.width, colorSapce, kCGImageAlphaNone);
                                //                                CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
                                //                                CGContextSetShouldAntialias(context, NO);
                                //                                CGContextDrawImage(context, CGRectMake(0, 0, inputImage.size.width, inputImage.size.height), [inputImage CGImage]);
                                //
                                //                                CGImageRef bwImage = CGBitmapContextCreateImage(context);
                                //                                CGContextRelease(context);
                                //                                CGColorSpaceRelease(colorSapce);
                                //
                                //                                UIImage *resultImage = [UIImage imageWithCGImage:bwImage]; // This is result B/W image.
                                //                                CGImageRelease(bwImage);
                                
                                cell.avaImageView.layer.masksToBounds = YES;
                                cell.avaImageView.layer.cornerRadius = cell.avaImageView.frame.size.height/2;
                                cell.avaImageView.image = image;
                                if(self.idAudio.count > indexPath.row)
                                    [cacheImage setObject:image forKey:[self.idAudio objectAtIndex:indexPath.row]];
                                [cell setNeedsLayout];
                            }
                        });
                    }
                });
            }
            else
            {
                cell.avaImageView.image = image;
            }
            
            return cell;
        }
    }
    return nil;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.duration.count != 0)
        return 55;
    else return 44;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.isEditing) {
        if([self.selectedIndex containsObject:@(indexPath.row)]) {
            [self.selectedIndex removeObject:@(indexPath.row)];
        }
        else {
            [self.selectedIndex addObject:@(indexPath.row)];
        }
        //reload the cell
        [tableView reloadRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:indexPath.row inSection:0]]
                         withRowAnimation: UITableViewRowAnimationNone];
        return;
    }
    if(self.stateOfMusic == playlist && self.duration.count == 0) {
        Album *album = [[AppDelegate sharedDelegate] albumByName:self.names[indexPath.row]];
        self.names = [NSMutableArray array];
        self.songs = [NSMutableArray array];
        self.idUser = [NSMutableArray array];
        self.idAudio = [NSMutableArray array];
        self.duration = [NSMutableArray array];
        self.bitrate = [NSMutableDictionary dictionary];
        self.lyricsID = [NSMutableArray array];
        NSMutableArray *songsUrl = [NSMutableArray array];
        NSArray *allMusic = album.tracks.allObjects;
        [allMusic enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Music *music, NSUInteger idx, BOOL *stop){
            [self.names addObject:music.artist?music.artist:@""];
            [self.songs addObject:music.songName?music.songName:@""];
            [self.idAudio addObject:music.idAudio?music.idAudio:@""];
            [self.idUser addObject:music.idUser?music.idUser:@""];
            [self.duration addObject:music.duration?music.duration:@""];
            [self.bitrate setObject:music.bitrate?music.bitrate:@"" forKey:[NSNumber numberWithUnsignedInteger:idx]];
            [self.lyricsID addObject:@(music.text.intValue)];
            NSString *unique = [[NSString stringWithFormat:@"%@-%@",music.artist,music.songName] stringByAppendingString:@".mp3"];
            unique = [unique stringByReplacingOccurrencesOfString:@"/" withString:@" "];
            NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            documents = [documents stringByAppendingPathComponent:@"Music/"];
            NSString *filePath = [documents stringByAppendingPathComponent:unique];
            
            [songsUrl addObject:[NSURL fileURLWithPath:filePath]];
        }];
        [AppDelegate sharedDelegate].urls = songsUrl;
        [self.tableView reloadData];
        return;
    }
    if(self.stateOfMusic == groupWall && self.duration.count == 0) {
        [self.activityIndicatorView startAnimating];
        NSNumber *number = [self.idUser objectAtIndex:indexPath.row];
        [rm wallGet:@{@"owner_id":@(-1*number.integerValue),@"count":@"100"}];
        return;
    }
    if((self.stateOfMusic == friends || self.stateOfMusic == group) && self.duration.count == 0)
    {
        NSNumber *number = [self.idUser objectAtIndex:indexPath.row];
        NSString *str = [NSString stringWithFormat:@"%@",(self.stateOfMusic == group)?@(-1*number.integerValue):number];
        [self.activityIndicatorView startAnimating];
        [rm audioGet:@{@"owner_id":str,@"count":@1500}];
    }
    else
        if(self.stateOfMusic == album && self.duration.count == 0)
        {
            NSString *str = [NSString stringWithFormat:@"%@",[self.idUser objectAtIndex:indexPath.row]];
            [self.activityIndicatorView startAnimating];
            [rm audioGet:@{@"album_id":str,@"count":@1500}];
        }
        else{
            if(self.s_names.count){
                [MusicManager sharedMusicManager].listPlayNames = self.s_names;
                [MusicManager sharedMusicManager].listPlaySongs = self.s_songs ;
                [MusicManager sharedMusicManager].listPlayIdUser = self.s_idUser;
                [MusicManager sharedMusicManager].listPlayIdAudio = self.s_idAudio ;
                [MusicManager sharedMusicManager].listPlayDuration = self.s_duration ;
                [MusicManager sharedMusicManager].listPlayLyrics = self.s_lyricsID;
                [MusicManager sharedMusicManager].listPlayUrl = self.s_urls;
            }
            else{
                [MusicManager sharedMusicManager].listPlayNames = self.names;
                [MusicManager sharedMusicManager].listPlaySongs = self.songs ;
                [MusicManager sharedMusicManager].listPlayIdUser = self.idUser;
                [MusicManager sharedMusicManager].listPlayIdAudio = self.idAudio ;
                [MusicManager sharedMusicManager].listPlayDuration = self.duration ;
                [MusicManager sharedMusicManager].listPlayLyrics = self.lyricsID;
                [MusicManager sharedMusicManager].listPlayUrl = [AppDelegate sharedDelegate].urls;
            }
            [MusicManager sharedMusicManager].stateOfMusic = self.stateOfMusic;
            [[MusicManager sharedMusicManager] playMusic:[NSIndexPath indexPathForRow:indexPath.row inSection:self.stateOfMusic] AndURL:nil];
            if([MusicManager sharedMusicManager].statusMusic){
                VKRequestManager *rmLocal = [[VKRequestManager alloc]
                                             initWithDelegate:self
                                             user:[VKUser currentUser]];
                rm.offlineMode = [AppDelegate sharedDelegate].offlineMode;
                NSNumber *idA = [[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSNumber *idU = [[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:[MusicManager sharedMusicManager].playIndexPlaylist.row];
                NSString *target = [NSString stringWithFormat:@"%@_%@",idU,idA];
                [rmLocal audioSetBroadcast:@{@"audio":target}];
            }
            [self.centerViewControl showMusicViewModal];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
}

-(IBAction)clickDownload:(UIButton*)button
{
    if([button.titleLabel.text isEqualToString:@"-"])
    {
        UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Удаление" message:@"Вы уверены, что хотите удалить трек?" delegate:self cancelButtonTitle:@"Удалить" otherButtonTitles:@"Нет", nil];
        tempButton = button;
        [deleteAlert show];
    }
    else
        [self download:button fromMusic:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == [alertView cancelButtonIndex])
    {
        if(alertView.tag == 2)
        {
            for (int i = max+1; i < self.names.count; i++) {
                UIButton *tempBtn = [[UIButton alloc] init];
                [tempBtn setTitle:@"+" forState:UIControlStateNormal];
                tempBtn.tag = i;
                [self download:tempBtn fromMusic:YES];
            }
        }
        else
            [self download:tempButton fromMusic:YES];
    }
}

-(void)checkForDownloaderAll
{
    NSArray *arr = (NSArray*)[lastFiveDownloader valueForKeyPath:@"@distinctUnionOfObjects.section"];
    if(arr.count == 0)
        return;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"section == %@", [NSNumber numberWithInt:self.stateOfMusic]];
    NSArray *filteredArray = [lastFiveDownloader filteredArrayUsingPredicate:predicate];
    NSArray *arr1 = [filteredArray valueForKeyPath:@"@distinctUnionOfObjects.row"];
    int min = [[arr1 valueForKeyPath:@"@min.intValue"] intValue];
    max = [[arr1 valueForKeyPath:@"@max.intValue"] intValue];
    if((max - min) < 4 && filteredArray.count > 3)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Скачать все треки?" delegate:self cancelButtonTitle:@"Да" otherButtonTitles:@"Нет", nil];
        alert.tag = 2;
        [alert show];
    }
}

- (void)download:(UIButton*)button fromMusic:(BOOL)notFromMusic
{
    MusicCell* cell = (MusicCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]];
    if([cell.activity isAnimating])
    {
        [button setTitle:@"  " forState:UIControlStateNormal];
        for (MusicDownloader *operation in operationQueue.operations) {
            if([operation.url isEqual:[[AppDelegate sharedDelegate].urls objectAtIndex:button.tag]])
            {
                [cell.activity stopAnimating];
                NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:self.stateOfMusic];
                [waitingIndex removeObject:path];
                [operation cancel];
                [button setTitle:@"+" forState:UIControlStateNormal];
                return;
            }
        }
        return;
    }
    if([button.titleLabel.text isEqualToString:@"+"]){
        [button setTitle:@"  " forState:UIControlStateNormal];
        if(notFromMusic){
            
            MusicDownloader *downloader = [[MusicDownloader alloc] initWithArtist:[self.names objectAtIndex:button.tag] songName:[self.songs objectAtIndex:button.tag] idAudio:[self.idAudio objectAtIndex:button.tag] idUser:[self.idUser objectAtIndex:button.tag] duration:[self.duration objectAtIndex:button.tag] bitrate:[self.bitrate objectForKey:@(button.tag)] text:[self.lyricsID objectAtIndex:button.tag]];
            downloader.url = [[AppDelegate sharedDelegate].urls objectAtIndex:button.tag];
            NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:self.stateOfMusic];
            downloader.currentIndexPath = path;
            if(lastFiveDownloader.count > 10)
                [lastFiveDownloader removeObjectAtIndex:0];
            [lastFiveDownloader addObject:path];
            [waitingIndex addObject:path];
            [operationQueue addOperation:downloader];
            MusicCell* cell = (MusicCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]];
            [cell.activity startAnimating];
        }
        else
        {
            MusicDownloader *downloader = [[MusicDownloader alloc] initWithArtist:[[MusicManager sharedMusicManager].listPlayNames objectAtIndex:button.tag] songName:[[MusicManager sharedMusicManager].listPlaySongs objectAtIndex:button.tag] idAudio:[[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:button.tag] idUser:[[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:button.tag] duration:[[MusicManager sharedMusicManager].listPlayDuration objectAtIndex:button.tag] bitrate:@"320\nkbps" text:[[MusicManager sharedMusicManager].listPlayLyrics objectAtIndex:button.tag]];
            downloader.url = [[MusicManager sharedMusicManager].listPlayUrl objectAtIndex:button.tag];
            NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:[MusicManager sharedMusicManager].stateOfMusic];
            downloader.currentIndexPath = path;
            if(lastFiveDownloader.count > 10)
                [lastFiveDownloader removeObjectAtIndex:0];
            [lastFiveDownloader addObject:path];
            [waitingIndex addObject:path];
            [operationQueue addOperation:downloader];
            MusicCell* cell = (MusicCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]];
            [cell.activity startAnimating];
        }
        [self checkForDownloaderAll];
    }
    else{
        if([button.titleLabel.text isEqualToString:@"-"]){
            if(!notFromMusic){
                if([MusicManager sharedMusicManager].listPlayIdAudio.count > button.tag){
                    [[AppDelegate sharedDelegate] deleteMusicByIdAudio:[[MusicManager sharedMusicManager].listPlayIdAudio objectAtIndex:button.tag] idUser:[[MusicManager sharedMusicManager].listPlayIdUser objectAtIndex:button.tag]];
                    NSInteger row = [MusicManager sharedMusicManager].playIndexPlaylist.row;
                    if(row != 0)
                        row-=1;
                    else row = [MusicManager sharedMusicManager].listPlayIdAudio.count-1;
                    [MusicManager sharedMusicManager].playIndexPlaylist  = [NSIndexPath indexPathForRow:row inSection:[MusicManager sharedMusicManager].playIndexPlaylist.section];
                    [self.tableView reloadData];
                    [self tableView:self.tableView didSelectRowAtIndexPath:[MusicManager sharedMusicManager].playIndexPlaylist];
                    ((MusicViewController*)[AppDelegate sharedDelegate].musicViewController).downLbl.enabled = YES;
                }
            }
            else
            {
                [[AppDelegate sharedDelegate] deleteMusicByIdAudio:[self.idAudio objectAtIndex:button.tag] idUser:[self.idUser objectAtIndex:button.tag]];
                NSInteger row = [MusicManager sharedMusicManager].playIndexPlaylist.row;
                if(row > button.tag)
                    row-=1;
                [MusicManager sharedMusicManager].playIndexPlaylist  = [NSIndexPath indexPathForRow:row inSection:[MusicManager sharedMusicManager].playIndexPlaylist.section];
            }
            if([[AppDelegate sharedDelegate] getAllMusic].count == 0)
                [MusicManager sharedMusicManager].playIndexPlaylist = nil;
            if(notFromMusic){
                self.names = [NSMutableArray array];
                self.songs = [NSMutableArray array];
                self.idUser = [NSMutableArray array];
                self.idAudio = [NSMutableArray array];
                self.duration = [NSMutableArray array];
                self.bitrate = [NSMutableDictionary dictionary];
                NSMutableArray *songsUrl = [NSMutableArray array];
                NSArray *allMusic = [[AppDelegate sharedDelegate] getAllMusic];
                [allMusic enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Music *music, NSUInteger idx, BOOL *stop){
                    if(music.artist)
                        [self.names addObject:music.artist];
                    if(music.songName)
                        [self.songs addObject:music.songName];
                    if(music.idAudio)
                        [self.idAudio addObject:music.idAudio];
                    if(music.idUser)
                        [self.idUser addObject:music.idUser];
                    if(music.duration)
                        [self.duration addObject:music.duration];
                    if(music.bitrate)
                        [self.bitrate setObject:music.bitrate?music.bitrate:@"" forKey:[NSNumber numberWithUnsignedInteger:idx]];
                    NSString *unique = [[NSString stringWithFormat:@"%@-%@",music.artist,music.songName] stringByAppendingString:@".mp3"];
                    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                    documents = [documents stringByAppendingPathComponent:@"Music/"];
                    NSString *filePath = [documents stringByAppendingPathComponent:unique];
                    
                    [songsUrl addObject:[NSURL fileURLWithPath:filePath]];
                }];
                [AppDelegate sharedDelegate].urls = songsUrl;
                self.countFriends = self.names.count;
                [MusicManager sharedMusicManager].playIndexPlaylist = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }
}

-(BOOL)shuffleAll {
    if(waitingIndex.count != 0) {
        return NO;
    }
    NSInteger count = self.names.count;
    for (NSInteger i = 0; i < count; i++) {
        NSUInteger randomPos = arc4random_uniform((u_int32_t)count);
        if(randomPos == [MusicManager sharedMusicManager].playIndexPlaylist.row){
            [MusicManager sharedMusicManager].playIndexPlaylist = [NSIndexPath indexPathForRow:i inSection:[MusicManager sharedMusicManager].playIndexPlaylist.section];
        }
        else if (i == [MusicManager sharedMusicManager].playIndexPlaylist.row) {
            [MusicManager sharedMusicManager].playIndexPlaylist = [NSIndexPath indexPathForRow:randomPos inSection:[MusicManager sharedMusicManager].playIndexPlaylist.section];
        }
        if(self.names.count > randomPos && self.names.count > i) {
            [self.names exchangeObjectAtIndex:i withObjectAtIndex:randomPos];
        }
        if(self.songs.count > randomPos && self.songs.count > i) {
            [self.songs exchangeObjectAtIndex:i withObjectAtIndex:randomPos];
        }
        if(self.idAudio.count > randomPos && self.idAudio.count > i) {
            [self.idAudio exchangeObjectAtIndex:i withObjectAtIndex:randomPos];
        }
        if(self.idUser.count > randomPos && self.idUser.count > i) {
            [self.idUser exchangeObjectAtIndex:i withObjectAtIndex:randomPos];
        }
        
        if(self.duration.count > randomPos && self.duration.count > i) {
            [self.duration exchangeObjectAtIndex:i withObjectAtIndex:randomPos];
        }
        
        if(self.lyricsID.count > randomPos && self.lyricsID.count > i) {
            [self.lyricsID exchangeObjectAtIndex:i withObjectAtIndex:randomPos];
        }
        if([AppDelegate sharedDelegate].urls.count > randomPos && [AppDelegate sharedDelegate].urls.count > i) {
            [[AppDelegate sharedDelegate].urls exchangeObjectAtIndex:i withObjectAtIndex:randomPos];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    return YES;
}

-(void)playlistMode {
    ((CenterViewController*)self.view.superview.nextResponder).editBtn.hidden = NO;
    self.names = [NSMutableArray array];
    self.songs = [NSMutableArray array];
    self.idUser = [NSMutableArray array];
    self.idAudio = [NSMutableArray array];
    self.duration = [NSMutableArray array];
    self.bitrate = [NSMutableDictionary dictionary];
    self.lyricsID = [NSMutableArray array];
    NSArray *allMusic = [[AppDelegate sharedDelegate] getAllAlbum];
    [allMusic enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Album *album, NSUInteger idx, BOOL *stop){
        [self.names addObject:album.name?:@""];
        //        NSString *unique = [[NSString stringWithFormat:@"%@-%@",music.artist,music.songName] stringByAppendingString:@".mp3"];
        //        unique = [unique stringByReplacingOccurrencesOfString:@"/" withString:@" "];
        //        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        //        documents = [documents stringByAppendingPathComponent:@"Music/"];
        //        NSString *filePath = [documents stringByAppendingPathComponent:unique];
        
    }];
    [AppDelegate sharedDelegate].urls = nil;
    self.countFriends = self.names.count;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

-(void)offlineMode
{
    self.names = [NSMutableArray array];
    self.songs = [NSMutableArray array];
    self.idUser = [NSMutableArray array];
    self.idAudio = [NSMutableArray array];
    self.duration = [NSMutableArray array];
    self.bitrate = [NSMutableDictionary dictionary];
    self.lyricsID = [NSMutableArray array];
    NSMutableArray *songsUrl = [NSMutableArray array];
    NSArray *allMusic = [[AppDelegate sharedDelegate] getAllMusic];
    [allMusic enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Music *music, NSUInteger idx, BOOL *stop){
        [self.names addObject:music.artist?music.artist:@""];
        [self.songs addObject:music.songName?music.songName:@""];
        [self.idAudio addObject:music.idAudio?music.idAudio:@""];
        [self.idUser addObject:music.idUser?music.idUser:@""];
        [self.duration addObject:music.duration?music.duration:@""];
        [self.bitrate setObject:music.bitrate?music.bitrate:@"" forKey:[NSNumber numberWithUnsignedInteger:idx]];
        [self.lyricsID addObject:@(music.text.intValue)];
        NSString *unique = [[NSString stringWithFormat:@"%@-%@",music.artist,music.songName] stringByAppendingString:@".mp3"];
        unique = [unique stringByReplacingOccurrencesOfString:@"/" withString:@" "];
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        documents = [documents stringByAppendingPathComponent:@"Music/"];
        NSString *filePath = [documents stringByAppendingPathComponent:unique];
        
        [songsUrl addObject:[NSURL fileURLWithPath:filePath]];
    }];
    [AppDelegate sharedDelegate].urls = songsUrl;
    self.countFriends = self.names.count;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end

@implementation NSMutableArray (Helpers)

- (NSMutableArray *) shuffled
{
    // create temporary autoreleased mutable array
    NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[self count]];
    
    for (id anObject in self)
    {
        NSUInteger randomPos = arc4random()%([tmpArray count]+1);
        [tmpArray insertObject:anObject atIndex:randomPos];
    }
    
    return tmpArray;  // non-mutable autoreleased copy
}

@end
