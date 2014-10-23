//
//  STKApplicationCell.m
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import "STKApplicationCell.h"
#import "STKApplication.h"
#import "STKDevice.h"
#import "STKColors.h"

const CGFloat STKApplicationCellButtonHeight = 24;
const CGFloat STKApplicationCellButtonMargin = 4;
const CGFloat STKApplicationCellIconSize = 60;

@interface STKApplicationCell ()

@property (weak) IBOutlet NSView *deviceContainer;
@property (nonatomic, strong) NSArray *buttons;
@property (weak) IBOutlet NSBox *dividerView;

@end

@implementation STKApplicationCell

+ (CGFloat)heightForApplicationCount:(NSUInteger)count
{
    float nameArea = 8 + 8 + 17;
    float buttonPadding = 8 + 4;
    float buttonArea = count * STKApplicationCellButtonHeight;
    
    float total = nameArea + buttonArea + buttonPadding;
    if(total < STKApplicationCellIconSize + 16) {
        return STKApplicationCellIconSize + 16;
    }
    
    return total;
}

- (void)awakeFromNib
{
    [[self imageView] setWantsLayer:YES];
    [[[self imageView] layer] setBorderWidth:1];
    [[[self imageView] layer] setCornerRadius:10];
    [[[self imageView] layer] setBorderColor:[[NSColor clearColor] CGColor]];
    [[[self imageView] layer] setMasksToBounds:YES];
    
    [[self dividerView] setBorderType:NSNoBorder];
    [[self dividerView] setFillColor:[[[self textField] textColor] colorWithAlphaComponent:0.5]];
}

- (void)setApplications:(NSArray *)applications
{
    _applications = applications;
    
    STKApplication *anyApp = [applications lastObject];
    [[self imageView] setImage:[[NSImage alloc] initWithContentsOfFile:[anyApp iconPath]]];

    [self configureButtonsFromApplicationList:applications];
}

- (void)configureButtonsFromApplicationList:(NSArray *)appList
{
    [[[self deviceContainer] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSMutableArray *a = [NSMutableArray array];
    
    NSDictionary *textAttrs = @{
                                NSForegroundColorAttributeName : STKTextColor,
                                NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:12]
                                };
    for(STKApplication *app in appList) {
        NSButton *b = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 200, STKApplicationCellButtonHeight)];
        [b setBordered:NO];
        [b setBezelStyle:NSInlineBezelStyle];
        [b setTranslatesAutoresizingMaskIntoConstraints:NO];
        [b setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
        [b setTarget:self];
        [b setAction:@selector(buttonTapped:)];

        STKDevice *device = [app device];
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:[device identifierString]
                                                                    attributes:textAttrs];
        [b setAttributedTitle:title];
        [[self deviceContainer] addSubview:b];

        
        [a addObject:b];
    }

    [self setButtons:[a copy]];
    
    [self layoutButtons];
}

- (void)buttonTapped:(id)sender
{
    NSUInteger idx = [[self buttons] indexOfObject:sender];
    
    STKApplication *app = [[self applications] objectAtIndex:idx];
    
    [[self delegate] applicationCell:self
                didSelectApplication:app];
}

- (void)layoutButtons
{
    NSButton *prevButton = nil;
    for(NSButton *b in [self buttons]) {
        
        NSArray *vertical = nil;
        if(prevButton) {
            vertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prev][this(==height)]"
                                                               options:0
                                                               metrics:@{@"padding" : @(STKApplicationCellButtonMargin), @"height" : @(STKApplicationCellButtonHeight)}
                                                                 views:@{@"prev" : prevButton, @"this" : b}];
        } else {
            vertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[this(==height)]"
                                                               options:0
                                                               metrics:@{@"padding" : @(STKApplicationCellButtonMargin), @"height" : @(STKApplicationCellButtonHeight)}
                                                                 views:@{@"this" : b}];
        }
        [[self deviceContainer] addConstraints:vertical];
        
        [[self deviceContainer] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                                                       options:0
                                                                                       metrics:nil
                                                                                         views:@{@"v" : b}]];
        
        prevButton = b;
    }
    /*
    if([[self buttons] count] > 0) {
        [[self deviceContainer] addConstraint:[NSLayoutConstraint constraintWithItem:[self deviceContainer]
                                                                           attribute:NSLayoutAttributeBottom
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:[[self buttons] lastObject]
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1
                                                                            constant:0]];
    }*/
}


@end
