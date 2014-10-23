//
//  STKCommandWindowController.m
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import "STKCommandWindowController.h"
#import "STKSimulatorStore.h"
#import "STKApplicationCell.h"
#import "STKApplication.h"
#import "STKColors.h"
#import "STKTableHeaderView.h"
#import "STKDevice.h"



@interface STKCommandWindowController () <NSTableViewDataSource, NSTableViewDelegate, STKApplicationCellDelegate>

@property (nonatomic, strong) NSDictionary *applicationGroups;
@property (nonatomic, strong) NSArray *sortedApplicationKeys;
@property (weak) IBOutlet NSTableView *applicationTableView;
@property (nonatomic, strong) STKApplication *selectedApplication;
@property (weak) IBOutlet NSTableView *fileTableView;

@property (weak) IBOutlet NSImageView *selectedApplicationImageView;
@property (weak) IBOutlet NSTextField *selectedApplicationTitleLabel;
@property (weak) IBOutlet NSButton *openBundleButton;
@property (weak) IBOutlet NSButton *openSandboxButton;

@end

@implementation STKCommandWindowController

- (void)windowWillLoad
{
    [super windowWillLoad];
}

- (void)applicationsDidChange:(NSNotification *)note
{
    [self setApplicationGroups:[[STKSimulatorStore store] applicationGroups]];
    [[self applicationTableView] reloadData];
    [self reloadFiles];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationsDidChange:) name:STKSimulatorStoreDeviceDidUpdateNotification object:nil];
    
    STKTableHeaderView *th = [[STKTableHeaderView alloc] init];
    [[self fileTableView] setHeaderView:th];
    
    [[self fileTableView] setTarget:self];
    [[self fileTableView] setDoubleAction:@selector(doubleClickRow:)];
    
    [[self window] setBackgroundColor:[NSColor whiteColor]];
    
    [[self selectedApplicationImageView] setWantsLayer:YES];
    [[[self selectedApplicationImageView] layer] setBorderWidth:1];
    [[[self selectedApplicationImageView] layer] setCornerRadius:10];
    [[[self selectedApplicationImageView] layer] setBorderColor:[[NSColor clearColor] CGColor]];
    [[[self selectedApplicationImageView] layer] setMasksToBounds:YES];

    NSDictionary *textAttrs = @{
                                NSForegroundColorAttributeName : STKTextColor,
                                NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:12]
                                };

    [[self openBundleButton] setBordered:NO];
    [[self openBundleButton] setBezelStyle:NSInlineBezelStyle];
    [[self openBundleButton] setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Open Bundle"
                                                                                attributes:textAttrs]];
    [[self openSandboxButton] setBordered:NO];
    [[self openSandboxButton] setBezelStyle:NSInlineBezelStyle];
    [[self openSandboxButton] setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Open Sandbox"
                                                                                attributes:textAttrs]];
    
    
    [[self applicationTableView] setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    NSNib *appCellNib = [[NSNib alloc] initWithNibNamed:@"STKApplicationCell" bundle:nil];
    [[self applicationTableView] registerNib:appCellNib forIdentifier:@"STKApplicationCell"];

    [self setApplicationGroups:[[STKSimulatorStore store] applicationGroups]];
    [[self applicationTableView] reloadData];
    [self setSelectedApplication:nil];

    
}

- (void)doubleClickRow:(NSTableView *)tv
{
    NSUInteger row = [tv clickedRow];
    NSString *pathFrag = [[[self selectedApplication] files] objectAtIndex:row];
    
    NSString *fullPath = [[[self selectedApplication] sandboxPath] stringByAppendingPathComponent:pathFrag];
    
    if([[fullPath pathExtension] isEqualToString:@"db"] || [[fullPath pathExtension] isEqualToString:@"sqlite"]) {
        NSString *s = [NSString stringWithFormat:@"tell application \"Terminal\" to do script \"sqlite3 %@\"", fullPath];
        
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource:s];
        [as executeAndReturnError:nil];
    } else {
        if(![[NSWorkspace sharedWorkspace] openFile:fullPath]) {
            [[NSWorkspace sharedWorkspace] selectFile:fullPath
                             inFileViewerRootedAtPath:[fullPath stringByDeletingLastPathComponent]];
        }
    }
}

- (void)setApplicationGroups:(NSDictionary *)applicationGroups
{
    _applicationGroups = applicationGroups;
    
    [self setSortedApplicationKeys:[[_applicationGroups allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 caseInsensitiveCompare:obj2];
    }]];
}

- (IBAction)openBundle:(id)sender
{
    [[NSWorkspace sharedWorkspace] selectFile:[[self selectedApplication] bundlePath]
                     inFileViewerRootedAtPath:[[self selectedApplication] bundlePath]];
}

- (IBAction)openSandbox:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[[self selectedApplication] sandboxPath]];
}

- (void)setSelectedApplication:(STKApplication *)selectedApplication
{
    _selectedApplication = selectedApplication;
    
    [self reloadViews];
    [self reloadFiles];
}

- (void)reloadFiles
{
    [_selectedApplication reloadFiles];
    [[self fileTableView] reloadData];
}

- (void)reloadViews
{
    [[self selectedApplicationImageView] setImage:[[NSImage alloc] initWithContentsOfFile:[[self selectedApplication] iconPath]]];
    
    if(![self selectedApplication]) {
        [[self selectedApplicationTitleLabel] setStringValue:@""];

        [[self openSandboxButton] setHidden:YES];
        [[self openBundleButton] setHidden:YES];
    } else {
        NSString *titleString = [NSString stringWithFormat:@"%@ - %@",
                                 [[self selectedApplication] bundleIdentifier],
                                 [[[self selectedApplication] device] identifierString]];
        [[self selectedApplicationTitleLabel] setStringValue:titleString];
        [[self openSandboxButton] setHidden:NO];
        [[self openBundleButton] setHidden:NO];
    }

}

- (void)applicationCell:(STKApplicationCell *)cell didSelectApplication:(STKApplication *)app
{
    [self setSelectedApplication:app];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if([self fileTableView] == tableView) {
        return [[[self selectedApplication] files] count];
    }
    
    return [[self sortedApplicationKeys] count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if(tableView == [self applicationTableView]) {
        NSArray *apps = [[self applicationGroups] objectForKey:[[self sortedApplicationKeys] objectAtIndex:row]];
        
        return [STKApplicationCell heightForApplicationCount:[apps count]];
    }
    
    return 18;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == [self fileTableView]) {
        NSTextField *result = [tableView makeViewWithIdentifier:@"NSTextField" owner:self];
        
        if (!result) {
            result = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, [tableView bounds].size.width, 0)];
            [result setIdentifier:@"NSTextField"];
            [result setEditable:NO];
            [result setBordered:NO];
            [result setBackgroundColor:[NSColor clearColor]];
            [[result cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        }
        
        NSString *str = [[[self selectedApplication] files] objectAtIndex:row];
        if([[tableColumn identifier] isEqualToString:@"filename"]) {
            [result setTextColor:STKTextColor];
            [result setStringValue:[str lastPathComponent]];
        } else if ([[tableColumn identifier] isEqualToString:@"fullPath"]) {
            [result setTextColor:[STKTextColor colorWithAlphaComponent:0.5]];
            [result setStringValue:[str stringByDeletingLastPathComponent]];
        }
        
        return result;
    } else if (tableView == [self applicationTableView]) {
        
        STKApplicationCell *c = [tableView makeViewWithIdentifier:@"STKApplicationCell" owner:self];
        [c setDelegate:self];
        
        NSString *key = [[self sortedApplicationKeys] objectAtIndex:row];
        [[c textField] setStringValue:key];
        [c setApplications:[[self applicationGroups] objectForKey:key]];
        
        
        return c;
    }
    return nil;
}

@end
