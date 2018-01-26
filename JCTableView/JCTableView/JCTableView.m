//
//  JCTableView.m
//  JCTableView
//
//  Created by 林锦超 on 11/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableView.h"
#import "JCTableView+JCAnimation.h"
#import "JCTableViewCellPrivate.h"
#import "JCSwipeActionPullView.h"
#import <objc/runtime.h>

#define kJCTableViewCellHeightDefault   44.f

#define kRespondsToSelector(id, SEL)        (id && [id respondsToSelector:SEL])
#define kDelegateRespondsToSelector(SEL)    kRespondsToSelector(self.delegate, SEL)
#define kDataSourceRespondsToSelector(SEL)  kRespondsToSelector(self.dataSource, SEL)

@interface JCTableView()
@property (nonatomic, weak) id<JCTableViewDelegate> jcDelegate;

/// recycle
@property (nonatomic, strong) NSMutableSet<__kindof JCTableViewCell *> *recycledCells;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *registerdIdentifierClassMap;  //@{ id : Class }
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, __kindof JCTableViewCell *> *visibleIndexCellMap; //@{ indexPath : cell }
@property (nonatomic, strong, nullable, readwrite) NSArray<NSIndexPath *> *indexPathsForVisibleRows;    //sorted
@property (nonatomic, strong, nullable, readwrite) NSIndexPath *indexPathForSelectedRow;    // returns nil or index path representing section and row of selection.

/// layout
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *cellIndexHeightMap;   // @{ indexPath : @(float) }
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *cellIndexOffsetYMap;  // @{ indexPath : @(float) }

/// sections
@property (nonatomic, assign, readwrite) NSInteger numberOfSections;

/// editing
@property (nonatomic, assign) BOOL canEditRow;

@property (nonatomic, strong) NSMutableSet<JCSwipeActionPullView *> *recycledSwipeViews;
@property (nonatomic, strong) JCSwipeActionPullView *previousSwipeView;
@property (nonatomic, assign) CGPoint panStartPoint;
@end

@implementation JCTableView

@dynamic delegate;

#pragma mark - LifeCycle
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self _setup];
        [self _setupGestureRecognizer];
    }
    return self;
}

- (void)_setup
{
    /// recycle
    _recycledCells = [NSMutableSet set];
    _registerdIdentifierClassMap = [NSMutableDictionary dictionary];
    _visibleIndexCellMap = [NSMutableDictionary dictionary];
    
    /// layout
    _cellIndexHeightMap = [NSMutableDictionary dictionary];
    _cellIndexOffsetYMap = [NSMutableDictionary dictionary];
    
    ///
    _numberOfSections = 1;
    
    /// swipe
    _recycledSwipeViews = [NSMutableSet setWithCapacity:2];
    
    self.alwaysBounceVertical = YES;
}

- (void)_setupGestureRecognizer
{
    // tap to selection
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTableViewTapped:)];
    [self addGestureRecognizer:tapGR];
    
    // pan to swipe
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGestureRecognizer:)];
    panGR.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:panGR];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    CFTimeInterval timeStart = CACurrentMediaTime();
    
    NSArray *indexPathsForVisibleRows = [self _indexPathForVisibleCells];
    if ([indexPathsForVisibleRows isEqualToArray:_indexPathsForVisibleRows]) {
        return;
    }
    
    _indexPathsForVisibleRows = indexPathsForVisibleRows;
    [_indexPathsForVisibleRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        JCTableViewCell *cell = [self cellForRowAtIndexPath:indexPath created:YES];
        [self _insertCell:cell atIndexPath:indexPath];
    }];
    
    [self _recoverUnvisibleCellsWithVisibleIndexPaths:_indexPathsForVisibleRows];
    
    // 0.000248
//    NSLog(@"layoutSubviews timeEclips:%f", CACurrentMediaTime() - timeStart);
}

#pragma mark - Accessor
- (void)setDataSource:(id<JCTableViewDataSource>)dataSource
{
    _dataSource = dataSource;
    
    [self _resizeTableContent];
}

- (void)setDelegate:(id<JCTableViewDelegate>)delegate
{
    super.delegate = delegate;
    
    _jcDelegate = delegate;
    _canEditRow = [_jcDelegate respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)];
    
    [self _resizeTableContent];
}

- (id<JCTableViewDelegate>)delegate
{
    return _jcDelegate;
}

#pragma mark - Recycle
/// Used by the delegate to acquire an already allocated cell
- (nullable __kindof JCTableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    __block JCTableViewCell *cell = nil;
    [self.recycledCells enumerateObjectsUsingBlock:^(__kindof JCTableViewCell * _Nonnull one, BOOL * _Nonnull stop) {
        if ([one.reuseIdentifier isEqualToString:identifier]) {
            cell = one;
            *stop = YES;
        }
    }];
    
    if (cell) {
        [self.recycledCells removeObject:cell];
    }
    else {
        // identifier has been registered
        if ([self.registerdIdentifierClassMap.allKeys containsObject:identifier]) {
            Class cls = [self.registerdIdentifierClassMap objectForKey:identifier];
            
            if ([cls instancesRespondToSelector:@selector(initWithReuseIdentifier:)]) {
                cell = [[cls alloc] initWithReuseIdentifier:identifier];
            }
            else {
                NSAssert(0 == 1, @"must pass a class of kind JCTableViewCell"); //always assert
            }
        }
    }
    return cell;
}

- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier
{
    [self.registerdIdentifierClassMap setValue:cellClass forKey:identifier];
}

- (void)_enqueueReusableCell:(JCTableViewCell *)cell
{
    if (cell) {
        [cell prepareForReuse];
        [cell removeFromSuperview];
        [self.recycledCells addObject:cell];
    }
}

- (void)_recoverUnvisibleCellsWithVisibleIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    [self.visibleIndexCellMap enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSIndexPath * _Nonnull key, __kindof JCTableViewCell * _Nonnull cell, BOOL * _Nonnull stop) {
        // unvisible
        if (![indexPaths containsObject:key]) {
            [self.visibleIndexCellMap removeObjectForKey:key];
            [self _enqueueReusableCell:cell];
        }
    }];
}

- (void)_recoverTotalVisibleCells
{
    [self.visibleIndexCellMap enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSIndexPath * _Nonnull key, __kindof JCTableViewCell * _Nonnull cell, BOOL * _Nonnull stop) {
        [self.visibleIndexCellMap removeObjectForKey:key];
        [self _enqueueReusableCell:cell];
    }];
    
    _indexPathsForVisibleRows = @[];
}

#pragma mark - Layout
- (void)_resizeTableContent
{
//    CFTimeInterval timeStart = CACurrentMediaTime();
    
    [_cellIndexHeightMap removeAllObjects];
    [_cellIndexOffsetYMap removeAllObjects];
    
    CGFloat padding = 0.f;
    for (NSInteger section = 0; section < self.numberOfSections; section++) {
        for (NSInteger row = 0; row < [self numberOfRowsInSection:section]; row++) {
            
            CGFloat height = kJCTableViewCellHeightDefault;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            if (kDelegateRespondsToSelector(@selector(tableView:heightForRowAtIndexPath:))) {
                height = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
            }
            
            [_cellIndexHeightMap setObject:@(height) forKey:indexPath];
            [_cellIndexOffsetYMap setObject:@(padding) forKey:indexPath];
            
            padding += height;
//            NSLog(@"[%zd/%zd] padding:%f height:%f", section, row, padding, height);
        }
    }
    
    self.contentSize = CGSizeMake(CGRectGetWidth(self.frame), padding);
    
    // 0.000024
//    NSLog(@"_resizeTableContent timeEclipse:%f", CACurrentMediaTime() - timeStart);
}

- (NSInteger)_amountForCells
{
    NSInteger amount = 0;
    for (NSInteger section = 0; section < self.numberOfSections; section++) {
        amount += [self numberOfRowsInSection:section];
    }
    return amount;
}
- (NSArray<NSIndexPath *> *)_indexPathForVisibleCells
{
    if ([self _amountForCells] == 0) {
        return nil;
    }
    
    NSMutableArray<NSIndexPath *> *visibleIndexPaths = [NSMutableArray array];
    CGFloat startY = self.contentOffset.y;
    CGFloat endY = startY + CGRectGetHeight(self.frame);
    
    BOOL isStartFound = NO;
    CGFloat visibleStartY = 0.f;
    
    for (NSInteger section = 0; section < self.numberOfSections; section++) {
        for (NSInteger row = 0; row < [self numberOfRowsInSection:section]; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            
            if (!isStartFound) {
                // start
                visibleStartY += self.cellIndexHeightMap[indexPath].floatValue;
                
                if (visibleStartY > startY) {
                    isStartFound = YES;
                    [visibleIndexPaths addObject:indexPath];
                }
            }
            else {
                [visibleIndexPaths addObject:indexPath];
                
                // end
                if (self.cellIndexOffsetYMap[indexPath].floatValue > endY) {
                    break;
                }
            }
        }
    }
    
    return visibleIndexPaths;
}

#pragma mark - Info
- (NSInteger)numberOfSections
{
    if (kDataSourceRespondsToSelector(@selector(numberOfSectionsInTableView:))) {
        _numberOfSections = [self.dataSource numberOfSectionsInTableView:self];
    }
    else {
        _numberOfSections = 1;
    }
    return _numberOfSections;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    if (kDataSourceRespondsToSelector(@selector(tableView:numberOfRowsInSection:))) {
        return [self.dataSource tableView:self numberOfRowsInSection:section];
    }
    return 0;
}

- (BOOL)_invalidIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= self.numberOfSections || indexPath.row >= [self numberOfRowsInSection:indexPath.section]) {
        return YES;
    }
    return NO;
}

- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if ([self _invalidIndexPath:indexPath]) {
//        return CGRectZero;
//    }
    
    CGFloat offsetY = self.cellIndexOffsetYMap[indexPath].floatValue;
    CGFloat height = self.cellIndexHeightMap[indexPath].floatValue;
    return CGRectMake(0, offsetY, CGRectGetWidth(self.frame), height);
}

- (nullable NSIndexPath *)indexPathForCell:(JCTableViewCell *)cell
{
    return cell.indexPath;
}

- (nullable __kindof JCTableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath created:(BOOL)isCreated
{
    // 多余的判断，反而在 deleteRowAtIndexPath:animation: 内部调用会有问题
//    if ([self _invalidIndexPath:indexPath]) {
//        return nil;
//    }
    
    JCTableViewCell *cell = self.visibleIndexCellMap[indexPath];
    if (!cell && isCreated) {
        if (kDataSourceRespondsToSelector(@selector(tableView:cellForRowAtIndexPath:))) {
            cell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
        }
    }
    return cell;
}

/// 外部调用方法，只显示 visible
- (nullable __kindof JCTableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellForRowAtIndexPath:indexPath created:NO];
}

- (NSArray<__kindof JCTableViewCell *> *)visibleCells
{
    return self.visibleIndexCellMap.allValues;
}

- (NSArray<NSIndexPath *> *)_sortedIndexPathForVisibleCells
{
    return [self _sortedIndexPaths:self.visibleIndexCellMap.allKeys];
}

- (NSArray<NSIndexPath *> *)_sortedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    NSArray<NSIndexPath *> *sortedVisibleIndexPaths = [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
        if (obj1.section < obj2.section) {
            return NSOrderedAscending;
        }
        else if (obj1.section > obj2.section) {
            return NSOrderedDescending;
        }
        else {
            return obj1.row > obj2.row;
        }
    }];
    
    return sortedVisibleIndexPaths;
}

#pragma mark - Hierarchy
- (void)_insertCell:(JCTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.frame = [self rectForRowAtIndexPath:indexPath];
    cell.indexPath = indexPath;
    [self insertSubview:cell atIndex:0];    //防止遮挡滚动条
    
    self.visibleIndexCellMap[indexPath] = cell;
}

#pragma mark - Reload
- (void)reloadData
{
    // resize
    [self _resizeTableContent];
    [self _recoverTotalVisibleCells];
    
    [self setNeedsLayout];
}

- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation
{
//    CFTimeInterval timeStart = CACurrentMediaTime();
    
    if (indexPaths.count == 0) {
        return;
    }
    
    // resize
    [self _resizeTableContent];
    
    __block CGFloat padding = 0.f;  // 用于计算插入cell的初始高度
    NSArray<NSIndexPath *> *sortedIndexPaths = [self _sortedIndexPaths:indexPaths];
    [sortedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self _invalidIndexPath:indexPath]) {
            
            // sorted visible
            NSArray<NSIndexPath *> *sortedVisibleIndexPaths = [self _sortedIndexPathForVisibleCells];
            if ([sortedVisibleIndexPaths containsObject:indexPath]) {
                
                // 找出插入位置后的cell，修改对应的 visibleIndexCellMap
                NSMutableArray<NSIndexPath *> *afterIndexPaths = [NSMutableArray array];
                for (NSIndexPath *oneIndex in [sortedVisibleIndexPaths reverseObjectEnumerator]) {
                    if (oneIndex.section < indexPath.section) {
                        break;
                    }
                    else if (oneIndex.section == indexPath.section && oneIndex.row >= indexPath.row) {
                        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:oneIndex.row + 1 inSection:oneIndex.section];
                        self.visibleIndexCellMap[newIndexPath] = [self cellForRowAtIndexPath:oneIndex];
                        self.visibleIndexCellMap[newIndexPath].indexPath = newIndexPath;
                        
                        [afterIndexPaths addObject:newIndexPath];
                    }
                    else if (oneIndex.section > indexPath.section) {
                        [afterIndexPaths addObject:oneIndex];
                    }
                }
                [self.visibleIndexCellMap removeObjectForKey:indexPath];
                
                // new cell
                JCTableViewCell *cell = [self cellForRowAtIndexPath:indexPath created:YES];
                [self _insertCell:cell atIndexPath:indexPath];
                
                // 动画初始高度
                CGRect destFrame = cell.frame;
                [self _prepareInsertCell:cell padding:padding withAnimation:animation];
                padding += CGRectGetHeight(destFrame);
                
                // animation
                void (^insertAnimation)(void) = ^{
                    cell.frame = destFrame;
                    cell.alpha = 1.f;
                    
                    [afterIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        JCTableViewCell *cell = [self cellForRowAtIndexPath:obj];
                        cell.frame = [self rectForRowAtIndexPath:obj];
                    }];
                };
                
                [UIView animateWithDuration:.25f animations:^{
                    insertAnimation();
                }];
            }
        }
    }];
    
    _indexPathsForVisibleRows = [self _indexPathForVisibleCells];
    [self _recoverUnvisibleCellsWithVisibleIndexPaths:_indexPathsForVisibleRows];
    
    //0.002292
//    NSLog(@"insertRowsAtIndexPaths timeEclipse:%f", CACurrentMediaTime() - timeStart);
}

- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation
{
    if (indexPaths.count == 0) {
        return;
    }
    
    // resize
    [self _resizeTableContent];
    
    NSArray<NSIndexPath *> *sortedIndexPaths = [self _sortedIndexPaths:indexPaths];
    [sortedIndexPaths enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
//        if (![self _invalidIndexPath:indexPath]) {
        
            // sorted visible
            NSArray<NSIndexPath *> *sortedVisibleIndexPaths = [self _sortedIndexPathForVisibleCells];
            if ([sortedVisibleIndexPaths containsObject:indexPath]) {
                
                JCTableViewCell *deleteCell = [self cellForRowAtIndexPath:indexPath];
                
                // 找出删除位置之后的的cell，修改对应的 visibleIndexCellMap
                NSMutableArray<NSIndexPath *> *afterIndexPaths = [NSMutableArray array];
                for (NSIndexPath *oneIndex in sortedVisibleIndexPaths) {
                    if (oneIndex.section < indexPath.section) {
                        continue;
                    }
                    else if (oneIndex.section == indexPath.section && oneIndex.row >= indexPath.row) {
                        // same section
                        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:oneIndex.row + 1 inSection:oneIndex.section];
                        JCTableViewCell *nextCell = self.visibleIndexCellMap[nextIndexPath];
                        if (nextCell) {
                            self.visibleIndexCellMap[oneIndex] = nextCell;
                            self.visibleIndexCellMap[oneIndex].indexPath = oneIndex;
                            
                            [afterIndexPaths addObject:oneIndex];
                        }
                        else {
                            [self.visibleIndexCellMap removeObjectForKey:oneIndex];
                        }
                    }
                    else if (oneIndex.section > indexPath.section) {
                        // greater sections
                        [afterIndexPaths addObject:oneIndex];
                    }
                }
                
                // animation
                void (^deleteAnimation)(void) = ^{
                    deleteCell.frame = [self _prepareDeleteCell:deleteCell withAnimation:animation];
                    deleteCell.alpha = 1.f;
                    
                    [afterIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        JCTableViewCell *cell = [self cellForRowAtIndexPath:obj];
                        cell.frame = [self rectForRowAtIndexPath:obj];
                    }];
                };
                
                [UIView animateWithDuration:.25f animations:^{
                    deleteAnimation();
                } completion:^(BOOL finished) {
                    [self _enqueueReusableCell:deleteCell];
                }];
            }
//        }
    }];
    
    _indexPathsForVisibleRows = [self _indexPathForVisibleCells];
    [self _recoverUnvisibleCellsWithVisibleIndexPaths:_indexPathsForVisibleRows];
}

- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation
{
    if (indexPaths.count == 0) {
        return;
    }
    
    // resize
    [self _resizeTableContent];
    
    BOOL isAnimationTop = (animation == JCTableViewRowAnimationTop);
    BOOL isAnimationBottom = (animation == JCTableViewRowAnimationBottom);
    BOOL isAnimationVertical = isAnimationTop || isAnimationBottom;
    
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self _invalidIndexPath:indexPath]) {
            // enqueue
            JCTableViewCell *cell = self.visibleIndexCellMap[indexPath];
            NSInteger zIndex = [self.subviews indexOfObject:cell];
            [self.visibleIndexCellMap removeObjectForKey:indexPath];
            // 垂直方向动画，延时回收cell，做动画使用
            if (!isAnimationVertical) {
                [self _enqueueReusableCell:cell];
            }
            
            // cell 从上往下更新，sendBack 防止图层遮挡，看不清动画效果
            if (isAnimationBottom) {
                [self sendSubviewToBack:cell];
            }
            
            // new cell
            JCTableViewCell *newCell = [self cellForRowAtIndexPath:indexPath created:YES];
            [self _insertCell:newCell atIndexPath:indexPath];
            [self insertSubview:newCell atIndex:zIndex];
            
            // 动画初始高度
            CGRect destFrame = isAnimationTop ? [self _prepareReloadFrame:cell.frame withAnimation:animation] : newCell.frame;
            [self _prepareReloadCell:newCell withAnimation:animation];
            
            // animation，JCTableViewRowAnimationNone 时可以不需要动画
            JCTableViewCell *animatedCell = isAnimationTop ? cell : newCell;
            [UIView animateWithDuration:.35 animations:^{
                animatedCell.frame = destFrame;
                animatedCell.alpha = 1.f;
            } completion:^(BOOL finished) {
                if (isAnimationVertical) {
                    [self _enqueueReusableCell:cell];
                }
            }];
        }
    }];
}

#pragma mark - Action
- (IBAction)_handleTableViewTapped:(UITapGestureRecognizer *)sender
{
    JCTableViewCell *swipingCell = [self _swipingCell];
    if (swipingCell) {
        [swipingCell.swipingView swipeToHide];
        return;
    }
    
    __block NSIndexPath *oldSelectedIndexPath = self.indexPathForSelectedRow;
    
    CGPoint point = [sender locationInView:self];
    [self.visibleCells enumerateObjectsUsingBlock:^(__kindof JCTableViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGRectContainsPoint(cell.frame, point)) {
            self.indexPathForSelectedRow = cell.indexPath;
            [cell setSelected:YES animated:YES];
            
            // select
            if (kDelegateRespondsToSelector(@selector(tableView:didSelectRowAtIndexPath:))) {
                [self.delegate tableView:self didSelectRowAtIndexPath:cell.indexPath];
            }
        }
        else {
            [cell setSelected:NO animated:NO];
            
            // deselect
            if (oldSelectedIndexPath) {
                if (cell.indexPath.section == oldSelectedIndexPath.section &&
                    cell.indexPath.row == oldSelectedIndexPath.row) {
                    
                    if (kDelegateRespondsToSelector(@selector(tableView:didDeselectRowAtIndexPath:))) {
                        [self.delegate tableView:self didDeselectRowAtIndexPath:cell.indexPath];
                    }
                    oldSelectedIndexPath = nil;
                }
            }
        }
    }];
}

- (IBAction)_handlePanGestureRecognizer:(UIPanGestureRecognizer *)sender
{
    if (!self.canEditRow) {
        return;
    }
    
    CGPoint point = [sender locationInView:self];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        _panStartPoint = point;
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        // swipe left
        if (point.x < _panStartPoint.x) {
            [self.visibleCells enumerateObjectsUsingBlock:^(__kindof JCTableViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
                if (CGRectContainsPoint(cell.frame, point)) {
                    // swipe
                    if (!cell.swipingView) {
                        [self.previousSwipeView swipeToHide];
                        
                        JCSwipeActionPullView *swipeView = [self _prepareSwipeViewForCell:cell];
                        [swipeView swipeToShow];
                        self.previousSwipeView = swipeView;
                    }
                    
                    *stop = YES;
                }
            }];
        }
    }
    else if (sender.state == UIGestureRecognizerStateCancelled) {
        _panStartPoint = CGPointZero;
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        _panStartPoint = CGPointZero;
    }
}

#pragma mark - Pan
- (JCSwipeActionPullView *)_dequeueSwipeView
{
    JCSwipeActionPullView *swipeView = [self.recycledSwipeViews anyObject];
    if (swipeView) {
        [self.recycledSwipeViews removeObject:swipeView];
    }
    else {
        swipeView = [JCSwipeActionPullView new];
    }
    return swipeView;
}

- (void)_enqueueSwipeView:(JCSwipeActionPullView *)swipeView
{
    if (swipeView) {
        swipeView.swipingCell = nil;
        [self.recycledSwipeViews addObject:swipeView];
        [swipeView removeFromSuperview];
        
        if ([swipeView isEqual:self.previousSwipeView]) {
            self.previousSwipeView = nil;
        }
    }
}

- (JCSwipeActionPullView *)_prepareSwipeViewForCell:(JCTableViewCell *)cell
{
    if (!cell) {
        return nil;
    }
    
    __weak __typeof(self) weakSelf = self;
    JCSwipeActionPullView *swipeView = [self _dequeueSwipeView];
    cell.swipingView = swipeView;   //weak
    swipeView.swipingCell = cell;   //weak
    swipeView.hideCompletionHandler = ^(JCSwipeActionPullView *swipe) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _enqueueSwipeView:swipe];
    };
    swipeView.actionHandler = ^(JCTableViewCell *associatedCell) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.delegate &&
            [strongSelf.delegate respondsToSelector:@selector(tableView:commitEditingForRowAtIndexPath:)]) {
            [strongSelf.delegate tableView:self commitEditingForRowAtIndexPath:associatedCell.indexPath];
        }
    };
    swipeView.frame = CGRectMake(CGRectGetMaxX(cell.frame), CGRectGetMinY(cell.frame), JCSwipeActionPullViewWidth, CGRectGetHeight(cell.frame));
    [self addSubview:swipeView];
    
    return swipeView;
}

- (JCTableViewCell *)_swipingCell
{
    __block JCTableViewCell *swipingCell = nil;
    [self.visibleCells enumerateObjectsUsingBlock:^(__kindof JCTableViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if (cell.swipingView) {
            swipingCell = cell;
            *stop = YES;
        }
    }];
    return swipingCell;
}

@end
