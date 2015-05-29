//
//  MusicDownloader.m
//  VKiller
//
//  Created by yury.mehov on 1/15/14.
//  Copyright (c) 2014 yury.mehov. All rights reserved.
//

#import "MusicDownloader.h"
#import "RNBlurModalView.h"


NSString * const kLoadedTimeRangesKey   = @"loadedTimeRanges";
static void *AudioControllerBufferingObservationContext = &AudioControllerBufferingObservationContext;




@implementation MusicDownloader
{
    NSURLConnection *connection;
    BOOL isExecuting;
    BOOL isFinished;
}


-(instancetype)initWithArtist:(NSString*)artist songName:(NSString*)songName idAudio:(NSNumber*)isAudio idUser:(NSNumber*)isUser duration:(NSNumber*)duration bitrate:(NSString*)bitrate text:(NSNumber*)textID
{
    self = [super init];
    if(!self){
    }
    _artist = artist;
    _songName = songName;
    _idAudio = isAudio;
    _idUser = isUser;
    _duration = duration;
    _bitrate = bitrate;
    _lyricsId = textID;
    return self;
}

-(void)main
{
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:self.url];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO]; // ivar
                                                                                                      // Here is the trick
    [connection start];
    while(!isFinished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    [self completeOperation];
    return;
    
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    isExecuting = NO;
    isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    NSDictionary *dict = httpResponse.allHeaderFields;
    NSString *lengthString = [dict valueForKey:@"Content-Length"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *length = [formatter numberFromString:lengthString];
    self.totalBytes = length.unsignedIntegerValue;
    self.receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    self.receivedBytes += data.length;
    [self.receivedData appendData:data];
    double x = ((double)self.receivedBytes / (double)self.totalBytes);
    int percent = x*100;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:percent] forKey:@"percent"];
    [userInfo setObject:self.currentIndexPath forKey:@"currentIndexPath"];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PERCENT_NOTIFICATION object:self userInfo:userInfo];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSNumber* isOK = @NO;
    if(self.receivedBytes > 500) {
        isOK = @YES;
        NSString *unique = [[NSString stringWithFormat:@"%@-%@",self.artist,self.songName] stringByAppendingString:@".mp3"];
        unique = [unique stringByReplacingOccurrencesOfString:@"/" withString:@" "];
        
        NSError *error = nil;
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        documents = [documents stringByAppendingPathComponent:@"Music/"];
        NSFileManager *fileManager= [NSFileManager defaultManager];
        if(![fileManager createDirectoryAtPath:documents withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory \"%@\". Error: %@", documents, error);
        }
        NSString *filePath = [documents stringByAppendingPathComponent:unique];
        [self.receivedData writeToFile:filePath atomically:YES];
        NSManagedObjectContext *context = [[AppDelegate sharedDelegate] getContextForBGTask];
        Music *music = [NSEntityDescription
                        insertNewObjectForEntityForName:@"Music"
                        inManagedObjectContext:context];
        music.artist = self.artist;
        music.songName = self.songName;
        music.idAudio = self.idAudio;
        music.idUser = self.idUser;
        if(!self.bitrate) {
            int bitrate = ((double)self.totalBytes/128)/self.duration.integerValue;
            if(bitrate < 112)
                bitrate = 112;
            else if (bitrate < 128)
                bitrate = 128;
            else if (bitrate < 160)
                bitrate = 160;
            else if (bitrate < 192)
                bitrate = 192;
            else if (bitrate < 256)
                bitrate = 256;
            else if (bitrate < 320)
                bitrate = 320;
            music.bitrate = [NSString stringWithFormat:@"%d\nkbps",bitrate];
        }
        else {
            music.bitrate = [NSString stringWithFormat:@"%@",self.bitrate];
        }
        music.duration = self.duration;
        music.text = [NSString stringWithFormat:@"%@",self.lyricsId];
        [[AppDelegate sharedDelegate] saveContextForBGTask:context];
    }
    self.totalBytes = 0;
    self.receivedBytes = 0;
    self.receivedData = nil;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:self.currentIndexPath forKey:@"currentIndexPath"];
    [userInfo setObject:isOK forKey:@"isOK"];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:LOADING_COMPLETED_NOTIFICATION object:userInfo];
    [self performSelector:@selector(completeOperation) withObject:nil afterDelay:1];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.totalBytes = 0;
    self.receivedBytes = 0;
    self.receivedData = nil;
}



@end
