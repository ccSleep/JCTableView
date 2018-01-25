//
//  JCTableViewCell+Private.h
//  JCTableView
//
//  Created by 林锦超 on 12/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableViewCell.h"
#import "JCSwipeActionPullView.h"

@interface JCTableViewCell ()
@property (nonatomic, strong) NSIndexPath *indexPath;
//@property (nonatomic, assign, getter=isSwiping) BOOL swiping;
@property (nonatomic, weak) JCSwipeActionPullView *swipingView;
@end
