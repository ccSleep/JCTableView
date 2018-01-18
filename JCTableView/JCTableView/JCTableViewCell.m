//
//  JCTableViewCell.m
//  JCTableView
//
//  Created by 林锦超 on 11/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableViewCell.h"
#import "JCTableViewCellPrivate.h"

#define kJCTableCellMargin  20.f

@interface JCTableViewCell()
@property (nonatomic, strong, nullable, readwrite) UILabel *textLabel;

@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong, readwrite) UIView *selectedBackgroundView;

@property (nonatomic, copy, readwrite) NSString *reuseIdentifier;
@end
@implementation JCTableViewCell

#pragma mark - LifeCycle
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super init]) {
        _reuseIdentifier = reuseIdentifier;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self _setup];
    }
    return self;
}

- (void)_setup
{
    _contentView = [UIView new];
    _textLabel = [UILabel new];
    
    [self addSubview:_contentView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    if (self.textLabel.text) {
        CGSize size = self.bounds.size;
        self.textLabel.frame = CGRectMake(kJCTableCellMargin, 0, size.width - 2*kJCTableCellMargin, size.height);
        [self.contentView addSubview:self.textLabel];
    }
    else {
        [self.textLabel removeFromSuperview];
    }
}

- (void)prepareForReuse
{
    self.indexPath = nil;
}

#pragma mark - Accessor

@end
