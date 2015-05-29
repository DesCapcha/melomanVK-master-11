//
//  PlaylistTableViewController.m
//  VKiller
//
//  Created by iLego on 10.02.15.
//  Copyright (c) 2015 yury.mehov. All rights reserved.
//

#import "PlaylistTableViewController.h"

@interface PlaylistTableViewController ()

@end

@implementation PlaylistTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.bounces = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [MusicManager sharedMusicManager].listPlayNames.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"playlistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:13];
    }
    if(indexPath.row ==[MusicManager sharedMusicManager].playIndexPlaylist.row) {
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    else {
        cell.textLabel.textColor = [UIColor grayColor];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@- %@",[MusicManager sharedMusicManager].listPlayNames[indexPath.row],[MusicManager sharedMusicManager].listPlaySongs[indexPath.row]];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //reload the cell
    [[MusicManager sharedMusicManager] playMusic:[NSIndexPath indexPathForRow:indexPath.row inSection:[MusicManager sharedMusicManager].stateOfMusic] AndURL:nil];
    [self.tableView reloadData];
    [AppDelegate sharedDelegate].musicViewController.countLbl.text = [NSString stringWithFormat:@"%ld из %lu",(long)[MusicManager sharedMusicManager].playIndexPlaylist.row+1,(unsigned long)[MusicManager sharedMusicManager].listPlayNames.count];
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
