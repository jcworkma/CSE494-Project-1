//
//  Stock.m
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import "Stock.h"

@implementation Stock

- (id)init:(NSString *)ticker withNumShares:(NSNumber *)numShares
{
    self = [super init];
    if (self)
    {
        self.ticker = ticker;
        self.numShares = numShares;
    }
    return self;
}

#pragma mark NSCoding protocol
- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString * ticker = [aDecoder decodeObjectForKey:@"tkey"];
    NSNumber * numShares = [aDecoder decodeObjectForKey:@"skey"];
    return [self init:ticker withNumShares:numShares];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.ticker forKey:@"tkey"];
    [aCoder encodeObject:self.numShares forKey:@"skey"];
}

@end
