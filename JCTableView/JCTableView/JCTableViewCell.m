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
@property (nonatomic, strong) UITableViewCell *cell;
@property (nonatomic, strong, nullable, readwrite) UILabel *textLabel;

@property (nonatomic, strong, readwrite) UIView *contentView;

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
    _selectedBackgroundView = [UIView new];
    _selectedBackgroundView.backgroundColor = [UIColor colorWithRed:217/255.f green:217/255.f blue:217/255.f alpha:1.f];
    _textLabel = [UILabel new];
    
    [self addSubview:_contentView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    // textLabel
    if (self.textLabel.text) {
        CGSize size = self.bounds.size;
        self.textLabel.frame = CGRectMake(kJCTableCellMargin, 0, size.width - 2*kJCTableCellMargin, size.height);
        [self.contentView addSubview:self.textLabel];
    }
    else {
        [self.textLabel removeFromSuperview];
    }
    
    // selected
    if (self.isSelected) {
        self.selectedBackgroundView.frame = self.bounds;
        [self insertSubview:self.selectedBackgroundView atIndex:0];
    }
    else {
        [self.selectedBackgroundView removeFromSuperview];
    }
}

- (void)prepareForReuse
{
    self.indexPath = nil;
    
    [self setSelected:NO animated:NO];
}

#pragma mark - Accessor
- (void)setSelectedBackgroundView:(UIView *)selectedBackgroundView
{
    if (_selectedBackgroundView != selectedBackgroundView) {
        [_selectedBackgroundView removeFromSuperview];
        _selectedBackgroundView = selectedBackgroundView;
        
        [self setNeedsLayout];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selected == selected) {
        return;
    }
    
    void (^animation)(void) = ^{
        _selected = selected;
        [self setNeedsLayout];
    };
    
    if (!animated) {
        animation();
    }
    else {
        [UIView animateWithDuration:.25f animations:^{
            animation();
        }];
    }
}

#pragma mark -


@end
