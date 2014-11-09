//
//  AddStockViewController.m
//  Project 1
//
//  Created by Joseph North on 10/30/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "AddStockViewController.h"
#import "Portfolio.h"
#import "Stock.h"

#define WATCHING_SWITCH 0

@interface AddStockViewController ()
- (IBAction)categorySwitch:(id)sender;
- (IBAction)addButton:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *categorySegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *tickerTextField;
@property (weak, nonatomic) IBOutlet UITextField *sharesTextField;

@end

@implementation AddStockViewController {
    UIActivityIndicatorView *spinner;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // "Watching" is selected by default, so the "Shares" text field should not be editable.
    [self.sharesTextField setUserInteractionEnabled:NO];
    
    // Initialize the activity indicator spinner.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Convenience method to display an alert, given a title and message.
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
    // If the switch was set to "Watching", disable inteaction on the "Shares" text field.
    if ([self.categorySegmentedControl selectedSegmentIndex] == WATCHING_SWITCH)
    {
        [self.sharesTextField setUserInteractionEnabled:NO];
    }
    // Otherwise, the switch was set to "Holding", so enable interaction on the "Shares" text field.
    else
    {
        [self.sharesTextField setUserInteractionEnabled:YES];
    }
    // If the keyboard is up, hide it.
    [self hideKeyboard];
}

- (IBAction)addButton:(id)sender {
    // Change all input ticker symbols to upper case because the Web APIs we use expect upper-case ticker symbols.
    NSString *ticker = [self.tickerTextField.text uppercaseString];
    // Trim whitespace from the string.
    ticker = [ticker stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([ticker length] == WATCHING_SWITCH)
    {
        [self displayAlert:@"No ticker symbol" withMessage:@"Please enter a ticker symbol"];
        return;
    }
    
    // Get the singleton instance of the Portfolio.
    Portfolio *portfolio = [Portfolio sharedInstance];
    
    // Block that is called after the Portfolio has finished its addHolding/addWatching call.
    void(^addStockCallback)(int) = ^(int result) {
        [spinner stopAnimating];
        switch(result) {
            case ALREADY_HOLDING:
                [self displayAlert:@"Already holding" withMessage:@"You are already holding this stock."];
                break;
            case ALREADY_WATCHING:
                [self displayAlert:@"Already watching" withMessage:@"You are already watching this stock."];
                break;
            case SYMBOL_NOT_FOUND:
                [self displayAlert:@"Ticker symbol not found" withMessage:@"We couldn't find that ticker symbol. Please make sure you typed it in correctly."];
                break;
            case SUCCESS:
                [self displayAlert:@"Success!" withMessage:@"Your stock was successfully added."];
                break;
            case NO_DATA:
                [self displayAlert:@"Problem retrieving data" withMessage:@"Please check your Internet connection and try again"];
                break;
            default:
                NSLog(@"Error! Invalid result code received.");
        }
    };
    
    if ([self.categorySegmentedControl selectedSegmentIndex] == WATCHING_SWITCH) // The switch is set to "Watching"
    {
        Stock *stock = [[Stock alloc] init:ticker withNumShares:0];
        // Start the activity indicator spinner.
        [spinner startAnimating];
        // Attempt to add the stock to the "Watching" category.
        [portfolio addWatching:stock withCallback:addStockCallback];
    }
    else // The switch is set to "Holding"
    {
        NSNumber * numShares = [NSNumber numberWithInt:[self.sharesTextField.text intValue]];
        if ([numShares compare:[NSNumber numberWithInt:0]] == NSOrderedSame ||
            [numShares compare:[NSNumber numberWithInt:0]] == NSOrderedAscending)
        {
            // If the number of shares is <= 0, display an alert.
            [self displayAlert:@"Invalid number of shares" withMessage:@"Enter a positive integer for the number of shares"];
            return;
        }
        
        Stock * stock = [[Stock alloc] init:ticker withNumShares:numShares];
        // Start the activity indicator spinner.
        [spinner startAnimating];
        // Attempt to add the stock to the "Holding" category.
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
