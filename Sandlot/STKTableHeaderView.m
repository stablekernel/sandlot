//
//  STKTableHeaderView.m
//  Sandlot
//
//  Created by Joe Conway on 10/23/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import "STKTableHeaderView.h"
#import "STKColors.h"

@implementation STKTableHeaderView

- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] setFill];
    NSRectFill([self bounds]);
    
    if([[self tableView] numberOfRows] > 0) {
        [STKTextColor setStroke];
        CGRect columnRect = [self headerRectOfColumn:0];
        NSBezierPath *bp = [NSBezierPath bezierPath];
        [bp moveToPoint:CGPointMake(columnRect.size.width, 0)];
        [bp lineToPoint:CGPointMake(columnRect.size.width, columnRect.size.height)];
        [bp stroke];
    }
}

@end
