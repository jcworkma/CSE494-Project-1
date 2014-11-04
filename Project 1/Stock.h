//
//  Stock.h
//  Project 1
//
//  Created by bhroos on 10/29/14.
//  Copyright (c) 2014 CSE494. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Stock : NSObject
    <NSCoding>

@property NSString *ticker;
@property NSNumber *numShares;

- (id)init:(NSString*)ticker withNumShares:(NSNumber *)numShares;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
