//
//  STKDevice.m
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import "STKDevice.h"
#import "STKApplication.h"
#import "STKDevice.h"

@implementation STKDevice

@dynamic uniqueIdentifier;
@dynamic path;
@dynamic name;
@dynamic runtime;
@dynamic deviceType;
@dynamic applications;

- (NSString *)identifierString
{
    NSString *runtime = [[self runtime] stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime."
                                                                  withString:@""];

    NSRegularExpression *exp = [[NSRegularExpression alloc] initWithPattern:@"iOS-([0-9]*)-([0-9]*)"
                                                                    options:0
                                                                      error:nil];
    NSTextCheckingResult *tr = [exp firstMatchInString:runtime options:0 range:NSMakeRange(0, [runtime length])];
    
    if([tr numberOfRanges] > 2) {
        NSString *majorVersion = [runtime substringWithRange:[tr rangeAtIndex:1]];
        NSString *minorVersion = [runtime substringWithRange:[tr rangeAtIndex:2]];
        runtime = [NSString stringWithFormat:@"%@.%@", majorVersion, minorVersion];
    }

    
    NSString *deviceType = [[self deviceType] stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimDeviceType."
                                                                       withString:@""];
    deviceType = [deviceType stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    
    return [NSString stringWithFormat:@"%@ (iOS: %@)", deviceType, runtime];
}

- (NSError *)readFromPath:(NSString *)path
{
    NSDictionary *metadata = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"device.plist"]];
    
    if(!metadata) {
        return [NSError errorWithDomain:@"STKDeviceErrorDomain" code:-1 userInfo:@{@"reason" : @"No metadata file."}];
    }
    
    [self setPath:path];
    [self setUniqueIdentifier:[metadata objectForKey:@"UDID"]];
    [self setDeviceType:[metadata objectForKey:@"deviceType"]];
    [self setName:[metadata objectForKey:@"name"]];
    [self setRuntime:[metadata objectForKey:@"runtime"]];
    
    NSDictionary *appMetadata = [NSDictionary dictionaryWithContentsOfFile:[self applicationMetadataPath]];
    if(!appMetadata) {
        return [NSError errorWithDomain:@"STKDeviceErrorDomain" code:-1 userInfo:@{@"reason" : @"No application metadata file."}];
    }

    for(NSDictionary *appData in [appMetadata allValues]) {
        [self addApplicationWithMetadata:appData];
    }
    
    return nil;
}

- (NSString *)applicationMetadataPath
{
    return [[self path] stringByAppendingPathComponent:@"data/Library/BackBoard/applicationState.plist"];
}

- (void)addApplicationWithMetadata:(NSDictionary *)metadata
{
    STKApplication *app = [NSEntityDescription insertNewObjectForEntityForName:@"STKApplication"
                                                        inManagedObjectContext:[self managedObjectContext]];
    NSError *err = [app readFromMetadata:metadata];
    if(err) {
        [[self managedObjectContext] deleteObject:app];
    } else {
        [app setDevice:self];
    }
}

- (void)updateApplicationWithMetadata:(NSDictionary *)metadata
{
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"STKApplication"];
    NSString *bundleID = [[metadata objectForKey:STKApplicationInfoKey] objectForKey:STKApplicationBundleIdentifierKey];
    [req setPredicate:[NSPredicate predicateWithFormat:@"bundleIdentifier == %@ and device.uniqueIdentifier == %@", bundleID, [self uniqueIdentifier]]];
    
    NSArray *results = [[self managedObjectContext] executeFetchRequest:req error:nil];
    if([results count] == 1) {
        STKApplication *app = [results lastObject];
        [app readFromMetadata:metadata];
    }
    
}

- (void)deleteApplicationWithBundleID:(NSString *)bundleID
{
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"STKApplication"];
    [req setPredicate:[NSPredicate predicateWithFormat:@"bundleIdentifier == %@ and device.uniqueIdentifier == %@", bundleID, [self uniqueIdentifier]]];
    
    NSArray *results = [[self managedObjectContext] executeFetchRequest:req error:nil];
    for(STKApplication *obj in results) {            
        [[self managedObjectContext] deleteObject:obj];
    }
}

- (void)refreshApplications
{
    NSDictionary *appMetadata = [NSDictionary dictionaryWithContentsOfFile:[self applicationMetadataPath]];
    if(!appMetadata) {
        @throw [NSException exceptionWithName:@"STKDeviceException" reason:@"Application metadata does not exist when refreshing." userInfo:@{@"udid" : [self uniqueIdentifier]}];
    }
    
    NSMutableArray *newBundleIDs = [[[[appMetadata allValues] valueForKey:STKApplicationInfoKey] valueForKey:STKApplicationBundleIdentifierKey] mutableCopy];
    [newBundleIDs removeObjectIdenticalTo:[NSNull null]];
    
    NSSet *currentBundleIDs = [[self applications] valueForKey:@"bundleIdentifier"];
    
    NSArray *additions = [newBundleIDs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"not (self in %@)", currentBundleIDs]];
    NSSet *deletions = [currentBundleIDs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"not (self in %@)", newBundleIDs]];
    NSSet *updates = [currentBundleIDs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"self in %@", newBundleIDs]];
    
    for(NSString *bundleID in additions) {
        // The bundleID is both the key in the top-level dictionary as well as a field in the info dictionary
        // so this is ok.
        NSDictionary *m = [appMetadata objectForKey:bundleID];
        [self addApplicationWithMetadata:m];
    }

    for(NSString *bundleID in updates) {
        // The bundleID is both the key in the top-level dictionary as well as a field in the info dictionary
        // so this is ok.
        NSDictionary *m = [appMetadata objectForKey:bundleID];
        [self updateApplicationWithMetadata:m];
    }

    for(NSString *bundleID in deletions) {
        // The bundleID is both the key in the top-level dictionary as well as a field in the info dictionary
        // so this is ok.
        [self deleteApplicationWithBundleID:bundleID];
    }
}

@end
