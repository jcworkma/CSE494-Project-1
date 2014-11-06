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
    // Do any additional setup after loading the view, typically from a nib.
    
    portfolio = [Portfolio sharedInstance];
    holdingsData = [[NSMutableArray alloc] init];
    self.title = @"Portfolio Summary";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:0.0 green:0.7843 blue:1.0 alpha:1.0];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshData)
                  forControlEvents:UIControlEventValueChanged];
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    if (portfolio.holdings.count > 0) {
        totalPortfolioValue = [NSDecimalNumber zero];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [holdingsData removeAllObjects];
            
            NSMutableString * stocksToQuery = [[NSMutableString alloc] initWithString:STOCK_DATA_QUERY_URL_P1];

            [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@", QUOTATION_ENCODING, [portfolio.holdings[0] ticker], QUOTATION_ENCODING]];
            for (int i = 1; i < portfolio.holdings.count; ++i) {
                [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@%@", COMMA_ENCODING, QUOTATION_ENCODING, [portfolio.holdings[i] ticker], QUOTATION_ENCODING]];
            }
            [stocksToQuery appendString:STOCK_DATA_QUERY_URL_P2];
            
            NSURL * queryURL = [NSURL URLWithString:stocksToQuery];
            NSData * data = [NSData dataWithContentsOfURL:queryURL];
            
            NSMutableDictionary * results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil][@"query"][@"results"][@"quote"];
            
            // Need to special-case this because the API returns a JSON object if there's only one result and a JSON array if there's more than one result.
            if (portfolio.holdings.count == 1) {
                if ([results[@"Symbol"] isEqualToString:[portfolio.holdings[0] ticker]]) {
                    [self getTotalValue:results numShares:[portfolio.holdings[0] numShares]];
                    [holdingsData addObject:results];
                    totalPortfolioValue = [totalPortfolioValue decimalNumberByAdding:results[@"HoldingsValue"]];
                }
            } else {
                int stockNum = 0;
                for (Stock * s in portfolio.holdings) {
                    for (NSMutableDictionary * dict in results) {
                        if ([dict[@"Symbol"] isEqualToString:[s ticker]]) {
                            [self getTotalValue:dict numShares:[portfolio.holdings[stockNum] numShares]];
                            ++stockNum;
                            [holdingsData addObject:dict];
                            totalPortfolioValue = [totalPortfolioValue decimalNumberByAdding:dict[@"HoldingsValue"]];
                            break;
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
                [spinner stopAnimating];
            });
        });
    } else {
        [holdingsData removeAllObjects];
        [self.tableView reloadData];
        
        [self.refreshControl endRefreshing];
        [spinner stopAnimating];
    }
}

- (void)getTotalValue:(NSMutableDictionary *)dict numShares:(NSNumber *)numShares
{
    NSDecimalNumber * sharePrice = [NSDecimalNumber decimalNumberWithString:dict[@"LastTradePriceOnly"]];
    NSDecimalNumber * totalValue = [sharePrice decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[numShares stringValue]]];
    dict[@"HoldingsValue"] = totalValue;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (holdingsData.count > 0) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    } else {
        // Display a message when the table is empty
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        messageLabel.text = @"You haven't added any stock holdings. Go to Stock Status page to add holdings.";
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
        case 0:
            return holdingsData.count;
        case 1:
            return holdingsData.count > 0 ? 1 : 0;
        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Portfolio Contents";
        case 1:
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
        case 0:
            [cell.tickerLabel setText:holdingsData[row][@"Symbol"]];

            [cell.valueLabel setText:[NSString stringWithFormat:@"%.2f", [holdingsData[row][@"HoldingsValue"] doubleValue]]];
    
            [cell.calculationLabel setText:[NSString stringWithFormat:@"%@ shares @ %@ per share", [portfolio.holdings[row] numShares], holdingsData[row][@"LastTradePriceOnly"]]];
            break;
        case 1:
            [cell.tickerLabel setText:@"Total"];
            [cell.valueLabel setText:[totalPortfolioValue stringValue]];
            [cell.calculationLabel setText:@""];
            break;
    }
    
    return cell;
}

@end
