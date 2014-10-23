//
//  STKApplicationCell.h
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STKApplicationCell, STKApplication;

@protocol STKApplicationCellDelegate <NSObject>

- (void)applicationCell:(STKApplicationCell *)cell didSelectApplication:(STKApplication *)app;

@end

@interface STKApplicationCell : NSTableCellView

+ (CGFloat)heightForApplicationCount:(NSUInteger)count;
@property (nonatomic, weak) id <STKApplicationCellDelegate> delegate;
@property (nonatomic, weak) NSArray *applications;
@end
