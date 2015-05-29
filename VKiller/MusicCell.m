//
//  MusicCell.m
//  VKiller
//
//  Created by yury.mehov on 11/29/13.
//  Copyright (c) 2013 yury.mehov. All rights reserved.
//

#import "MusicCell.h"
#import "ViewController.h"

@implementation MusicCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


-(id) initWithCoder:(NSCoder *)aDecoder{
    
    self=[super initWithCoder:aDecoder];
    
    if(self){
        offset=32.0;
        self.btn=[[UIImageView alloc] initWithFrame:CGRectMake(-(offset/2.0)-(15.0/2.0),  (self.contentView.frame.size.height/2.0)-(15/2.0), 15  , 15)];
        
        [self.btn setImage:[UIImage imageNamed:@"audioplayer_add"]];
        [self addSubview:self.btn];
    }
    return self;
}

-(void) layoutSubviews{
    [super layoutSubviews];
    
    if(self.isEditing && ((ViewController *)[self.superview.superview nextResponder]).stateOfMusic == home){
        self.btn.frame=CGRectMake((offset/2.0)-(15.0/2.0),  (self.contentView.frame.size.height/2.0)-(25/2.0), 15  , 15);
        
    }else{
        self.btn.frame=CGRectMake(-(offset/2.0)-(15/2.0),  (self.contentView.frame.size.height/2.0)-(25/2.0), 15  , 15);
        
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


@end
