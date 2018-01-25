//
//  JCSwipeActionPullView.h
//  JCTableView
//
//  Created by 林锦超 on 19/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JCTableViewCell, JCSwipeActionPullView;

typedef void(^JCSwipeActionPullViewActionHandler)(JCTableViewCell *associatedCell);
typedef void(^JCSwipeActionPullViewHideCompletionHandler)(JCSwipeActionPullView *swipeView);

@interface JCSwipeActionPullView : UIView
@property (nonatomic, weak) JCTableViewCell *swipingCell;
@property (nonatomic, copy) JCSwipeActionPullViewHideCompletionHandler hideCompletionHandler;
@property (nonatomic, copy) JCSwipeActionPullViewActionHandler actionHandler;

- (void)swipeToShow;
- (void)swipeToHide;
@end

extern CGFloat const JCSwipeActionPullViewWidth;

