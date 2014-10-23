//
//  STKSimulatorStore.m
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import "STKSimulatorStore.h"
#import "STKApplication.h"
#import "STKDevice.h"

NSString * const STKSimulatorStoreDeviceDidUpdateNotification = @"STKSimulatorStoreDeviceDidUpdateNotification";
NSString * const STKSimulatorStoreDeviceKey = @"STKSimulatorStoreDeviceKey";


@import CoreData;

@interface STKSimulatorStore ()
@property (nonatomic, strong, readonly) NSManagedObjectContext *context;
@property (nonatomic, strong) NSMutableDictionary *deviceMonitors;
@end

@implementation STKSimulatorStore
@synthesize context = _context;

+ (STKSimulatorStore *)store
{
    static STKSimulatorStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[STKSimulatorStore alloc] init];
    });
    
    return store;
}

- (id)init
{
    self = [super init];
    if(self) {
        _deviceMonitors = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSManagedObjectContext *)context
{
    if(!_context) {
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Schema"
                                                                                                                withExtension:@"momd"]];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        NSError *error = nil;
        if(![psc addPersistentStoreWithType:NSInMemoryStoreType
                              configuration:nil
                                        URL:nil
                                    options:nil
                                      error:&error]) {
            [NSException raise:@"Open failed" format:@"Reason %@", [error localizedDescription]];
        }
        
        NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] init];
        [ctx setPersistentStoreCoordinator:psc];
        [ctx setUndoManager:nil];
        _context = ctx;
    }
    
    return _context;
}

- (NSArray *)devices
{
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"STKDevice"];
    return [[self context] executeFetchRequest:req error:nil];
}

- (NSArray *)applications
{
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"STKApplication"];
    return [[self context] executeFetchRequest:req error:nil];

}

- (void)constructSimulatorGraphWithPath:(NSString *)path
{
    NSArray *deviceDirectoryList = [self deviceDirectoryListAtPath:path];
    
    for(NSString *deviceDirectoryPath in deviceDirectoryList) {
        STKDevice *d = [NSEntityDescription insertNewObjectForEntityForName:@"STKDevice"
                                                     inManagedObjectContext:[self context]];
        NSError *err = [d readFromPath:deviceDirectoryPath];
        if(err) {
            [[self context] deleteObject:d];
        }
    }
    
    [[self context] save:nil];
    
    for(STKDevice *device in [self devices]) {
        [self monitorDeviceApplicationStateForUDID:[device uniqueIdentifier]
                                      metadataPath:[device applicationMetadataPath]];
    }
    
}

- (NSArray *)deviceDirectoryListAtPath:(NSString *)rootPath
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    NSDirectoryEnumerator *de = [[NSFileManager defaultManager] enumeratorAtPath:rootPath];
    
    for(NSString *devicePath in de) {
        NSString *absoluteDevicePath = [rootPath stringByAppendingPathComponent:devicePath];
        NSString *deviceMetadataPath = [absoluteDevicePath stringByAppendingPathComponent:@"device.plist"];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:deviceMetadataPath]) {
            [list addObject:absoluteDevicePath];
        }
        
        [de skipDescendants];

    }
    
    return [list copy];
}

- (NSDictionary *)applicationGroups
{
    /* Apparently distinct results don't work for in-memory stores, bummer.
     
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"STKApplication"];
    [req setPropertiesToFetch:@[@"bundleIdentifier"]];
    [req setReturnsDistinctResults:YES];
    [req setResultType:NSDictionaryResultType];
    
    NSArray *results = [[self context] executeFetchRequest:req error:nil];
    NSLog(@"%@", results);
    return [results valueForKey:@"bundleIdentifier"];
     */
    
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"STKApplication"];
    [req setPropertiesToFetch:@[@"bundleIdentifier"]];
    [req setResultType:NSDictionaryResultType];
    
    NSArray *results = [[[self context] executeFetchRequest:req error:nil] valueForKey:@"bundleIdentifier"];
    NSSet *distinctSet = [NSSet setWithArray:results];
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for(NSString *bundleID in distinctSet) {
        NSFetchRequest *appsReq = [NSFetchRequest fetchRequestWithEntityName:@"STKApplication"];
        [appsReq setPredicate:[NSPredicate predicateWithFormat:@"bundleIdentifier == %@", bundleID]];
        
        [result setObject:[[self context] executeFetchRequest:appsReq error:nil] forKey:bundleID];
    }
    
    return result;
}

- (void)refreshDeviceApplicationsForUDID:(NSString *)udid
{
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"STKDevice"];
    [req setPredicate:[NSPredicate predicateWithFormat:@"uniqueIdentifier == %@", udid]];
    
    NSArray *results = [[self context] executeFetchRequest:req error:nil];
    
    if([results count] != 1) {
        // Shouldn't happen unless someone called it from outside where it should be called;
        // otherwise, this method should only be called in response to a monitored app state file,
        // so the device must exist, otherwise, how did we set up the monitor?
        @throw [NSException exceptionWithName:@"STKSimulatorStoreException" reason:@"Multiple devices or missing device for a given UDID." userInfo:@{@"devices" : results, @"udid" : udid}];
    }
    
    
    STKDevice *d = [results lastObject];
    [d refreshApplications];
    [[self context] save:nil];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:STKSimulatorStoreDeviceDidUpdateNotification
                                                        object:self
                                                      userInfo:@{STKSimulatorStoreDeviceKey : d}];
    
}

- (void)monitorDeviceApplicationStateForUDID:(NSString *)udid metadataPath:(NSString *)metadataPath
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    int fileDescriptor = open([metadataPath UTF8String], O_EVTONLY);
    
    __weak STKSimulatorStore *s = self;
    dispatch_source_t monitor = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                       fileDescriptor,
                                                       DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE,
                                                       queue);
    __weak dispatch_source_t weakMonitor = monitor;
    
    dispatch_source_set_event_handler(monitor, ^{
        dispatch_source_cancel(weakMonitor);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[s deviceMonitors] removeObjectForKey:udid];
            [s monitorDeviceApplicationStateForUDID:udid metadataPath:metadataPath];
            [s refreshDeviceApplicationsForUDID:udid];
        });
    });
    
    dispatch_source_set_cancel_handler(monitor, ^{
        close(fileDescriptor);
    });
    
    dispatch_resume(monitor);
    
    [[self deviceMonitors] setObject:monitor forKey:udid];
}


@end
