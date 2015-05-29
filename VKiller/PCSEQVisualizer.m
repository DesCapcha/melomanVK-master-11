//
//  HNHHEQVisualizer.m
//  HNHH
//
//  Created by Dobango on 9/17/13.
//  Copyright (c) 2013 RC. All rights reserved.
//

#import "PCSEQVisualizer.h"
#import "UIImage+Color.h"

#define kWidth 15
#define kHeight 40
#define kPadding 1


@implementation PCSEQVisualizer
{
    NSTimer* timer;
    NSArray* barArray;
    BOOL showBar;
}
// isOnline - переменная, отвечающая за воспроизведение музыки
- (id)initWithNumberOfBars:(int)numberOfBars internetConnection:(BOOL)isOnline
{
    self = [super init];
    if (self) {
        showBar = ![AppDelegate sharedDelegate].offlineMode;
        if(showBar){
            self.frame = CGRectMake(0, 0, kPadding*numberOfBars+(kWidth*numberOfBars), kHeight);
            NSMutableArray* tempBarArray = [[NSMutableArray alloc]initWithCapacity:numberOfBars];
            
            for(int i=0;i<numberOfBars;i++){
                
                UIImageView* bar = [[UIImageView alloc]initWithFrame:CGRectMake(i*kWidth+i*kPadding, 0, 10, 0)];
                bar.image = [UIImage imageWithColor:[UILabel appearance].textColor];
                bar.alpha = 0.8;
                [self addSubview:bar];
                [tempBarArray addObject:bar];
                
            }
            
            barArray = [[NSArray alloc]initWithArray:tempBarArray];
            
            CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2*2);
            self.transform = transform;
        }
//        else{
//            NSArray *words = @[@"Н",@"Е",@"Т",@" ",@"И",@"Н",@"Т",@"Е",@"Р",@"Н",@"Е",@"Т",@"А"];
//            NSMutableArray* tempBarArray = [[NSMutableArray alloc]initWithCapacity:numberOfBars];
//            
//            for(int i=0;i<numberOfBars;i++){
//                
//                UILabel *character =[[UILabel alloc] init];
//                character.text = [words objectAtIndex:i];
//                character.textColor = [UIColor grayColor];
//                character.font = [UIFont fontWithName:@"Apple SD Gothic Neo" size:17];
//                character.frame = CGRectMake(i*16, 0, kWidth, 15 );
//                [self addSubview:character];
//                [tempBarArray addObject:character];
//                
//            }
//            barArray = [[NSArray alloc]initWithArray:tempBarArray];
//        }
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:@"stopTimer" object:nil];
        
    }
    return self;
}


-(void)start{
    if(timer == nil){
        self.hidden = NO;
        timer = [NSTimer scheduledTimerWithTimeInterval:.35 target:self selector:@selector(ticker) userInfo:nil repeats:YES];
    }
    
}


-(void)stop{
    
    [timer invalidate];
    timer = nil;
    
}

-(void)ticker{
    
    [UIView animateWithDuration:.35 animations:^{
        
        for(UIImageView* bar in barArray){
            
            CGRect rect = bar.frame;
            if(showBar)
                rect.size.height = arc4random() % kHeight + 1;
//            else
//                rect.size.height = arc4random() % kHeight + 18;
            bar.frame = rect;
            
            
        }
        
    }];
}

@end
