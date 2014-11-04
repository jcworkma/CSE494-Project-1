//
//  PortfolioTableViewCell.h
//  Project 1
//
//  Created by bhroos on 11/4/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PortfolioTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *tickerLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *calculationLabel;

@end
