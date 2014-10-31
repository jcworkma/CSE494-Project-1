//
//  AddStockViewController.m
//  Project 1
//
//  Created by Christopher Schott on 10/30/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "AddStockViewController.h"
#import "Portfolio.h"
#import "Stock.h"

@interface AddStockViewController ()
- (IBAction)categorySwitch:(id)sender;
- (IBAction)addButton:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *categorySegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *tickerTextField;
@property (weak, nonatomic) IBOutlet UITextField *sharesTextField;

@end

@implementation AddStockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.sharesTextField setUserInteractionEnabled:NO];
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

- (IBAction)categorySwitch:(id)sender {
    if ([self.categorySegmentedControl selectedSegmentIndex] == 0)
    {
        [self.sharesTextField setUserInteractionEnabled:NO];
    }
    else
    {
        [self.sharesTextField setUserInteractionEnabled:YES];
    }
    [self hideKeyboard];
}

- (IBAction)addButton:(id)sender {
    NSString *ticker = self.tickerTextField.text;
    
    if ([ticker length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No ticker symbol" message:@"Please enter a ticker symbol" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    Portfolio *portfolio = [Portfolio sharedInstance];
    
    if ([self.categorySegmentedControl selectedSegmentIndex] == 0)
    {
        
    }
    else
    {
        NSNumber * numShares = [NSNumber numberWithInt:[self.sharesTextField.text intValue]];
        if ([numShares compare:[NSNumber numberWithInt:0]] == NSOrderedSame ||
            [numShares compare:[NSNumber numberWithInt:0]] == NSOrderedAscending)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid number of shares" message:@"Enter a positive integer for the number of shares" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        Stock * stock = [[Stock alloc] init:ticker withNumShares:numShares];
    }
    
    [self hideKeyboard];
}

- (void)hideKeyboard
{
    [self.sharesTextField resignFirstResponder];
    [self.tickerTextField resignFirstResponder];
}
@end
