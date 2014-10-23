//
//  STKApplication.h
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class STKDevice;

extern NSString * const STKApplicationBundleIdentifierKey;
extern NSString * const STKApplicationInfoKey;

@interface STKApplication : NSManagedObject

@property (nonatomic, retain) NSString * bundleIdentifier;
@property (nonatomic, retain) NSString * bundlePath;
@property (nonatomic, retain) NSString * sandboxPath;
@property (nonatomic, retain) NSString * iconPath;
@property (nonatomic, retain) STKDevice *device;

@property (nonatomic, strong) NSArray *files;

- (NSError *)readFromMetadata:(NSDictionary *)metadata;

- (void)reloadFiles;

@end
