//
//  JCTableView+JCAnimation.m
//  JCTableView
//
//  Created by 林锦超 on 18/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableView+JCAnimation.h"

@implementation JCTableView (JCAnimation)

- (void)_prepareInsertCell:(JCTableViewCell *)cell padding:(CGFloat)padding withAnimation:(JCTableViewRowAnimation)animation
{
    CGRect startFrame = cell.frame;
    
    switch (animation) {
        case JCTableViewRowAnimationNone:
            break;
            
        case JCTableViewRowAnimationFade:
            cell.alpha = 0.f;
            break;
            
        case JCTableViewRowAnimationRight:
            startFrame = CGRectOffset(cell.frame, CGRectGetWidth(cell.frame), 0);
            startFrame.size.height = 0.f;
            break;
            
        case JCTableViewRowAnimationLeft:
            startFrame = CGRectOffset(cell.frame, -CGRectGetWidth(cell.frame), 0);
            startFrame.size.height = 0.f;
            break;
            
        case JCTableViewRowAnimationTop:
        case JCTableViewRowAnimationBottom:
            startFrame = CGRectOffset(cell.frame, 0, -CGRectGetHeight(cell.frame));
            break;
            
        default:
            break;
    }
    
    // previous
    startFrame.origin.y -= padding;
//    NSLog(@"startFrame.origin.y:%f", startFrame.origin.y);
    
    cell.frame = startFrame;
}

- (void)_prepareReloadCell:(JCTableViewCell *)cell withAnimation:(JCTableViewRowAnimation)animation
{
    CGRect startFrame = cell.frame;
    
    switch (animation) {
        case JCTableViewRowAnimationNone:
            break;
            
        case JCTableViewRowAnimationFade:
            cell.alpha = 0.7f;
            break;
            
        case JCTableViewRowAnimationRight:
            startFrame = CGRectOffset(cell.frame, -CGRectGetWidth(cell.frame), 0);
            break;
            
        case JCTableViewRowAnimationLeft:
            startFrame = CGRectOffset(cell.frame, CGRectGetWidth(cell.frame), 0);
            break;
            
        // reload 之前的cell发生动画
        case JCTableViewRowAnimationTop:
            break;
            
        case JCTableViewRowAnimationBottom:
            startFrame = CGRectOffset(cell.frame, 0, -CGRectGetHeight(cell.frame));
            break;
            
        default:
            break;
    }
    cell.frame = startFrame;
}

- (CGRect)_prepareReloadFrame:(CGRect)frame withAnimation:(JCTableViewRowAnimation)animation
{
    CGRect destFrame = frame;
    if (animation == JCTableViewRowAnimationTop) {
        destFrame = CGRectOffset(frame, 0, -CGRectGetHeight(frame));
    }
    return destFrame;
}
@end
