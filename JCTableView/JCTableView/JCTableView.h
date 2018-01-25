//
//  JCTableView.h
//  JCTableView
//
//  Created by 林锦超 on 11/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@class JCTableView;

typedef NS_ENUM(NSInteger, JCTableViewRowAnimation) {
    JCTableViewRowAnimationFade,
    JCTableViewRowAnimationRight,
    JCTableViewRowAnimationLeft,
    JCTableViewRowAnimationTop,
    JCTableViewRowAnimationBottom,
    JCTableViewRowAnimationNone,
};


// ----------------------------------------------------------------------
//MARK: - JCTableViewDataSource
@protocol JCTableViewDataSource <NSObject>
@required
- (NSInteger)tableView:(JCTableView *)tableView numberOfRowsInSection:(NSInteger)section;

- (JCTableViewCell *)tableView:(JCTableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

@optional
- (NSInteger)numberOfSectionsInTableView:(JCTableView *)tableView;

// header & footer
@end


// ----------------------------------------------------------------------
//MARK: - JCTableViewDelegate
@protocol JCTableViewDelegate <NSObject, UIScrollViewDelegate>
@optional
- (CGFloat)tableView:(JCTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

// Called after the user changes the selection.
- (void)tableView:(JCTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(JCTableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

// Editing
- (BOOL)tableView:(JCTableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(JCTableView *)tableView commitEditingForRowAtIndexPath:(NSIndexPath *)indexPath;
@end


// ----------------------------------------------------------------------
//MARK: - JCTableView
@interface JCTableView : UIScrollView

@property (nonatomic, weak) id<JCTableViewDataSource> dataSource;
@property (nonatomic, weak) id<JCTableViewDelegate> delegate;

// ----------------------------------------------------------------------
//MARK: Info
@property (nonatomic, assign, readonly) NSInteger numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;

//- (CGRect)rectForSection:(NSInteger)section;                                    // includes header, footer and all rows
//- (CGRect)rectForHeaderInSection:(NSInteger)section;
//- (CGRect)rectForFooterInSection:(NSInteger)section;
- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath;

- (nullable NSIndexPath *)indexPathForCell:(JCTableViewCell *)cell;                      // returns nil if cell is not visible
- (nullable __kindof JCTableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;   // returns nil if cell is not visible or index path is out of range
@property (nonatomic, strong, readonly) NSArray<__kindof JCTableViewCell *> *visibleCells;
@property (nonatomic, strong, nullable, readonly) NSArray<NSIndexPath *> *indexPathsForVisibleRows; // sorted


// ----------------------------------------------------------------------
//MARK: Selection
@property (nonatomic, strong, nullable, readonly) NSIndexPath *indexPathForSelectedRow; // returns nil or index path representing section and row of selection.


// ----------------------------------------------------------------------
//MARK: recycle
/// Used by the delegate to acquire an already allocated cell
- (nullable __kindof JCTableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

// If all reuse identifiers are registered, use the newer -dequeueReusableCellWithIdentifier:forIndexPath: to guarantee that a cell instance is returned.
- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier;


// ----------------------------------------------------------------------
//MARK: reload
/// rows
- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation;
- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation;
- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(JCTableViewRowAnimation)animation;

/// Redisplays visible rows
- (void)reloadData;
@end

NS_ASSUME_NONNULL_END
