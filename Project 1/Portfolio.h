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
#define ALREADYHOLDING 1
#define ALREADYWATCHING 2
#define SYMBOLNOTFOUND 3

@interface Portfolio : NSObject

@property NSMutableArray *holdings;
@property NSMutableArray *watching;

@end
