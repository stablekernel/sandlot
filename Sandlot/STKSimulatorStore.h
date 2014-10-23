//
//  STKSimulatorStore.h
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const STKSimulatorStoreDeviceDidUpdateNotification;
extern NSString * const STKSimulatorStoreDeviceKey;

@interface STKSimulatorStore : NSObject

+ (STKSimulatorStore *)store;

- (void)constructSimulatorGraphWithPath:(NSString *)path;

- (NSDictionary *)applicationGroups;

- (NSArray *)devices;
- (NSArray *)applications;

@end
