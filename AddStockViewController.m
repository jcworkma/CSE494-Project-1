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

- (void)displayAlert:(NSString *)title withMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
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
    NSString *ticker = [self.tickerTextField.text uppercaseString];
    
    if ([ticker length] == 0)
    {
        [self displayAlert:@"No ticker symbol" withMessage:@"Please enter a ticker symbol"];
        return;
    }
    
    Portfolio *portfolio = [Portfolio sharedInstance];
    
    void(^addStockCallback)(int) = ^(int result) {
        switch(result) {
            case ALREADY_HOLDING:
                [self displayAlert:@"Already holding" withMessage:@"You are already holding this stock. You can add more shares on the stock editing page."];
                break;
            case ALREADY_WATCHING:
                [self displayAlert:@"Already watching" withMessage:@"You are already watching this stock."];
                break;
            case SYMBOL_NOT_FOUND:
                [self displayAlert:@"Ticker symbol not found" withMessage:@"We couldn't find that ticker symbol. Please make sure you typed it in correctly."];
                break;
            case SUCCESS:
                // TODO: separate messages for watching success/holding success?
                [self displayAlert:@"Success!" withMessage:@"Your stock was successfully added."];
                break;
            default:
                NSLog(@"Error! Invalid result code received.");
        }
    };
    
    // TODO: add an activity indicator?
    if ([self.categorySegmentedControl selectedSegmentIndex] == 0)
    {
        Stock *stock = [[Stock alloc] init:ticker withNumShares:0];
        [portfolio addWatching:stock withCallback:addStockCallback];
    }
    else
    {
        NSNumber * numShares = [NSNumber numberWithInt:[self.sharesTextField.text intValue]];
        if ([numShares compare:[NSNumber numberWithInt:0]] == NSOrderedSame ||
            [numShares compare:[NSNumber numberWithInt:0]] == NSOrderedAscending)
        {
            [self displayAlert:@"Invalid number of shares" withMessage:@"Enter a positive integer for the number of shares"];
            return;
        }
        
        Stock * stock = [[Stock alloc] init:ticker withNumShares:numShares];
        [portfolio addHolding:stock withCallback:addStockCallback];
    }
    
    [self hideKeyboard];
}

- (void)hideKeyboard
{
    [self.sharesTextField resignFirstResponder];
    [self.tickerTextField resignFirstResponder];
}
@end
