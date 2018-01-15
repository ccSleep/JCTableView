//
//  JCTableViewCell.m
//  JCTableView
//
//  Created by 林锦超 on 11/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableViewCell.h"
#import "JCTableViewCellPrivate.h"

@interface JCTableViewCell()
@property (nonatomic, strong, nullable, readwrite) UILabel *textLabel;

@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong, readwrite) UIView *selectedBackgroundView;

@property (nonatomic, copy, readwrite) NSString *reuseIdentifier;
@end
@implementation JCTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super init]) {
        _reuseIdentifier = reuseIdentifier;
    }
    return self;
}

- (void)prepareForReuse
{
    
}

@end
