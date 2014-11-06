//
//  SecondViewController.m
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "PortfolioSummaryViewController.h"
#import "Portfolio.h"
#import "PortfolioTableViewCell.h"

#define STOCK_DATA_QUERY_URL_P1 @"https://query.yahooapis.com/v1/public/yql?q=select%20Change%2C%20LastTradePriceOnly%2C%20Symbol%20from%20yahoo.finance.quote%20where%20symbol%20in%20("
#define COMMA_ENCODING @"%2C"
#define QUOTATION_ENCODING @"%22"
#define STOCK_DATA_QUERY_URL_P2 @")&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
#define GREEN_ARROW_FILENAME @"greenarrow.png"
#define RED_ARROW_FILENAME @"redarrow.png"
#define FLAT_LINE_FILENAME @"flatline.jpg"

#define PORTFOLIO_SECTION 0
#define TOTAL_SECTION 1

@interface PortfolioSummaryViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation PortfolioSummaryViewController
{
    Portfolio * portfolio;
    NSMutableArray * holdingsData;
    NSDecimalNumber * totalPortfolioValue;
    UIActivityIndicatorView *spinner;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Get the Portfolio singleton instance.
    portfolio = [Portfolio sharedInstance];
    holdingsData = [[NSMutableArray alloc] init];
    self.title = @"Portfolio Summary";
    
    // Set up the pull-to-refresh control.
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:0.0 green:0.7843 blue:1.0 alpha:1.0];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshData)
                  forControlEvents:UIControlEventValueChanged];
    
    // Set up the activity indicator spinner.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // The data will refresh every time the view reappears.
    [spinner startAnimating];
    [self refreshData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshData
{
    if (portfolio.holdings.count > 0) { // Only refresh the data if the user has any stocks.
        // Reset the portfolio's total value to zero.
        totalPortfolioValue = [NSDecimalNumber zero];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Clear any old stock data.
            [holdingsData removeAllObjects];
            
            NSMutableString * stocksToQuery = [[NSMutableString alloc] initWithString:STOCK_DATA_QUERY_URL_P1];
            // Add the first stock ticker to the URL, which needs to be done separately from the other stock tickers because they all have to be comma-separated in the URL.
            [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@", QUOTATION_ENCODING, [portfolio.holdings[0] ticker], QUOTATION_ENCODING]];
            // Add the rest of the stock tickers to the URL.
            for (int i = 1; i < portfolio.holdings.count; ++i) {
                [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@%@", COMMA_ENCODING, QUOTATION_ENCODING, [portfolio.holdings[i] ticker], QUOTATION_ENCODING]];
            }
            [stocksToQuery appendString:STOCK_DATA_QUERY_URL_P2];
            
            NSURL * queryURL = [NSURL URLWithString:stocksToQuery];
            NSData * data = [NSData dataWithContentsOfURL:queryURL];
            
            if (data != nil) // Check to make sure we actually received data.
            {
                // The actual content we want is nested inside the returned JSON object.
                NSMutableDictionary * results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil][@"query"][@"results"][@"quote"];
                
                // This API returns a JSON object (not a JSON array) if there is only one result in the result set. It returns a JSON array of JSON objects if there is more than one result. Therefore, we have to check what data structure type the result is so we can properly extract the data we want.
                if (portfolio.holdings.count == 1) {
                    if ([results[@"Symbol"] isEqualToString:[portfolio.holdings[0] ticker]]) {
                        // Calculate and set the total value of this stock holding.
                        [self getTotalValue:results numShares:[portfolio.holdings[0] numShares]];
                        [holdingsData addObject:results];
                        // Add its value to the total portfolio value.
                        totalPortfolioValue = [totalPortfolioValue decimalNumberByAdding:results[@"HoldingsValue"]];
                    }
                } else {
                    int stockNum = 0;
                    for (Stock * s in portfolio.holdings) { // For each stock in the user's holdings:
                        for (NSMutableDictionary * dict in results) { // For each stock object returned by the Web service:
                            if ([dict[@"Symbol"] isEqualToString:[s ticker]]) { // If the user's stock ticker matches the returned stock's ticker, save the stock's information.
                                // Calculate and set the total value of this stock holding.
                                [self getTotalValue:dict numShares:[portfolio.holdings[stockNum] numShares]];
                                ++stockNum;
                                [holdingsData addObject:dict];
                                // Add its value to the total portfolio value.
                                totalPortfolioValue = [totalPortfolioValue decimalNumberByAdding:dict[@"HoldingsValue"]];
                                break;
                            }
                        }
                    }
                }
            }
            else // The data returned from the Web service was nil.
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Problem retrieving data" message:@"Please check your Internet connection or pull to refresh to try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                });
            }
            
            // Do UI updates on the main thread.
            dispatch_async(dispatch_get_main_queue(), ^{
                // Reload the table's data.
                [self.tableView reloadData];
                // Close the pull-to-refresh control.
                [self.refreshControl endRefreshing];
                // Stop the activity indicator spinner.
                [spinner stopAnimating];
            });
        });
    } else {
        // We need to clear any old stock holdings data so the data in this table is in sync with the data on the Stock Status page.
        [holdingsData removeAllObjects];
        [self.tableView reloadData];
        // Close the pull-to-refresh control.
        [self.refreshControl endRefreshing];
        // Stop the activity indicator spinner.
        [spinner stopAnimating];
    }
}

- (void)getTotalValue:(NSMutableDictionary *)dict numShares:(NSNumber *)numShares
{
    // Get the total value for this stock holding by multiplying the price by the number of shares.
    NSDecimalNumber * sharePrice = [NSDecimalNumber decimalNumberWithString:dict[@"LastTradePriceOnly"]];
    NSDecimalNumber * totalValue = [sharePrice decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[numShares stringValue]]];
    dict[@"HoldingsValue"] = totalValue;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (holdingsData.count > 0) {
        // If we have data, clear the message we displayed before.
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    } else {
        // Display a message when the table is empty.
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        messageLabel.text = @"You haven't added any stock holdings. Go to the Stock Status page to add holdings.";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case PORTFOLIO_SECTION:
            return holdingsData.count;
        case TOTAL_SECTION:
            // If there are any holdings, there will be a row for the total.
            return holdingsData.count > 0 ? 1 : 0;
        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case PORTFOLIO_SECTION:
            return @"Portfolio Contents";
        case TOTAL_SECTION:
            return @"Total";
        default:
            return @"Error";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PortfolioTableViewCell *cell = (PortfolioTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"PortfolioCell"];
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    switch (section) {
        case PORTFOLIO_SECTION:
        {
            [cell.tickerLabel setText:holdingsData[row][@"Symbol"]];

            [cell.valueLabel setText:[NSString stringWithFormat:@"%.2f", [holdingsData[row][@"HoldingsValue"] doubleValue]]];

            // Use the correct "share/shares" depending on how many shares the user actually has.
            NSString * calcFormatString;
            if ([[portfolio.holdings[row] numShares] compare:[NSNumber numberWithInt:1]] == NSOrderedSame)
            {
                calcFormatString = @"%@ share @ %@ per share";
            }
            else
            {
                calcFormatString = @"%@ shares @ %@ per share";
            }
            
            [cell.calculationLabel setText:[NSString stringWithFormat:calcFormatString, [portfolio.holdings[row] numShares], holdingsData[row][@"LastTradePriceOnly"]]];
            break;
        }
        case TOTAL_SECTION:
        {
            [cell.tickerLabel setText:@"Total"];
            [cell.valueLabel setText:[NSString stringWithFormat:@"%.2f", [totalPortfolioValue doubleValue]]];
            [cell.calculationLabel setText:@""];
            break;
        }
    }
    
    return cell;
}

@end
