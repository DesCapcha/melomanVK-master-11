//
//  CenterViewController.m
//  VKiller
//
//  Created by iLego on 10.02.15.
//  Copyright (c) 2015 yury.mehov. All rights reserved.
//

#import "CenterViewController.h"
#import "MusicManager.h"
#import "RNBlurModalView.h"
#import "Album.h"
#import "LeftViewController.h"
#import "NGAParallaxMotion.h"

@interface CenterViewController ()<UIAlertViewDelegate>
{
    UIImageView *view;
    __weak IBOutlet UIToolbar *toolbar;
}

@end

@implementation CenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ViewController *viewContr =[[ViewController alloc] init];
    UITableView *tableView = viewContr.tableView;
    tableView.frame = CGRectMake(0, 54, self.view.bounds.size.width, self.view.bounds.size.height-54);
    self.mainViewController =viewContr;
    viewContr.centerViewControl = self;
    [self.view addSubview:tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedFone) name:POST_CHANGED_FONE object:nil];
    
    [self setNeedsStatusBarAppearanceUpdate];
    // Do any additional setup after loading the view from its nib.
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    
    return NO;
}
- (IBAction)editAction:(UIButton*)sender {
    [self editingTable:sender.tag?YES:NO];
    sender.tag = !sender.tag;
    if(!sender.tag) {
        [sender setImage:[UIImage imageNamed:@"school.png"] forState:UIControlStateNormal];
    }
    else {
        [sender setImage:[UIImage imageNamed:@"photo_panel_ok.png"] forState:UIControlStateNormal];
    }
}

-(void)editingTable:(BOOL)edit {
    [self.mainViewController.tableView setEditing:!edit animated:YES];
    CGRect rect = self.mainViewController.tableView.frame;
    
    [self.mainViewController.tableView reloadData];
    if(self.mainViewController.stateOfMusic == home) {
        self.mainViewController.selectedIndex = [NSMutableSet set];
        if(edit ){
            rect.size.height += toolbar.frame.size.height;
        }
        else {
            rect.size.height -= toolbar.frame.size.height;
        }
        self.mainViewController.tableView.frame = rect;
        toolbar.hidden = edit;
    }
}

- (IBAction)actionPlaylist:(UIBarButtonItem *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Плейлист для перемещения" delegate:self cancelButtonTitle:@"Отмена" otherButtonTitles:nil];
    for(Album *al in [[AppDelegate sharedDelegate] getAllAlbum]) {
        [alert addButtonWithTitle:al.name];
    }
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != [alertView cancelButtonIndex] && alertView.tag != 123) {
    NSString *nameAlbum = [alertView buttonTitleAtIndex:buttonIndex];
    Album * al = [[AppDelegate sharedDelegate] albumByName:nameAlbum];
    for (NSNumber *n in self.mainViewController.selectedIndex) {
        NSNumber *idAudio = self.mainViewController.idAudio[n.intValue];
        NSNumber *idUser = self.mainViewController.idUser[n.intValue];
        Music * music = [[AppDelegate sharedDelegate] musicByIdAudio:idAudio andIdUser:idUser];
        music.album = al;
        [al addTracksObject:music];
        [[AppDelegate sharedDelegate].defaultManagedObjectContext save:nil];
    }
    [self.editBtn setImage:[UIImage imageNamed:@"school.png"] forState:UIControlStateNormal];
    self.editBtn.tag = 0;
    [self editingTable:YES];
    }
}

- (IBAction)actionRemove:(id)sender {
    NSMutableArray *deleteIndexPath = [NSMutableArray array];
    for (NSNumber *n in self.mainViewController.selectedIndex) {
        NSString *idAudio = self.mainViewController.idAudio[n.intValue];
        NSString *idUser = self.mainViewController.idUser[n.intValue];
        [[AppDelegate sharedDelegate] deleteMusicByIdAudio:idAudio idUser:idUser];
        [deleteIndexPath addObject:[NSIndexPath indexPathForRow:n.intValue inSection:0]];
    }
    [self.editBtn setImage:[UIImage imageNamed:@"school.png"] forState:UIControlStateNormal];
    self.editBtn.tag = 0;
    [self editingTable:YES];
    [self.mainViewController.tableView deleteRowsAtIndexPaths:deleteIndexPath withRowAnimation:UITableViewRowAnimationLeft];
}

-(void)viewDidLayoutSubviews {
    [self changedFone];
}

-(void)changedFone
{
    if(view){
        [view removeFromSuperview];
        view = nil;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"fone.jpg"];
    if(imagePath){
        UIImage *tempImg = [UIImage imageWithContentsOfFile:imagePath];
        view = [[UIImageView alloc] initWithImage:tempImg];
        if(tempImg)
            view.image = [UIImage imageWithContentsOfFile:imagePath];
        else view.image = [((LeftViewController *)([AppDelegate sharedDelegate].controller.leftController)).ava.image applyDarkEffect];
    }
    view.frame = self.view.frame;
    view.alpha = kALPHA;
    [self.view addSubview:view ];
    [self.view sendSubviewToBack:view ];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (IBAction)showMusicViewModal {
    if([MusicManager sharedMusicManager].listPlayNames.count == 0) {
        RNBlurModalView* alertView = [[RNBlurModalView alloc] initWithParentView:self.view title:@"Неудача"
                                                                         message:@"Нет трека для воспроизведения"];
        [alertView show];
        return;
    }
    MusicViewController *news = (MusicViewController*)[AppDelegate sharedDelegate].musicViewController;
    //news.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    if(!news) {
        news =  [[MusicViewController alloc] init];
    }
    [[AppDelegate sharedDelegate].navController pushViewController:news animated:YES];
}

- (IBAction)showLeftView {
    if([[AppDelegate sharedDelegate].controller isSideOpen:IIViewDeckLeftSide])
        [[AppDelegate sharedDelegate].controller closeLeftViewAnimated:YES];
    else {
        [[AppDelegate sharedDelegate].controller openLeftViewAnimated:YES];
    }
}
- (IBAction)shuffle {
    
    if(self.shuffleBtn.tag == 123) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Новый альбом" message:@"Введите название" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Назад", nil];
        alert.tag = 123;
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
        return;
    }
    BOOL ok = [self.mainViewController shuffleAll];
    if(!ok) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Неудача" message:@"Пожалуйста, дождитесь окончания загрузки" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alert show];
        [self performSelector:@selector(dismissAlertView:) withObject:alert afterDelay:2];
        
    }
    
    return;
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 123 && buttonIndex == [alertView cancelButtonIndex]) {
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].defaultManagedObjectContext;
        Album *album = [NSEntityDescription
                        insertNewObjectForEntityForName:@"Album"
                        inManagedObjectContext:context];
        album.name = [alertView textFieldAtIndex:0].text;
        [[AppDelegate sharedDelegate] saveContextForBGTask:context];
        [self.mainViewController playlistMode];
        [self.mainViewController.tableView reloadData];
    }
}

-(void)dismissAlertView:(UIAlertView *)alertView{
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
