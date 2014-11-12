//
//  EditStockHoldingView.m
//  Project 1
//
//  Created by jcworkma on 11/12/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

/* CONTRIBUTED BY jack workman FOR CSE 494 ASSIGNMENT 5 */

#import "EditStockHoldingView.h"
#import "Portfolio.h"
#import "Stock.h"

@interface EditStockHoldingView ()
@property (weak, nonatomic) IBOutlet UILabel *stockName;
@property (weak, nonatomic) IBOutlet UILabel *currentShares;
@property (weak, nonatomic) IBOutlet UIButton *updateButton;
@property (weak, nonatomic) IBOutlet UITextField *updatedShares;

@end

@implementation EditStockHoldingView
{
    Portfolio * portfolio;
    Stock * stock;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get the Portfolio singleton instance.
    portfolio = [Portfolio sharedInstance];
    // Get selected Stock
    stock = (Stock*)portfolio.holdings[self.IndexOfSelectedStock];
    self.title = @"Edit Stock";
    
    self.stockName.text = stock.ticker;
    [self updateCurrentShares:stock.numShares];
    [self resetNewShares];
}

- (void)updateCurrentShares:(NSNumber*)numShares {
    self.currentShares.text = [NSString stringWithFormat:@"%@ shares", [numShares stringValue]];
}

- (void)resetNewShares {
    self.updatedShares.text = [NSString stringWithFormat:@"%ld", [stock.numShares longValue]];
}

- (void)updateHolding:(NSNumber*)numShares {
    ((Stock*)portfolio.holdings[self.IndexOfSelectedStock]).numShares = numShares;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updateButtonClicked:(id)sender {
    // Retrieve user entered shares number
    NSNumber* num = [NSNumber numberWithInteger:[self.updatedShares.text integerValue]];
    
    // update portfolio
    [self updateHolding:num];
    
    // update current shares
    [self updateCurrentShares:num];
    
    // save portfolio
    [portfolio savePortfolio];
}

@end
