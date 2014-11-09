//
//  StatusTableViewCell.h
//  Project 1
//
//  Created by Joseph North on 11/1/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *tickerLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end
