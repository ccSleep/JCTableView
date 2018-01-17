//
//  JCTableView.m
//  JCTableView
//
//  Created by 林锦超 on 11/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableView.h"
//#import "JCTableViewCellPrivate.h"

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
@property (nonatomic, strong, nullable, readwrite) NSArray<NSIndexPath *> *indexPathsForVisibleRows;

/// layout
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *cellIndexHeightMap;   // @{ indexPath : @(float) }
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *cellIndexOffsetYMap;  // @{ indexPath : @(float) }


/// sections
@property (nonatomic, assign, readwrite) NSInteger numberOfSections;
@end

@implementation JCTableView

@dynamic delegate;

#pragma mark - LifeCycle
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self _setup];
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
    
    self.alwaysBounceVertical = YES;
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
            NSLog(@"cls:%@", cls);
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
    if ([self _invalidIndexPath:indexPath]) {
        return CGRectZero;
    }
    
    CGFloat offsetY = self.cellIndexOffsetYMap[indexPath].floatValue;
    CGFloat height = self.cellIndexHeightMap[indexPath].floatValue;
    return CGRectMake(0, offsetY, CGRectGetWidth(self.frame), height);
}

- (nullable NSIndexPath *)indexPathForCell:(UITableViewCell *)cell
{
    return nil;
}

- (nullable __kindof JCTableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath created:(BOOL)isCreated
{
    if ([self _invalidIndexPath:indexPath]) {
        return nil;
    }
    
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
    NSArray<NSIndexPath *> *sortedVisibleIndexPaths = [self.visibleIndexCellMap.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
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
//    [self addSubview:cell];
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
    CFTimeInterval timeStart = CACurrentMediaTime();
    
    if (indexPaths.count == 0) {
        return;
    }
    
    // resize
    [self _resizeTableContent];
    
    // sorted
    NSArray<NSIndexPath *> *sortedVisibleIndexPaths = [self _sortedIndexPathForVisibleCells];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self _invalidIndexPath:indexPath]) {
            
            // visible
            if ([sortedVisibleIndexPaths containsObject:indexPath]) {
                NSMutableArray<NSIndexPath *> *afterIndexPathsInSameSection = [NSMutableArray array];
                for (NSIndexPath *oneIndex in [sortedVisibleIndexPaths reverseObjectEnumerator]) {
                    if (oneIndex.section < indexPath.section) {
                        break;
                    }
                    else if (oneIndex.section == indexPath.section && oneIndex.row >= indexPath.row) {
                        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:oneIndex.row + 1 inSection:oneIndex.section];
                        self.visibleIndexCellMap[newIndexPath] = [self cellForRowAtIndexPath:oneIndex];
                        
                        [afterIndexPathsInSameSection addObject:newIndexPath];
                    }
                }
                [self.visibleIndexCellMap removeObjectForKey:indexPath];
                
                JCTableViewCell *cell = [self cellForRowAtIndexPath:indexPath created:YES];
                [self _insertCell:cell atIndexPath:indexPath];
                
                CGRect destFrame = cell.frame;
                cell.frame = CGRectOffset(destFrame, 0, -CGRectGetHeight(destFrame));
                
                
                
                // animation
                void (^animation)(void) = ^{
                    cell.frame = destFrame;
                    
                    [afterIndexPathsInSameSection enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        JCTableViewCell *cell = [self cellForRowAtIndexPath:obj];
                        cell.frame = [self rectForRowAtIndexPath:obj];
                    }];
                };
                
//                [UIView animateWithDuration:.25f animations:^{
//                    animation();
//                }];
                
                [UIView animateWithDuration:.25f delay:0.f options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
                    animation();
                } completion:^(BOOL finished) {
                    
                }];
            }
        }
    }];
    
    NSLog(@"insertRowsAtIndexPaths timeEclipse:%f", CACurrentMediaTime() - timeStart);
}

- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation
{
    if (indexPaths.count == 0) {
        return;
    }
}

- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation
{
    if (indexPaths.count == 0) {
        return;
    }
}

@end
