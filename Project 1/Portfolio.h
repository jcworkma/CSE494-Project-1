//
//  Stocks.h
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stock.h"

#define SUCCESS 0
#define ALREADY_HOLDING 1
#define ALREADY_WATCHING 2
#define SYMBOL_NOT_FOUND 3

#define STOCK_LOOKUP_BASE_URL @"http://dev.markitondemand.com/Api/v2/Lookup/json?input="

@interface Portfolio : NSObject

@property NSMutableArray *holdings;
@property NSMutableArray *watching;

- (void)addHolding:(Stock *)stock withCallback:(void(^)(int result))callback;
- (void)addWatching:(Stock *)stock withCallback:(void(^)(int result))callback;
+ (Portfolio *)sharedInstance;

@end
