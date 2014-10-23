//
//  STKApplication.m
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import "STKApplication.h"
#import "STKDevice.h"


NSString * const STKApplicationBundleIdentifierKey = @"bundleIdentifier";
NSString * const STKApplicationInfoKey = @"compatibilityInfo";

@implementation STKApplication

@dynamic bundleIdentifier;
@dynamic bundlePath;
@dynamic sandboxPath;
@dynamic iconPath;
@dynamic device;

@synthesize files = _files;

- (NSError *)readFromMetadata:(NSDictionary *)metadata
{
    NSDictionary *compatInfo = [metadata objectForKey:STKApplicationInfoKey];
    if(!compatInfo) {
        return [NSError errorWithDomain:@"STKApplicationErrorDomain"
                                   code:-1
                               userInfo:@{@"reason" : @"No compatibility info."}];
    }
    
    [self setBundleIdentifier:[compatInfo objectForKey:STKApplicationBundleIdentifierKey]];
    
    [self setSandboxPath:[compatInfo objectForKey:@"sandboxPath"]];
    [self setBundlePath:[compatInfo objectForKey:@"bundlePath"]];
    
    // Ensure that both of these paths exist!
    if(![[NSFileManager defaultManager] fileExistsAtPath:[self sandboxPath]] || ![[NSFileManager defaultManager] fileExistsAtPath:[self bundlePath]]) {
        return [NSError errorWithDomain:@"STKApplicationErrorDomain" code:-1 userInfo:@{@"reason" : @"Metadata out of date, actual directories don't exist."}];
    }
    
    
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:[[self bundlePath] stringByAppendingPathComponent:@"Info.plist"]];
    
    NSDictionary *bundleIcons = [infoPlist objectForKey:@"CFBundleIcons"];
    if(!bundleIcons)
        bundleIcons = [infoPlist objectForKey:@"CFBundleIcons~ipad"];
    
    if(bundleIcons) {
        // Use newstyle
        NSDictionary *primaryIcons = [bundleIcons objectForKey:@"CFBundlePrimaryIcon"];
        NSArray *iconFiles = [primaryIcons objectForKey:@"CFBundleIconFiles"];
        if([iconFiles count] > 0) {
            NSString *lastFilename = [iconFiles lastObject];
            
            NSDirectoryEnumerator *de = [[NSFileManager defaultManager] enumeratorAtPath:[self bundlePath]];
            for(NSString *possibleIconPath in de) {
                if([possibleIconPath rangeOfString:lastFilename].location == 0) {
                    [self setIconPath:[[self bundlePath] stringByAppendingPathComponent:possibleIconPath]];
                    break;
                }
            }
        }
    } else {
        // Use oldstyle? 
    }
    
    
    return nil;
}

- (void)reloadFiles
{
    [self setFiles:[self filesystemItemsAtPath:[self sandboxPath]]];
}

- (NSArray *)filesystemItemsAtPath:(NSString *)path
{
    NSDirectoryEnumerator *de = [[NSFileManager defaultManager] enumeratorAtPath:path];
    
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for(NSString *p in de) {
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:p]
                                             isDirectory:&directory];
        if(!directory) {
            [a addObject:p];
        }
    }
    [a sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];
    
    return a;
}

@end
