//
//  Stocks.m
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "Portfolio.h"

@implementation Portfolio

- (id)init
{
    self = [super init];
    if (self)
    {
        self.holdings = [[NSMutableArray alloc] init];
        self.watching = [[NSMutableArray alloc] init];
    }
    return SUCCESS;
}

- (int)addHolding:(Stock *)stock
{
    for (Stock *s in self.holdings)
    {
        if ([s.ticker isEqualToString:stock.ticker]) {
            return ALREADYHOLDING;
        }
    }
    [self.holdings addObject:stock];
    return true;
}

- (int)addWatching:(Stock *)stock
{
    for (Stock *s in self.watching)
    {
        if ([s.ticker isEqualToString:stock.ticker])
        {
            return ALREADYWATCHING;
        }
    }
    [self.watching addObject:stock];
    return SUCCESS;
}

- (int)queryForStock:(NSString *)ticker
{
    return SUCCESS;
}

@end
