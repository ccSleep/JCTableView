//
//  JCSwipeActionPullView.m
//  JCTableView
//
//  Created by 林锦超 on 19/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCSwipeActionPullView.h"
#import "JCTableViewCell.h"
#import "JCTableViewCellPrivate.h"

#define kJCSwipeActionButtonMargin  2.f
CGFloat const JCSwipeActionPullViewWidth = 74.f;

@interface JCSwipeActionPullView()
@property (nonatomic, strong) UIButton *actionButton;
@end
@implementation JCSwipeActionPullView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:252/255.f green:60/255.f blue:57/255.f alpha:1.f];
        
        [self addSubview:self.actionButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize size = self.bounds.size;
    self.actionButton.frame = CGRectMake(kJCSwipeActionButtonMargin, 0, size.width - 2*kJCSwipeActionButtonMargin, size.height);
}

- (UIButton *)actionButton
{
    if (!_actionButton) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _actionButton.backgroundColor = self.backgroundColor;
        [_actionButton setTitle:@"delete" forState:UIControlStateNormal];
        [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_actionButton addTarget:self action:@selector(_handleActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionButton;
}

- (IBAction)_handleActionButtonPressed:(id)sender
{
    [self swipeToHide];
    if (self.actionHandler) {
        self.actionHandler(self.swipingCell);
    }
}

#pragma mark - Animation
- (void)swipeToShow
{
    [self.swipingCell setSelected:NO animated:NO];
    
    [UIView animateWithDuration:.25f animations:^{
        self.swipingCell.frame = CGRectOffset(self.swipingCell.frame, -JCSwipeActionPullViewWidth, 0);
        self.frame = CGRectOffset(self.frame, -JCSwipeActionPullViewWidth, 0);
    }];
}

- (void)swipeToHide
{
    CGFloat padding = fabs(CGRectGetMinX(self.swipingCell.frame));
    [UIView animateWithDuration:.25f animations:^{
        self.swipingCell.frame = CGRectOffset(self.swipingCell.frame, padding, 0);
        self.frame = CGRectOffset(self.frame, padding, 0);
    } completion:^(BOOL finished) {
        self.swipingCell.swipingView = nil;
        
        if (self.hideCompletionHandler) {
            self.hideCompletionHandler(self);
        }
    }];
}

@end
