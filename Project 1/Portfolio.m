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
        // This is the first time the instance has been requested, so load the data from storage.
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
        if ([s.ticker isEqualToString:stock.ticker]) { // If the user already holds this stock:
            callback(ALREADY_HOLDING);
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ticker = stock.ticker;
        NSString *queryString = [NSString stringWithFormat:@"%@%@", STOCK_LOOKUP_BASE_URL, ticker];
        NSURL *queryURL = [NSURL URLWithString:queryString];
        NSData *data = [NSData dataWithContentsOfURL:queryURL];
        
        if (data != nil) // Check that we actually received some data.
        {
            NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:Nil];
            
            // This API returns an empty JSON array if the stock doesn't exist, so all we have to do to check that this is a valid stock is see if the array has any contents.
            if (resultDict.count == 0) // The array doesn't have any data, so it's not a real stock.
            {
                // We're not on the main thread and the callback does UI updates, so call the callback on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(SYMBOL_NOT_FOUND);
                });
            }
            else    // The array contains data, so the stock exists.
            {
                // Add the stock to the user's holdings and save them.
                [self.holdings addObject:stock];
                [self savePortfolio];
                // We're not on the main thread and the callback does UI updates, so call the callback on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(SUCCESS);
                });
            }
        }
        else // The data received was nil.
        {
            // We're not on the main thread and the callback does UI updates, so call the callback on the main thread.
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
        if ([s.ticker isEqualToString:stock.ticker]) // If the user is already watching this stock:
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
        
        if (data != nil) // Check that we actually received some data.
        {
            NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:Nil];
            
            // This API returns an empty JSON array if the stock doesn't exist, so all we have to do to check that this is a valid stock is see if the array has any contents.
            if (resultDict.count == 0) // The array doesn't have any data, so it's not a real stock.
            {
                // We're not on the main thread and the callback does UI updates, so call the callback on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(SYMBOL_NOT_FOUND);
                });
            }
            else // The array contains data, so the stock exists.
            {
                // Add the stock to the user's watched stocks and save them.
                [self.watching addObject:stock];
                [self savePortfolio];
                // We're not on the main thread and the callback does UI updates, so call the callback on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(SUCCESS);
                });
            }
        }
        else
        {
            // We're not on the main thread and the callback does UI updates, so call the callback on the main thread.
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
