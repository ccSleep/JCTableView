//
//  JCTableViewCell.h
//  JCTableView
//
//  Created by 林锦超 on 11/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JCTableViewCell : UIView

// default is nil.  label will be created if necessary.
@property (nonatomic, strong, nullable, readonly) UILabel *textLabel;

@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong, nullable) UIView *selectedBackgroundView;

@property (nonatomic, copy, readonly) NSString *reuseIdentifier;
- (void)prepareForReuse NS_REQUIRES_SUPER;  

- (instancetype)initWithReuseIdentifier:(nullable NSString *)reuseIdentifier;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


@property (nonatomic, getter=isSelected) BOOL selected;                   // set selected state (title, image, background). default is NO. animated is NO
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END

