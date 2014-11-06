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

+ (void)loadPortfolio
{
    NSString *path = [Portfolio dataFilePath];
    // Only load the list from storage if a saved one exists.
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        // Does not need to be mutable because we're only reading it. Loads the data from file.
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        // What objects need to be decoded?
        thePortfolio.watching = [unarchiver decodeObjectForKey:@"watching"];
        
        thePortfolio.holdings = [unarchiver decodeObjectForKey:@"holdings"];
        
        // Read the objects.
        [unarchiver finishDecoding];
    }
}

+ (NSString*)dataFilePath
{
    return [@"~/Documents/stocks_data.plist" stringByExpandingTildeInPath];
}

+ (Portfolio *)sharedInstance
{
    if (thePortfolio == nil)
    {
        thePortfolio = [[Portfolio alloc] init];
        [Portfolio loadPortfolio];
    }
    
    return thePortfolio;
}

- (void)savePortfolio
{
    // Set up encoder.
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    // What objects need to be encoded?
    [archiver encodeObject:self.watching forKey:@"watching"];
    
    [archiver encodeObject:self.holdings forKey:@"holdings"];
    
    // Encode the objects.
    [archiver finishEncoding];
    
    // Write the encoded objects.
    [data writeToFile:[Portfolio dataFilePath] atomically:YES];
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
        
        if (data != nil)
        {
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
                [self savePortfolio];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(SUCCESS);
                });
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(NO_DATA);
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
        
        if (data != nil)
        {
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
                [self savePortfolio];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(SUCCESS);
                });
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(NO_DATA);
            });
        }
    });
}

#pragma mark NSCoding protocol
- (id)initWithCoder:(NSCoder *)aDecoder
{
    Portfolio * instance = [Portfolio sharedInstance];
    instance.watching = [aDecoder decodeObjectForKey:@"wkey"];
    instance.holdings = [aDecoder decodeObjectForKey:@"hkey"];
    return instance;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    Portfolio * instance = [Portfolio sharedInstance];
    [aCoder encodeObject:instance.watching forKey:@"wkey"];
    [aCoder encodeObject:instance.holdings forKey:@"hkey"];
}

@end
