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
    // The Portfolio singleton will be initialized here, because this is the intitial view.
    portfolio = [Portfolio sharedInstance];
    holdingsData = [[NSMutableArray alloc] init];
    watchingData = [[NSMutableArray alloc] init];
    self.title = @"Stock Status";
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshData {
    if (portfolio.holdings.count > 0 || portfolio.watching.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [holdingsData removeAllObjects];
            [watchingData removeAllObjects];
            
            NSMutableSet * stockSet = [[NSMutableSet alloc] init];
            [stockSet addObjectsFromArray:portfolio.holdings];
            [stockSet addObjectsFromArray:portfolio.watching];
        
            NSMutableString * stocksToQuery = [[NSMutableString alloc] initWithString:STOCK_DATA_QUERY_URL_P1];
            NSArray * stocksArray = [stockSet allObjects];
            [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@", QUOTATION_ENCODING, [stocksArray[0] ticker], QUOTATION_ENCODING]];
            for (int i = 1; i < stocksArray.count; ++i) {
                [stocksToQuery appendString:[NSString stringWithFormat:@"%@%@%@%@", COMMA_ENCODING, QUOTATION_ENCODING, [stocksArray[i] ticker], QUOTATION_ENCODING]];
            }
            [stocksToQuery appendString:STOCK_DATA_QUERY_URL_P2];
            
            NSURL * queryURL = [NSURL URLWithString:stocksToQuery];
            NSData * data = [NSData dataWithContentsOfURL:queryURL];
            
            id results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil][@"query"][@"results"][@"quote"];
            
            // Need to special-case this because the API returns a JSON object if there's only one result and a JSON array if there's more than one result.
            
            if ([results isKindOfClass:[NSDictionary class]])
            {
                if (portfolio.holdings.count > 0 && [results[@"Symbol"] isEqualToString:[portfolio.holdings[0] ticker]])
                {
                    [self getStatusImage:results];
                    [self getPercentage:results];
                    [holdingsData addObject:results];
                }
            } else {
                for (Stock * s in portfolio.holdings)
                {
                    for (NSMutableDictionary * dict in results) {
                        if ([dict[@"Symbol"] isEqualToString:[s ticker]]) {
                            [self getStatusImage:dict];
                            [self getPercentage:dict];
                            [holdingsData addObject:dict];
                            break;
                        }
                    }
                }
            }
            
            if ([results isKindOfClass:[NSDictionary class]])
            {
                if (portfolio.watching.count > 0 && [results[@"Symbol"] isEqualToString:[portfolio.watching[0] ticker]])
                {
                    [self getStatusImage:results];
                    [self getPercentage:results];
                    [watchingData addObject:results];
                }
            } else {
                for (Stock * s in portfolio.watching) {
                    for (NSMutableDictionary * dict in results) {
                        if ([dict[@"Symbol"] isEqualToString:[s ticker]])
                        {
                            [self getStatusImage:dict];
                            [self getPercentage:dict];
                            [watchingData addObject:dict];
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
        [self.refreshControl endRefreshing];
        [spinner stopAnimating];
    }
}

- (void)getPercentage:(NSMutableDictionary *)dict
{
    NSDecimalNumber * change = [NSDecimalNumber decimalNumberWithString:dict[@"Change"]];
    NSDecimalNumber * lastPrice = [NSDecimalNumber decimalNumberWithString:dict[@"LastTradePriceOnly"]];
    NSDecimalNumber * previousPrice = [lastPrice decimalNumberBySubtracting:change];
    NSDecimalNumber * percentChange;
    if (![previousPrice isEqualToNumber:[NSDecimalNumber zero]])
        percentChange = [change decimalNumberByDividingBy:previousPrice];
    else
        percentChange = [NSDecimalNumber zero];
    percentChange = [percentChange decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
    dict[@"Percent"] = percentChange;
}

- (void)getStatusImage:(NSMutableDictionary *)dict
{
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
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    else {
        // Display a message when the table is empty
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
        case 0:
            return watchingData.count;
        case 1:
            return holdingsData.count;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Watching";
        case 1:
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
            case 0:
                [portfolio.watching removeObjectAtIndex:indexPath.row];
                [watchingData removeObjectAtIndex:indexPath.row];
                break;
            case 1:
                [portfolio.holdings removeObjectAtIndex:indexPath.row];
                [holdingsData removeObjectAtIndex:indexPath.row];
                break;
        }
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if (portfolio.holdings.count == 0 && portfolio.watching.count == 0)
        {
            [self.tableView setEditing:NO animated:YES];
            self.removeButton.title = @"Remove";
        }
        [portfolio savePortfolio];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatusTableViewCell *cell = (StatusTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    switch (section) {
        case 0:
        {
            [cell.tickerLabel setText:[portfolio.watching[row] ticker]];
            NSString * status = [NSString stringWithFormat:STATUS_STRING, watchingData[row][@"Change"], [watchingData[row][@"Percent"] doubleValue]];
            [cell.statusLabel setText:status];
            cell.image.image = [UIImage imageNamed:watchingData[row][@"Image"]];
            break;
        }
        case 1:
        {   // Surrounding each case's code with braces so we don't redefine "status".
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
    if (holdingsData.count > 0 || watchingData.count > 0) {
        if (self.tableView.editing) {
            [self.tableView setEditing:NO animated:YES];
            self.removeButton.title = @"Remove";
        } else {
            [self.tableView setEditing:YES  animated:NO];
            self.removeButton.title = @"Done";
        }
    }
}
@end
