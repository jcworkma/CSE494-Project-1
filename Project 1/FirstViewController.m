//
//  FirstViewController.m
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "FirstViewController.h"
#import "Portfolio.h"
#import "StatusTableViewCell.h"

#define STOCK_DATA_QUERY_URL_P1 @"https://query.yahooapis.com/v1/public/yql?q=select%20Change%2C%20LastTradePriceOnly%2C%20Symbol%20from%20yahoo.finance.quote%20where%20symbol%20in%20("
#define COMMA_ENCODING @"%2C"
#define QUOTATION_ENCODING @"%22"
#define STOCK_DATA_QUERY_URL_P2 @")&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"

@interface FirstViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation FirstViewController {
    Portfolio * portfolio;
    NSMutableArray * holdingsData;
    NSMutableArray * watchingData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    portfolio = [Portfolio sharedInstance];
    holdingsData = [[NSMutableArray alloc] init];
    watchingData = [[NSMutableArray alloc] init];
    self.title = @"Stock Status";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshData)
                  forControlEvents:UIControlEventValueChanged];

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
            
            NSDictionary * results = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil][@"query"][@"results"][@"quote"];
            NSLog(@"%lu", (unsigned long)results.count);
            
            // Need to special-case this because the API returns a JSON object if there's only one result and a JSON array if there's more than one result.
            if (portfolio.holdings.count == 1) {
                if ([results[@"Symbol"] isEqualToString:[portfolio.holdings[0] ticker]]) {
                    [holdingsData addObject:results];
                }
            } else {
                for (Stock * s in portfolio.holdings) {
                    for (NSDictionary * dict in results) {
                        if ([dict[@"Symbol"] isEqualToString:[s ticker]]) {
                            [holdingsData addObject:dict];
                            break;
                        }
                    }
                }
            }
            
            if (portfolio.watching.count == 1) {
                if ([results[@"Symbol"] isEqualToString:[portfolio.watching[0] ticker]]) {
                    [watchingData addObject:results];
                }
            } else {
                for (Stock * s in portfolio.watching) {
                    for (NSDictionary * dict in results) {
                        if ([dict[@"Symbol"] isEqualToString:[s ticker]]) {
                            [watchingData addObject:dict];
                            break;
                        }
                    }
                }
            }
            
            NSLog(@"%lu", (unsigned long)holdingsData.count);
            NSLog(@"%lu", (unsigned long)watchingData.count);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"reloadData");
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
            });
        });
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (holdingsData.count > 0 || watchingData.count > 0) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
        return 2;
    } else {
        // Display a message when the table is empty
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    
        messageLabel.text = @"No data is currently available. Please pull down to refresh.";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
        [messageLabel sizeToFit];
    
        self.tableView.backgroundView = messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return 0;
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
            break;
        case 1:
            return @"Holding";
            break;
        default:
            return @"Error";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatusTableViewCell *cell = (StatusTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    NSLog(@"cellforrowatindexpath:row:%ld", (long)row);
    NSLog(@"cellforrowatindexpath:%lu", (unsigned long)holdingsData.count);
    NSLog(@"cellforrowatindexpath:%lu", (unsigned long)watchingData.count);
    
    switch (section) {
        case 0:
            [cell.tickerLabel setText:[portfolio.watching[row] ticker]];
            [cell.statusLabel setText:watchingData[row][@"Change"]];
            break;
        case 1:
            [cell.tickerLabel setText:[portfolio.holdings[row] ticker]];
            [cell.statusLabel setText:holdingsData[row][@"Change"]];
            break;
    }
    
    return cell;
}

@end
