//
//  Stocks.m
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "Portfolio.h"

@implementation Portfolio

static Portfolio *thePortfolio = nil;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.holdings = [[NSMutableArray alloc] init];
        self.watching = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (Portfolio *)sharedInstance
{
    if (thePortfolio == nil)
    {
        thePortfolio = [[Portfolio alloc] init];
    }
    
    return thePortfolio;
}

- (void)addHolding:(Stock *)stock withCallback:(void (^)(int))callback
{
    for (Stock *s in self.holdings)
    {
        if ([s.ticker isEqualToString:stock.ticker]) {
            callback(ALREADY_HOLDING);
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ticker = stock.ticker;
        NSString *queryString = [NSString stringWithFormat:@"%@%@", STOCK_LOOKUP_BASE_URL, ticker];
        NSURL *queryURL = [NSURL URLWithString:queryString];
        NSData *data = [NSData dataWithContentsOfURL:queryURL];
        NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:Nil];
        
        if (resultDict.count == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(SYMBOL_NOT_FOUND);
            });
        }
        else
        {
            [self.holdings addObject:stock];
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(SUCCESS);
            });
        }
    });
}

- (void)addWatching:(Stock *)stock withCallback:(void (^)(int))callback
{
    for (Stock *s in self.watching)
    {
        if ([s.ticker isEqualToString:stock.ticker])
        {
            callback(ALREADY_WATCHING);
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ticker = stock.ticker;
        NSString *queryString = [NSString stringWithFormat:@"%@%@", STOCK_LOOKUP_BASE_URL, ticker];
        NSURL *queryURL = [NSURL URLWithString:queryString];
        NSData *data = [NSData dataWithContentsOfURL:queryURL];
        NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:Nil];
        
        if (resultDict.count == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(SYMBOL_NOT_FOUND);
            });
        }
        else
        {
            [self.watching addObject:stock];
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(SUCCESS);
            });
        }
    });
}

@end
