//
//  STKDevice.h
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class STKApplication;

@interface STKDevice : NSManagedObject

@property (nonatomic, strong) NSString *uniqueIdentifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * runtime;
@property (nonatomic, retain) NSString * deviceType;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSSet *applications;
@property (nonatomic, readonly) NSString *applicationMetadataPath;

- (NSError *)readFromPath:(NSString *)path;

- (void)refreshApplications;
- (NSString *)identifierString;

@end



@interface STKDevice (CoreDataGeneratedAccessors)

- (void)addApplicationsObject:(STKApplication *)value;
- (void)removeApplicationsObject:(STKApplication *)value;
- (void)addApplications:(NSSet *)values;
- (void)removeApplications:(NSSet *)values;

@end
