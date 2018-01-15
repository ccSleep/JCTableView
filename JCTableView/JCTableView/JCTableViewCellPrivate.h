//
//  JCTableViewCell+Private.h
//  JCTableView
//
//  Created by 林锦超 on 12/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableViewCell.h"

@interface JCTableViewCell ()
/// cell 是否被重用注册
@property (nonatomic, assign, getter=isRegistered) BOOL registered;
@end
