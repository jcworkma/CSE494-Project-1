//
//  FirstViewController.m
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "StockStatusViewController.h"
#import "Portfolio.h"
#import "StatusTableViewCell.h"

#define STOCK_DATA_QUERY_URL_P1 @"https://query.yahooapis.com/v1/public/yql?q=select%20Change%2C%20LastTradePriceOnly%2C%20Symbol%20from%20yahoo.finance.quote%20where%20symbol%20in%20("
#define COMMA_ENCODING @"%2C"
#define QUOTATION_ENCODING @"%22"
#define STOCK_DATA_QUERY_URL_P2 @")&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
#define GREEN_ARROW_FILENAME @"greenarrow.png"
#define RED_ARROW_FILENAME @"redarrow.png"
#define FLAT_LINE_FILENAME @"flatline.jpg"
#define STATUS_STRING @"%@ (%.2f%%)"

#define WATCHING_SECTION 0
#define HOLDING_SECTION 1

@interface StockStatusViewController () <UITableViewDataSource, UITableViewDelegate>
- (IBAction)removePressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *removeButton;

@end

@implementation StockStatusViewController {
    Portfolio * portfolio;
    NSMutableArray * holdingsData;
    NSMutableArray * watchingData;
    UIActivityIndicatorView *spinner;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // The Portfolio singleton will be initialized here, because this is the initial view.
    portfolio = [Portfolio sharedInstance];
    holdingsData = [[NSMutableArray alloc] init];
    watchingData = [[NSMutableArray alloc] init];
    self.title = @"Stock Status";
    
    // Initalize the pull-to-refresh control.
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:0.0 green:0.7843 blue:1.0 alpha:1.0];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshData)
                  forControlEvents:UIControlEventValueChanged];
    
    // Initialize the activity indicator spinner.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Every time the view appears, the data will be refreshed.
    [spinner startAnimating];
    [self refreshData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshData {
    // Only try to get data if the user has added stocks of some kind.
    if (portfolio.holdings.count > 0 || portfolio.watching.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Clear any old stock data.
            [holdingsData removeAllObjects];
            [watchingData removeAllObjects];
            
            // Put all the stocks from watching and holding together.
            NSMutableArray * stocksArray = [NSMutableArray arrayWithArray:portfolio.holdings];
            [stocksArray addObjectsFromArray:portfolio.watching];
            
            NSMutableString * stocksToQuery = [[NSMutableString alloc] initWithString:STOCK_DATA_QUERY_URL_P1];
            // Append the first stock ticker name to the URL, which needs to be done separately from the other stock tickers because they all have to be comma-separated in the URL.
            [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@", QUOTATION_ENCODING, [stocksArray[0] ticker], QUOTATION_ENCODING]];
            // Append the rest of the stock ticker names to the URL.
            for (int i = 1; i < stocksArray.count; ++i) {
                [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@%@", COMMA_ENCODING, QUOTATION_ENCODING, [stocksArray[i] ticker], QUOTATION_ENCODING]];
            }
            [stocksToQuery appendString:STOCK_DATA_QUERY_URL_P2];
            
            NSURL * queryURL = [NSURL URLWithString:stocksToQuery];
            NSData * data = [NSData dataWithContentsOfURL:queryURL];
            
            if (data != nil) // Check to make sure we actually received data.
            {
                // The actual content we want is nested inside the returned JSON object.
                id results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil][@"query"][@"results"][@"quote"];
                
                // This API returns a JSON object (not a JSON array) if there is only one result in the result set. It returns a JSON array of JSON objects if there is more than one result. Therefore, we have to check what data structure type the result is so we can properly extract the data we want.
                if ([results isKindOfClass:[NSDictionary class]])
                {
                    // If there are any stocks in the "Holding" category, and the ticker symbol from the Web request data matches the ticker symbol the user has for their held stock:
                    if (portfolio.holdings.count > 0 && [results[@"Symbol"] isEqualToString:[portfolio.holdings[0] ticker]])
                    {
                        // Set the status image for this stock.
                        [self getStatusImage:results];
                        // Calculate and set the percent change for this stock.
                        [self getPercentage:results];
                        [holdingsData addObject:results];
                    }
                } else {
                    for (Stock * s in portfolio.holdings) // For each stock the user holds:
                    {
                        for (NSMutableDictionary * dict in results) // For each stock object returned by the Web service:
                        {
                            if ([dict[@"Symbol"] isEqualToString:[s ticker]]) // If the user's stock ticker matches the returned stock's ticker, save the stock's information.
                            {
                                // Set the status image for this stock.
                                [self getStatusImage:dict];
                                // Calculate and set the percent change for this stock.
                                [self getPercentage:dict];
                                [holdingsData addObject:dict];
                                break;
                            }
                        }
                    }
                }
                
                // This API returns a JSON object (not a JSON array) if there is only one result in the result set. It returns a JSON array of JSON objects if there is more than one result. Therefore, we have to check what data structure type the result is so we can properly extract the data we want.
                if ([results isKindOfClass:[NSDictionary class]])
                {
                    // If there are any stocks in the "Watching" category, and the ticker symbol from the Web request data matches the ticker symbol the user has for their watched stock:
                    if (portfolio.watching.count > 0 && [results[@"Symbol"] isEqualToString:[portfolio.watching[0] ticker]])
                    {
                        // Set the status image for this stock.
                        [self getStatusImage:results];
                        // Calculate and set the percent change for this stock.
                        [self getPercentage:results];
                        [watchingData addObject:results];
                    }
                } else {
                    for (Stock * s in portfolio.watching) // For each stock the user holds:
                    {
                        for (NSMutableDictionary * dict in results) // For each stock returned by the Web service:
                        {
                            if ([dict[@"Symbol"] isEqualToString:[s ticker]]) // If the user's stock ticker matches the returned stock's ticker, save the stock's information.
                            {
                                // Set the status image for this stock.
                                [self getStatusImage:dict];
                                // Calculate and set the percent change for this stock.
                                [self getPercentage:dict];
                                [watchingData addObject:dict];
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
    } else { // The user doesn't have any stocks.
        // We still need to stop the pull-to-refresh control and activity indicator spinner even if the user doesn't have  any stocks.
        [self.refreshControl endRefreshing];
        [spinner stopAnimating];
    }
}

- (void)getPercentage:(NSMutableDictionary *)dict
{
    // Calculate the percent change of a stock's value based on its price change and its last price.
    NSDecimalNumber * change = [NSDecimalNumber decimalNumberWithString:dict[@"Change"]];
    NSDecimalNumber * lastPrice = [NSDecimalNumber decimalNumberWithString:dict[@"LastTradePriceOnly"]];
    NSDecimalNumber * previousPrice = [lastPrice decimalNumberBySubtracting:change];
    NSDecimalNumber * percentChange;
    // Check for a divide-by-zero error.
    if (![previousPrice isEqualToNumber:[NSDecimalNumber zero]])
        percentChange = [change decimalNumberByDividingBy:previousPrice];
    else
        percentChange = [NSDecimalNumber zero];
    percentChange = [percentChange decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
    dict[@"Percent"] = percentChange;
}

- (void)getStatusImage:(NSMutableDictionary *)dict
{
    // The status image for the stock is a green up arrow if it gained value, a red down arrow if it lost value, and a flat line if it hasn't changed.
    double change = [dict[@"Change"] doubleValue];
    if (change > 0) {
        dict[@"Image"] = GREEN_ARROW_FILENAME;
    } else if (change < 0) {
        dict[@"Image"] = RED_ARROW_FILENAME;
    } else {
        dict[@"Image"] = FLAT_LINE_FILENAME;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (watchingData.count > 0 || holdingsData.count > 0)
    {
        // If there's data in the table, get rid of any background view we had.
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    else
    {
        // Display a message when the table is empty.
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        messageLabel.text = @"You haven't added any stocks.";
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case WATCHING_SECTION:
            return watchingData.count;
        case HOLDING_SECTION:
            return holdingsData.count;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case WATCHING_SECTION:
            return @"Watching";
        case HOLDING_SECTION:
            return @"Holding";
        default:
            return @"Error";
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        switch (indexPath.section)
        {
            case WATCHING_SECTION:
                [portfolio.watching removeObjectAtIndex:indexPath.row];
                [watchingData removeObjectAtIndex:indexPath.row];
                break;
            case HOLDING_SECTION:
                [portfolio.holdings removeObjectAtIndex:indexPath.row];
                [holdingsData removeObjectAtIndex:indexPath.row];
                break;
        }
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if (portfolio.holdings.count == 0 && portfolio.watching.count == 0)
        {
            // If the last stock was just deleted, change the edit toggle button back to "Remove".
            [self.tableView setEditing:NO animated:YES];
            self.removeButton.title = @"Remove";
        }
        // Since a stock was just deleted, save the change.
        [portfolio savePortfolio];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatusTableViewCell *cell = (StatusTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    switch (section) {
        case WATCHING_SECTION:
        {
            [cell.tickerLabel setText:[portfolio.watching[row] ticker]];
            NSString * status = [NSString stringWithFormat:STATUS_STRING, watchingData[row][@"Change"], [watchingData[row][@"Percent"] doubleValue]];
            [cell.statusLabel setText:status];
            cell.image.image = [UIImage imageNamed:watchingData[row][@"Image"]];
            break;
        }
        case HOLDING_SECTION:
        {   // Surrounded each case's code with braces so we don't redefine "status".
            [cell.tickerLabel setText:[portfolio.holdings[row] ticker]];
            NSString * status = [NSString stringWithFormat:STATUS_STRING, holdingsData[row][@"Change"], [holdingsData[row][@"Percent"] doubleValue]];
            [cell.statusLabel setText:status];
            cell.image.image = [UIImage imageNamed:holdingsData[row][@"Image"]];
            break;
        }
    }
    
    return cell;
}

- (void)removePressed:(id)sender
{
    // Only take an action on the remove button being pressed if the user has stocks.
    if (holdingsData.count > 0 || watchingData.count > 0) {
        if (self.tableView.editing) {
            // If the table is in edit mode, set it back to regular mode and change the button title back to "Remove".
            [self.tableView setEditing:NO animated:YES];
            self.removeButton.title = @"Remove";
        } else {
            // If the table is not in edit mode, set it to edit mode and change the button title to "Done".
            [self.tableView setEditing:YES  animated:NO];
            self.removeButton.title = @"Done";
        }
    }
}
@end
