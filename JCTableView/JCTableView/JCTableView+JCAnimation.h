//
//  JCTableView+JCAnimation.h
//  JCTableView
//
//  Created by 林锦超 on 18/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableView.h"

@interface JCTableView (JCAnimation)

// insert
- (void)_prepareInsertCell:(JCTableViewCell *)cell padding:(CGFloat)padding withAnimation:(JCTableViewRowAnimation)animation;
// delete
- (CGRect)_prepareDeleteCell:(JCTableViewCell *)cell withAnimation:(JCTableViewRowAnimation)animation;
// reload
- (void)_prepareReloadCell:(JCTableViewCell *)cell withAnimation:(JCTableViewRowAnimation)animation;
- (CGRect)_prepareReloadFrame:(CGRect)frame withAnimation:(JCTableViewRowAnimation)animation;
@end
